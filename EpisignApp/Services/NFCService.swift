import Foundation
import CoreNFC

class NFCService: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var scannedID: String?
    @Published var isScanning = false
    @Published var errorMessage: String?

    private var session: NFCTagReaderSession?
    private var onResult: ((Result<String, Error>) -> Void)?

    func scan(prompt: String = "Hold your iPhone near the NFC card", completion: @escaping (Result<String, Error>) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            completion(.failure(NFCError.unavailable))
            return
        }
        onResult = completion
        isScanning = true
        session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self, queue: nil)
        session?.alertMessage = prompt
        session?.begin()
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            if let err = error as? NFCReaderError,
               err.code == .readerSessionInvalidationErrorUserCanceled ||
               err.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
                return
            }
            self.errorMessage = error.localizedDescription
            self.onResult?(.failure(error))
            self.onResult = nil
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                session.invalidate(errorMessage: "Connection failed.")
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.onResult?(.failure(error))
                    self.onResult = nil
                }
                return
            }

            let identifier: String
            switch tag {
            case .iso7816(let t):  identifier = t.identifier.hexString
            case .feliCa(let t):   identifier = t.currentIDm.hexString
            case .iso15693(let t): identifier = t.identifier.hexString
            case .miFare(let t):   identifier = t.identifier.hexString
            @unknown default:      identifier = "UNKNOWN"
            }

            session.alertMessage = "Card read successfully ✓"
            session.invalidate()

            DispatchQueue.main.async {
                self.isScanning = false
                self.scannedID = identifier
                self.onResult?(.success(identifier))
                self.onResult = nil
            }
        }
    }

    enum NFCError: LocalizedError {
        case unavailable
        var errorDescription: String? { "NFC is not available on this device." }
    }
}

private extension Data {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }
}
