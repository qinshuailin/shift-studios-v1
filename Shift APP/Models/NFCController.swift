import UIKit
import CoreNFC

class NFCController: NSObject, NFCNDEFReaderSessionDelegate {
    
    static let shared = NFCController()
    var session: NFCNDEFReaderSession?
    var onTagDetected: ((String) -> Void)?
    
    func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC reading not available on this device")
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the Shift Studios tag"
        session?.begin()
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC session invalidated: \(error.localizedDescription)")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            return
        }
        
        // Check if this is a company-issued tag
        if isCompanyTag(payload) {
            DispatchQueue.main.async {
                self.onTagDetected?(payload)
            }
        }
    }
    
    private func isCompanyTag(_ payload: String) -> Bool {
        // Implement your company tag validation logic here
        // For example, check for a specific prefix or pattern
        return payload.contains("ShiftStudios-")
    }
}
