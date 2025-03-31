import Foundation
import CoreNFC
import UIKit

// Protocol for UI callbacks
protocol NFCControllerDelegate: AnyObject {
    func didToggleFocusMode()
}

class NFCController: NSObject, NFCNDEFReaderSessionDelegate {

    static let shared = NFCController()

    weak var delegate: NFCControllerDelegate?

    private var session: NFCNDEFReaderSession?

    func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC not supported on this device")
            return
        }

        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near your Shift tag."
        session?.begin()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session is active")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC scan failed: \(error.localizedDescription)")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("Raw NFC NDEF Messages: \(messages)")

        guard let record = messages.first?.records.first else {
            print("No valid NDEF records found")
            return
        }

        let payloadData = record.payload
        let languageCodeLength = Int(payloadData.first ?? 0)
        let textData = payloadData.dropFirst(languageCodeLength + 1)
        guard let tagString = String(data: textData, encoding: .utf8) else {
            print("Failed to decode NFC payload as UTF-8 string")
            return
        }

        print("Scanned NFC Tag Payload: \(tagString)")

        DispatchQueue.main.async {
            if tagString == "SHIFT_TAG_001" {
                AppBlockingManager.shared.toggleFocusMode()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self.delegate?.didToggleFocusMode()
                print("Recognized tag — focus mode toggled")
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("Unrecognized tag content")
            }
        }
    }
}
