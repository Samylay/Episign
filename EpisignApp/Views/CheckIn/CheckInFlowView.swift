import SwiftUI
import LocalAuthentication

enum CheckInStep: Int, CaseIterable {
    case faceID = 0
    case teacherCode = 1
    case studentCode = 2
    case done = 3
}

@MainActor
class CheckInViewModel: ObservableObject {
    @Published var step: CheckInStep = .faceID
    @Published var faceIDDone = false
    @Published var teacherCode = ""
    @Published var studentCode = ""
    @Published var errorMessage: String?
    @Published var isProcessing = false
    @Published var signedAt: Date?

    let session: CourseSession

    var teacherName: String { session.teacher }

    init(session: CourseSession) {
        self.session = session
    }

    // MARK: - Step 1: Face ID

    func authenticateWithFaceID() async {
        isProcessing = true
        errorMessage = nil

        let ctx = LAContext()
        var authErr: NSError?

        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authErr) else {
            errorMessage = authErr?.localizedDescription ?? "Biometrics unavailable"
            isProcessing = false
            return
        }

        do {
            let success = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verify your identity to sign attendance"
            )
            if success {
                faceIDDone = true
                withAnimation(.spring(response: 0.4)) { step = .teacherCode }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    // MARK: - Step 2: Teacher code

    func confirmTeacherCode() async {
        guard teacherCode.count == 6, teacherCode.allSatisfy(\.isNumber) else {
            errorMessage = "Code invalide — 6 chiffres requis."
            return
        }
        isProcessing = true
        errorMessage = nil
        do {
            let valid = try await SupabaseService.shared.validateTeacherCode(
                sessionId: session.id,
                teacherCode: teacherCode
            )
            if valid {
                withAnimation(.spring(response: 0.4)) { step = .studentCode }
            } else {
                errorMessage = "Code formateur incorrect."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    // MARK: - Step 3: Student code + submit

    var onSuccess: (() -> Void)?

    func submitAttendance(forgeLogin: String) async {
        guard studentCode.count == 6, studentCode.allSatisfy(\.isNumber) else {
            errorMessage = "Code invalide — 6 chiffres requis."
            return
        }
        isProcessing = true
        errorMessage = nil
        do {
            let result = try await SupabaseService.shared.submitAttendance(
                forgeLogin: forgeLogin,
                teacherCode: teacherCode,
                studentCode: studentCode,
                sessionId: session.id
            )
            if result.ok {
                signedAt = Date()
                onSuccess?()
                withAnimation(.spring(response: 0.4)) { step = .done }
            } else {
                errorMessage = result.error ?? "Signature refusée. Vérifie ton code."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}

struct CheckInFlowView: View {
    let session: CourseSession
    var onSuccess: (() -> Void)? = nil
    @StateObject private var vm: CheckInViewModel
    @Environment(\.dismiss) private var dismiss

    init(session: CourseSession, onSuccess: (() -> Void)? = nil) {
        self.session = session
        self.onSuccess = onSuccess
        _vm = StateObject(wrappedValue: CheckInViewModel(session: session))
    }

    var body: some View {
        switch vm.step {
        case .faceID:
            FaceIDStepView(vm: vm)
        case .teacherCode:
            TeacherScanStepView(vm: vm)
        case .studentCode:
            StudentCodeStepView(vm: vm)
        case .done:
            StudentConfirmStepView(vm: vm, onDone: { dismiss() })
        }
    }
    .onAppear { vm.onSuccess = onSuccess }
}
