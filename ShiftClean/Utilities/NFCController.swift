import Foundation
import CoreNFC
import UIKit

// Protocol for UI callbacks
protocol NFCControllerDelegate: AnyObject {
    func didScanNFCTag()
    func didToggleFocusMode()
}

class NFCController: NSObject, NFCNDEFReaderSessionDelegate {

    static let shared = NFCController()

    weak var delegate: NFCControllerDelegate?

    // Make session property internal instead of private
    var nfcSession: NFCNDEFReaderSession?

    // Inside beginScanning() method
    func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC not supported on this device")
            return
        }
        
        // Force dark mode at the system level before starting NFC session
        if #available(iOS 13.0, *) {
            // Use UIWindow.appearance() instead of trying to access windows directly
            UIWindow.appearance().overrideUserInterfaceStyle = .dark
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near your Shift tag."
        nfcSession?.begin()
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
            self.delegate?.didScanNFCTag()
            
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
