import SwiftUI

struct TeacherScanStepView: View {
    @ObservedObject var vm: CheckInViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var codeFocused: Bool

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

                ForgePill(text: "IDENTITY VERIFIED", tone: .live, dot: true)
                    .padding(.top, 28)

                Text("Code formateur")
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.6)
                    .foregroundColor(.forgeInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                Text("Saisit le code à 6 chiffres affiché sur l'écran du formateur.")
                    .font(.system(size: 15))
                    .foregroundColor(.forgeInk3)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer()

                // Instructor badge illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.forgeBrand, Color.forgeBrandDeep],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 124)
                        .shadow(color: Color.forgeBrand.opacity(0.35), radius: 20, y: 10)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("FACULTY · FORMATEUR")
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
                    .frame(width: 200, height: 124, alignment: .leading)
                }

                Spacer()

                // OTP input
                ForgeCard {
                    VStack(spacing: 14) {
                        Text("Code à 6 chiffres affiché sur l'interface du formateur")
                            .font(.system(size: 12))
                            .foregroundColor(.forgeMuted)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { i in
                                let char: String = i < vm.teacherCode.count
                                    ? String(vm.teacherCode[vm.teacherCode.index(vm.teacherCode.startIndex, offsetBy: i)])
                                    : ""
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.forgeBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    i == vm.teacherCode.count ? Color.forgeBrand : Color.forgeHairline,
                                                    lineWidth: i == vm.teacherCode.count ? 1.5 : 1
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
                                get: { vm.teacherCode },
                                set: { newVal in
                                    let filtered = String(newVal.filter(\.isNumber).prefix(6))
                                    vm.teacherCode = filtered
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
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 24)

                ForgeButton(title: "Continuer", action: { Task { await vm.confirmTeacherCode() } })
                    .disabled(vm.teacherCode.count < 6)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 44)
            }
        }
        .onAppear { codeFocused = true }
    }
}
