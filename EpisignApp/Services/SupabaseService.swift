import Foundation

struct StudentProfile: Codable {
    let id: String
    let cardCode: String?
    let classId: String?
    let firstName: String
    let lastName: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id
        case cardCode  = "card_code"
        case classId   = "class_id"
        case firstName = "first_name"
        case lastName  = "last_name"
        case email
    }
}

struct AttendanceResult: Codable {
    let ok: Bool
    let error: String?
}

@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL  = "https://dhsvjvrfpvljvcqmahbj.supabase.co"
    private let anonKey  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoc3ZqdnJmcHZsanZjcW1haGJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjYwNzUsImV4cCI6MjA5MjQ0MjA3NX0.nlhPNbbncnBBNAuEefycULTGoKQw0n5Uj8_CmK3W40w"

    private func rpc<P: Encodable, R: Decodable>(_ name: String, params: P) async throws -> R {
        let url = URL(string: "\(baseURL)/rest/v1/rpc/\(name)")!
        var req = URLRequest(url: url)
        req.httpMethod  = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(params)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.http(http.statusCode, body)
        }
        return try JSONDecoder().decode(R.self, from: data)
    }

    func upsertStudent(login: String, firstName: String, lastName: String, email: String) async throws -> StudentProfile {
        struct P: Encodable {
            let p_forge_login: String
            let p_first_name:  String
            let p_last_name:   String
            let p_email:       String
        }
        return try await rpc("upsert_student", params: P(
            p_forge_login: login,
            p_first_name:  firstName,
            p_last_name:   lastName,
            p_email:       email
        ))
    }

    func getStudentSessions(login: String) async throws -> [DBSession] {
        struct P: Encodable { let p_forge_login: String }
        return try await rpc("get_student_sessions", params: P(p_forge_login: login))
    }

    func validateTeacherCode(sessionId: String, teacherCode: String) async throws -> Bool {
        struct P: Encodable { let p_session_id: String; let p_teacher_code: String }
        struct R: Decodable { let valid: Bool }
        let result: R = try await rpc("validate_teacher_code", params: P(
            p_session_id: sessionId,
            p_teacher_code: teacherCode
        ))
        return result.valid
    }

    func submitAttendance(forgeLogin: String, teacherCode: String, studentCode: String, sessionId: String) async throws -> AttendanceResult {
        struct P: Encodable {
            let p_forge_login:  String
            let p_teacher_code: String
            let p_student_code: String
            let p_session_id:   String
        }
        return try await rpc("submit_attendance", params: P(
            p_forge_login:  forgeLogin,
            p_teacher_code: teacherCode,
            p_student_code: studentCode,
            p_session_id:   sessionId
        ))
    }

    enum SupabaseError: LocalizedError {
        case http(Int, String)
        var errorDescription: String? {
            if case .http(let code, let body) = self { return "Erreur serveur \(code): \(body)" }
            return nil
        }
    }
}
