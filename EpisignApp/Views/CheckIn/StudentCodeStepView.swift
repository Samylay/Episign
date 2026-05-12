import SwiftUI

struct StudentCodeStepView: View {
    @ObservedObject var vm: CheckInViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthService
    @FocusState private var codeFocused: Bool

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
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.forgeMuted)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)

                ForgePill(text: "CODE FORMATEUR OK", tone: .live, dot: true)
                    .padding(.top, 28)

                Text("Ton code étudiant")
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.6)
                    .foregroundColor(.forgeInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                Text("Saisit ton code personnel à 6 chiffres fourni par ton établissement.")
                    .font(.system(size: 15))
                    .foregroundColor(.forgeInk3)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer()

                // OTP input
                ForgeCard {
                    VStack(spacing: 14) {
                        Text("Code étudiant à 6 chiffres")
                            .font(.system(size: 12))
                            .foregroundColor(.forgeMuted)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { i in
                                let char: String = i < vm.studentCode.count
                                    ? String(vm.studentCode[vm.studentCode.index(vm.studentCode.startIndex, offsetBy: i)])
                                    : ""
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.forgeBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    i == vm.studentCode.count ? Color.forgeBrand : Color.forgeHairline,
                                                    lineWidth: i == vm.studentCode.count ? 1.5 : 1
                                                )
                                        )
                                    Text(char)
                                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                                        .foregroundColor(.forgeInk)
                                }
                                .frame(width: 42, height: 50)
                            }
                        }
                        .overlay(
                            TextField("", text: Binding(
                                get: { vm.studentCode },
                                set: { newVal in
                                    let filtered = String(newVal.filter(\.isNumber).prefix(6))
                                    vm.studentCode = filtered
                                }
                            ))
                            .keyboardType(.numberPad)
                            .focused($codeFocused)
                            .opacity(0.01)
                        )

                        if let err = vm.errorMessage {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.forgeWarn)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 24)

                if vm.isProcessing {
                    ProgressView()
                        .tint(.forgeBrand)
                        .padding(.top, 20)
                        .padding(.bottom, 44)
                } else {
                    ForgeButton(title: "Signer ma présence", action: {
                        Task { await vm.submitAttendance(forgeLogin: auth.user?.login ?? "") }
                    })
                    .disabled(vm.studentCode.count < 6)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 44)
                }
            }
        }
        .onAppear { codeFocused = true }
    }
}
