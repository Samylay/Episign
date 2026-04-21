import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Ambient gradients
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.forgeBrand.opacity(0.14), .clear],
                        center: .center, startRadius: 0, endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: 80, y: -200)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.forgeAccent.opacity(0.12), .clear],
                        center: .center, startRadius: 0, endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -100, y: 220)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Logo + wordmark
                VStack(alignment: .leading, spacing: 0) {
                    EpisignLogo(size: 64)

                    Text("Welcome to Episign")
                        .font(.system(size: 32, weight: .bold))
                        .kerning(-0.8)
                        .foregroundColor(.forgeInk)
                        .padding(.top, 28)

                    Text("Secure campus attendance for students, faculty and staff.")
                        .font(.system(size: 16))
                        .foregroundColor(.forgeInk3)
                        .lineSpacing(5)
                        .frame(maxWidth: 300, alignment: .leading)
                        .padding(.top, 10)
                }

                Spacer()

                VStack(spacing: 12) {
                    ForgeButton(
                        title: auth.isLoading ? "Signing in…" : "Sign in with EpitaID",
                        systemIcon: "shield.fill",
                        action: { Task { await auth.signIn() } }
                    )
                    .disabled(auth.isLoading)
                    .overlay(
                        auth.isLoading
                            ? RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.4))
                            : nil
                    )

                    ForgeButton(
                        title: "Sign in with Microsoft",
                        secondary: true,
                        systemIcon: "square.grid.2x2.fill",
                        action: { Task { await auth.signIn() } }
                    )
                }

                if let err = auth.errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.forgeWarn)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }

                // Terms
                HStack(spacing: 4) {
                    Text("By signing in you agree to our")
                        .foregroundColor(.forgeMuted)
                    Button("Terms") {}
                        .foregroundColor(.forgeBrand)
                    Text("and")
                        .foregroundColor(.forgeMuted)
                    Button("Privacy Policy") {}
                        .foregroundColor(.forgeBrand)
                }
                .font(.system(size: 12))
                .padding(.top, 18)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Logo

struct EpisignLogo: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 14, y: 4)

            // Placeholder E mark (replace with actual EPITA asset in Xcode)
            Text("E")
                .font(.system(size: size * 0.5, weight: .black, design: .rounded))
                .foregroundColor(.forgeBrand)
        }
        .frame(width: size, height: size)
    }
}
