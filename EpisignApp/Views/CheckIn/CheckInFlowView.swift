import SwiftUI
import LocalAuthentication

enum CheckInStep: Int, CaseIterable {
    case faceID = 0
    case teacherScan = 1
    case confirm = 2
}

@MainActor
class CheckInViewModel: ObservableObject {
    @Published var step: CheckInStep = .faceID
    @Published var faceIDDone = false
    @Published var teacherCardID: String?
    @Published var studentCardID: String?
    @Published var errorMessage: String?
    @Published var isProcessing = false

    let session: CourseSession
    let nfc = NFCService()

    var teacherName: String { "Dr. Claire Moreau" }

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
                withAnimation(.spring(response: 0.4)) { step = .teacherScan }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    // MARK: - Step 2: Teacher NFC

    func scanTeacherCard() {
        nfc.scan(prompt: "Hold iPhone near instructor's NFC badge") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let id):
                    self?.teacherCardID = id
                    withAnimation(.spring(response: 0.4)) { self?.step = .confirm }
                case .failure(let err):
                    self?.errorMessage = err.localizedDescription
                }
            }
        }
    }

    // MARK: - Step 3: Confirm (auto-scans student card)

    func scanStudentCard() {
        nfc.scan(prompt: "Tap your student card to complete check-in") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let id):
                    self?.studentCardID = id
                case .failure(let err):
                    self?.errorMessage = err.localizedDescription
                }
            }
        }
    }
}

struct CheckInFlowView: View {
    let session: CourseSession
    @StateObject private var vm: CheckInViewModel
    @Environment(\.dismiss) private var dismiss

    init(session: CourseSession) {
        self.session = session
        _vm = StateObject(wrappedValue: CheckInViewModel(session: session))
    }

    var body: some View {
        switch vm.step {
        case .faceID:
            FaceIDStepView(vm: vm)
        case .teacherScan:
            TeacherScanStepView(vm: vm)
        case .confirm:
            StudentConfirmStepView(vm: vm, onDone: { dismiss() })
        }
    }
}
