import SwiftUI

struct FaceIDStepView: View {
    @ObservedObject var vm: CheckInViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.forgeInk.ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(RadialGradient(
                    colors: [Color.forgeBrand.opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: 220
                ))
                .frame(width: 440, height: 440)
                .offset(y: -160)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("STEP 1 OF 3")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.5)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    StepDots(active: 0)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)

                // Course label
                Text("\(vm.session.code) · ÉMARGEMENT")
                    .font(.system(size: 11.5, weight: .bold))
                    .kerning(1)
                    .foregroundColor(.forgeAccent)
                    .padding(.top, 36)

                Text("Verify your identity")
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.6)
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Face ID confirms you're present — no passwords, no codes.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                Spacer()

                // Scan animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: 0.29)
                        .stroke(Color.forgeAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: pulse)

                    // Corner frame marks
                    ForEach(0..<4, id: \.self) { i in
                        CornerMark()
                            .rotationEffect(.degrees(Double(i) * 90))
                            .frame(width: 160, height: 160)
                    }

                    // Face icon
                    VStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .font(.system(size: 52, weight: .thin))
                            .foregroundColor(.white)
                    }

                    // Scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.forgeAccent, .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: 120, height: 2)
                        .shadow(color: Color.forgeAccent, radius: 7)
                        .offset(y: pulse ? 40 : -40)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                }
                .frame(width: 220, height: 220)

                Spacer()

                // Status
                VStack(spacing: 4) {
                    if vm.isProcessing {
                        Text("Scanning…")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    } else if let err = vm.errorMessage {
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundColor(.forgeWarn)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Look at your iPhone")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Scanning secure facial signature…")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // CTA
                Button(action: { Task { await vm.authenticateWithFaceID() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                        Text("Authenticate with Face ID")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.forgeAccent.opacity(0.18))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .disabled(vm.isProcessing)

                // Privacy note
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("End-to-end encrypted · never stored")
                        .font(.system(size: 11.5))
                }
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear { pulse = true }
    }
}

struct CornerMark: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 12))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 12, y: 0))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 160, height: 160)
        }
    }
}
