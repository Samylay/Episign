import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthService
    @State private var showLogoutAlert = false
    @State private var faceIDEnabled = true
    @State private var selectedLanguage = "English (United States)"

    var user: EpisignUser? { auth.user }

    var promotionLabel: String {
        guard let u = user else { return "EPITA" }
        if let year = u.graduationYear {
            let major = u.groups.first(where: { $0.kind == "promotion" })?.name ?? "SIGL"
            return "EPITA · \(major) · Promotion \(year)"
        }
        return "EPITA"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.forgeBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Avatar + identity header
                        HStack(alignment: .center, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.forgeBrandSoft, .forgeBrand],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: Color.forgeBrand.opacity(0.28), radius: 9, y: 3)

                                Text(user?.initials ?? "?")
                                    .font(.system(size: 22, weight: .semibold))
                                    .kerning(-0.5)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(user?.displayName ?? "Student")
                                    .font(.system(size: 20, weight: .bold))
                                    .kerning(-0.4)
                                    .foregroundColor(.forgeInk)

                                Text(promotionLabel)
                                    .font(.system(size: 13.5))
                                    .foregroundColor(.forgeInk3)

                                HStack(spacing: 6) {
                                    ForgePill(text: "Student")
                                    if let uid = user?.uid {
                                        ForgePill(text: "ID \(uid)", tone: .neutral)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                        // ACCOUNT
                        SectionHeader("ACCOUNT")

                        ForgeCard {
                            VStack(spacing: 0) {
                                ProfileRow(label: "Username",   value: user?.login  ?? "—",   locked: true)
                                Divider().padding(.leading, 16)
                                ProfileRow(label: "Email",      value: user?.email  ?? "—",   locked: true)
                                Divider().padding(.leading, 16)
                                ProfileRow(label: "Student ID", value: user.map { "\($0.uid)" } ?? "—", locked: true, isLast: true)
                            }
                        }
                        .padding(.horizontal, 16)

                        Group {
                            Text("Synced from institutional directory. Contact ")
                                .foregroundColor(.forgeMuted)
                            + Text("support@epita.fr")
                                .foregroundColor(.forgeBrand)
                            + Text(" to change.")
                                .foregroundColor(.forgeMuted)
                        }
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // LINKED METHODS
                        SectionHeader("LINKED METHODS")

                        ForgeCard {
                            VStack(spacing: 0) {
                                LinkedMethodRow(
                                    icon: "faceid",
                                    title: "Face ID",
                                    subtitle: "Enrolled · iPhone 15 Pro",
                                    subtitleColor: .forgeSuccess,
                                    trailing: AnyView(Toggle("", isOn: $faceIDEnabled).tint(.forgeSuccess).labelsHidden())
                                )
                                Divider().padding(.leading, 62)
                                LinkedMethodRow(
                                    icon: "wave.3.right",
                                    title: "NFC Student Card",
                                    subtitle: "Paired · #A-2814",
                                    subtitleColor: .forgeSuccess,
                                    trailing: AnyView(Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.forgeMuted))
                                )
                                Divider().padding(.leading, 62)
                                LinkedMethodRow(
                                    icon: "square.grid.2x2.fill",
                                    title: "Microsoft 365",
                                    subtitle: "Not linked",
                                    subtitleColor: .forgeMuted,
                                    trailing: AnyView(Text("Link").font(.system(size: 13, weight: .semibold)).foregroundColor(.forgeBrand))
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // PREFERENCES
                        SectionHeader("PREFERENCES")

                        ForgeCard {
                            VStack(spacing: 0) {
                                ProfileRow(label: "Language",      value: "English (United States)", chevron: true)
                                Divider().padding(.leading, 16)
                                ProfileRow(label: "Notifications", value: "Session reminders · 15 min before", chevron: true)
                                Divider().padding(.leading, 16)
                                ProfileRow(label: "Appearance",    value: "Match system", chevron: true, isLast: true)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Logout
                        ForgeCard {
                            Button(action: { showLogoutAlert = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16))
                                    Text("Log out")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "C8483E"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 22)

                        Text("Episign v1.4.0 · Build 26.4 · © EPITA 2026")
                            .font(.system(size: 11))
                            .foregroundColor(.forgeMuted)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {}
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.forgeBrand)
                }
            }
            .alert("Log out?", isPresented: $showLogoutAlert) {
                Button("Log out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will be signed out of all Episign services.")
            }
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let label: String
    let value: String
    var locked: Bool = false
    var chevron: Bool = false
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 11.5, weight: .semibold))
                    .kerning(0.3)
                    .foregroundColor(.forgeMuted)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.forgeInk)
                    .lineLimit(1)
            }
            Spacer()
            if locked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Locked")
                        .font(.system(size: 11))
                }
                .foregroundColor(.forgeMuted)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.forgeMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Linked Method Row

struct LinkedMethodRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let subtitleColor: Color
    let trailing: AnyView

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.forgeTint)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.forgeBrand)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5))
                    .foregroundColor(.forgeInk)
                HStack(spacing: 4) {
                    if subtitleColor == .forgeSuccess {
                        Circle().fill(subtitleColor).frame(width: 6, height: 6)
                    }
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(subtitleColor)
                }
            }

            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .bold))
            .kerning(0.8)
            .foregroundColor(.forgeMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}
