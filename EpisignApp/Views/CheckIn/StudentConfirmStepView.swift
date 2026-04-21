import SwiftUI

struct StudentConfirmStepView: View {
    @ObservedObject var vm: CheckInViewModel
    var onDone: () -> Void
    @EnvironmentObject var auth: AuthService

    @State private var pulse = false
    @State private var appeared = false

    var checkInTime: String { "09:14:38" }

    var body: some View {
        ZStack {
            Color.forgeBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("STEP 3 OF 3")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.5)
                        .foregroundColor(.forgeInk3)
                    Spacer()
                    LightStepDots(active: 2)
                    Spacer()
                    Color.clear.frame(width: 24)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)

                Spacer()

                // Success checkmark
                ZStack {
                    Circle()
                        .stroke(Color.forgeSuccess.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 124, height: 124)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "27B27A"), .forgeSuccess],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 104, height: 104)
                        .shadow(color: Color.forgeSuccess.opacity(0.35), radius: 22, y: 9)

                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                Text("You're checked in")
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.6)
                    .foregroundColor(.forgeInk)
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.15), value: appeared)

                Group {
                    Text("Student card scanned · attendance recorded at ")
                        .foregroundColor(.forgeInk3)
                    + Text(checkInTime)
                        .fontWeight(.semibold)
                        .foregroundColor(.forgeInk2)
                    + Text(".")
                        .foregroundColor(.forgeInk3)
                }
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appeared)

                Spacer()

                // Receipt card
                ForgeCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ATTENDANCE RECEIPT")
                            .font(.system(size: 11.5, weight: .bold))
                            .kerning(1)
                            .foregroundColor(.forgeMuted)

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.session.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .kerning(-0.3)
                                    .foregroundColor(.forgeInk)
                                Text("\(vm.session.code) · Room \(vm.session.room)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.forgeInk3)
                            }
                            Spacer()
                            Text("#A-2814")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.forgeInk2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.forgeChip)
                                .cornerRadius(6)
                        }
                        .padding(.top, 6)

                        Divider().padding(.vertical, 14)

                        ReceiptRow(label: "Identity",     detail: "Face ID · verified",         done: true)
                        ReceiptRow(label: "Teacher card", detail: "Dr. Claire Moreau · NFC",    done: true)
                        ReceiptRow(label: "Student card", detail: "\(auth.user?.displayName ?? "Student") · NFC", done: vm.studentCardID != nil)
                    }
                    .padding(18)
                }
                .padding(.horizontal, 16)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.3), value: appeared)

                // Actions
                VStack(spacing: 10) {
                    if vm.studentCardID == nil {
                        ForgeButton(title: "Tap student card to confirm", systemIcon: "wave.3.right") {
                            vm.scanStudentCard()
                        }
                    } else {
                        ForgeButton(title: "Done", action: onDone)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 44)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.35), value: appeared)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
    }
}

struct ReceiptRow: View {
    let label: String
    let detail: String
    var done: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(done ? Color.forgeSuccess : Color.forgeMuted.opacity(0.2))
                    .frame(width: 16, height: 16)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Text(label)
                .font(.system(size: 13.5))
                .foregroundColor(.forgeInk2)
            Spacer()
            Text(detail)
                .font(.system(size: 13))
                .foregroundColor(.forgeMuted)
        }
        .padding(.vertical, 8)
    }
}
