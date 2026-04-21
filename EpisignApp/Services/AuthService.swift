import Foundation
import AuthenticationServices
import CryptoKit
import Security

@MainActor
class AuthService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: EpisignUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // ForgeID OIDC — use test credentials in dev; request production client for release
    private let clientID      = "125070"
    private let authURL       = URL(string: "https://cri.epita.fr/authorize")!
    private let tokenURL      = URL(string: "https://cri.epita.fr/token")!
    private let userInfoURL   = URL(string: "https://cri.epita.fr/userinfo")!
    private let redirectURI   = "episign://callback"
    private let scopes        = "openid profile email epita"

    private var webAuthSession: ASWebAuthenticationSession?
    private var pendingVerifier: String?

    override init() {
        super.init()
        restoreSession()
    }

    // MARK: - Sign in

    func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            let (verifier, challenge) = makePKCE()
            pendingVerifier = verifier

            let authorizationURL = buildAuthURL(challenge: challenge)
            let callbackURL = try await openWebAuth(url: authorizationURL)

            guard let code = urlQueryItem("code", in: callbackURL) else {
                throw AuthError.missingCode
            }

            let tokens = try await exchangeCode(code, verifier: verifier)
            try persist(tokens)

            let resolved = try await fetchUserInfo(token: tokens.accessToken)
            user = resolved
            isAuthenticated = true
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // User dismissed — no error toast
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() {
        clearKeychain()
        user = nil
        isAuthenticated = false
    }

    // MARK: - PKCE

    private func makePKCE() -> (verifier: String, challenge: String) {
        var random = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, random.count, &random)

        let verifier = Data(random)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let digest = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(digest)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return (verifier, challenge)
    }

    // MARK: - Auth URL

    private func buildAuthURL(challenge: String) -> URL {
        var c = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        c.queryItems = [
            URLQueryItem(name: "response_type",          value: "code"),
            URLQueryItem(name: "client_id",              value: clientID),
            URLQueryItem(name: "redirect_uri",           value: redirectURI),
            URLQueryItem(name: "scope",                  value: scopes),
            URLQueryItem(name: "code_challenge",         value: challenge),
            URLQueryItem(name: "code_challenge_method",  value: "S256"),
            URLQueryItem(name: "state",                  value: UUID().uuidString),
        ]
        return c.url!
    }

    // MARK: - ASWebAuthenticationSession

    @MainActor
    private func openWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "episign"
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: error ?? URLError(.cancelled))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            webAuthSession = session
            session.start()
        }
    }

    // MARK: - Token exchange

    private struct TokenResponse: Codable {
        let accessToken: String
        let idToken: String?
        let refreshToken: String?
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case accessToken  = "access_token"
            case idToken      = "id_token"
            case refreshToken = "refresh_token"
            case expiresIn    = "expires_in"
        }
    }

    private func exchangeCode(_ code: String, verifier: String) async throws -> TokenResponse {
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  redirectURI,
            "client_id":     clientID,
            "code_verifier": verifier,
        ]
        req.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    // MARK: - UserInfo

    private func fetchUserInfo(token: String) async throws -> EpisignUser {
        var req = URLRequest(url: userInfoURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.badUserInfo
        }

        let login     = json["preferred_username"] as? String ?? ""
        let email     = json["email"] as? String ?? ""
        let firstName = json["given_name"] as? String ?? ""
        let lastName  = json["family_name"] as? String ?? ""

        let epita = json["epita"] as? [String: Any] ?? [:]
        let uid   = epita["uid"] as? Int ?? 0
        let gid   = epita["gid"] as? Int ?? 0

        let rawGroups = epita["groups"] as? [[String: Any]] ?? []
        let groups = rawGroups.compactMap { g -> EpisignUser.Group? in
            guard
                let slug = g["slug"] as? String,
                let name = g["name"] as? String,
                let kind = g["kind"] as? String,
                let groupGid = g["gid"] as? Int
            else { return nil }
            return EpisignUser.Group(slug: slug, name: name, gid: groupGid, kind: kind)
        }

        let gradYears = epita["graduation_years"] as? [Int]

        return EpisignUser(
            login: login, email: email, firstName: firstName, lastName: lastName,
            uid: uid, gid: gid, groups: groups, graduationYear: gradYears?.first
        )
    }

    // MARK: - Keychain

    private let keychainService = "fr.epita.episign"
    private let keychainAccount = "tokens"

    private func persist(_ tokens: TokenResponse) throws {
        let data = try JSONEncoder().encode(tokens)
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String:   data,
        ]
        SecItemDelete(q as CFDictionary)
        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else { throw AuthError.keychainWrite(status) }
    }

    private func restoreSession() {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String:  true,
        ]
        var ref: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ref) == errSecSuccess,
              let data = ref as? Data,
              let tokens = try? JSONDecoder().decode(TokenResponse.self, from: data),
              !tokens.accessToken.isEmpty
        else { return }

        Task {
            do {
                let resolved = try await fetchUserInfo(token: tokens.accessToken)
                self.user = resolved
                self.isAuthenticated = true
            } catch {
                self.clearKeychain()
            }
        }
    }

    private func clearKeychain() {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(q as CFDictionary)
    }

    // MARK: - Helpers

    private func urlQueryItem(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case missingCode
        case badUserInfo
        case keychainWrite(OSStatus)

        var errorDescription: String? {
            switch self {
            case .missingCode:      return "No authorization code received from ForgeID."
            case .badUserInfo:      return "Could not parse user information from ForgeID."
            case .keychainWrite(let s): return "Keychain error \(s)."
            }
        }
    }
}

// MARK: - Presentation context

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
