import SwiftUI

struct TeacherScanStepView: View {
    @ObservedObject var vm: CheckInViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var ringScale: CGFloat = 1
    @State private var scanning = false

    var body: some View {
        ZStack {
            Color.forgeBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("STEP 2 OF 3")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.5)
                        .foregroundColor(.forgeInk3)
                    Spacer()
                    LightStepDots(active: 1)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.forgeMuted)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)

                // Identity verified pill
                ForgePill(text: "IDENTITY VERIFIED", tone: .live, dot: true)
                    .padding(.top, 28)

                Text("Scan teacher card")
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.6)
                    .foregroundColor(.forgeInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                Text("Hold the back of your iPhone near the instructor's NFC badge.")
                    .font(.system(size: 15))
                    .foregroundColor(.forgeInk3)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer()

                // NFC animation + card
                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.forgeBrand, lineWidth: 2)
                            .frame(width: CGFloat(90 + i * 60), height: CGFloat(90 + i * 60))
                            .opacity(scanning ? Double(3 - i) * 0.12 + 0.15 : Double(3 - i) * 0.08 + 0.08)
                            .scaleEffect(scanning ? 1 + CGFloat(i) * 0.08 : 1)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: scanning
                            )
                    }

                    // Faculty badge card
                    ZStack(alignment: .topTrailing) {
                        LinearGradient(
                            colors: [Color.forgeBrand, Color.forgeBrandDeep],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )

                        VStack(alignment: .leading, spacing: 0) {
                            Text("FACULTY · ID 20-441")
                                .font(.system(size: 9, weight: .bold))
                                .kerning(1.4)
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            Text(vm.teacherName)
                                .font(.system(size: 15, weight: .bold))
                                .kerning(-0.3)
                                .foregroundColor(.white)

                            Text("Computer Science")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.top, 2)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                        // EMV chip
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F4D28C"), Color(hex: "D5A44C")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 20)
                            .padding(14)

                        // NFC symbol
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .frame(width: 200, height: 124)
                    .cornerRadius(16)
                    .shadow(color: Color.forgeBrand.opacity(0.35), radius: 20, y: 10)
                }
                .frame(width: 280, height: 280)

                Spacer()

                // Status
                VStack(spacing: 4) {
                    if vm.nfc.isScanning {
                        ProgressView()
                            .tint(.forgeBrand)
                        Text("Reading card…")
                            .font(.system(size: 15))
                            .foregroundColor(.forgeInk3)
                    } else if let err = vm.errorMessage {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(.forgeWarn)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Waiting for card…")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.forgeInk)
                        Text("Move iPhone closer to the badge")
                            .font(.system(size: 13))
                            .foregroundColor(.forgeMuted)
                    }
                }

                // Scan button + fallback
                VStack(spacing: 12) {
                    ForgeButton(title: "Scan NFC Badge", systemIcon: "wave.3.right", action: {
                        vm.scanTeacherCard()
                    })
                    .disabled(vm.nfc.isScanning)

                    ForgeCard {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.forgeTint)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "qrcode")
                                    .font(.system(size: 16))
                                    .foregroundColor(.forgeBrand)
                            }
                            Text("No NFC badge? ")
                                .font(.system(size: 12.5))
                                .foregroundColor(.forgeInk3)
                            + Text("Scan QR instead")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.forgeBrand)
                            Spacer()
                        }
                        .padding(14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 44)
            }
        }
        .onAppear { scanning = true }
    }
}
