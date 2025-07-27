import UIKit
import CoreNFC

// Import the delegate protocol
import UIKit

class NFCController: NSObject, NFCNDEFReaderSessionDelegate {
    static let shared = NFCController()
    weak var delegate: NFCControllerDelegate?
    
    // Make session property internal instead of private
    var nfcSession: NFCNDEFReaderSession?
    
    // Animation properties
    private var scanningLayer: CAShapeLayer?
    
    // Inside beginScanning() method
    func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC not supported on this device")
            // Provide error feedback for unsupported device
            Constants.Haptics.error()
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near your Shift tag."
        nfcSession?.begin()
        
        // Provide haptic feedback when scanning begins
        Constants.Haptics.nfcScanStart()
        print("NFC scanning started with haptic feedback")
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session is active")
        
        // Provide light haptic feedback when session becomes active
        Constants.Haptics.light()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC scan ended: \(error.localizedDescription)")
        
        // INSTANT haptic feedback - zero delay, maximum responsiveness
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                // User tapped "X" - INSTANT ultra-light pulse
                Constants.Haptics.nfcScanCanceled()
                print("NFC scan canceled by user")
                
            case .readerSessionInvalidationErrorSessionTimeout:
                // Session timed out - immediate warning
                Constants.Haptics.gentleWarning()
                print("NFC scan timed out")
                
            default:
                // Other errors - immediate error feedback
                Constants.Haptics.nfcScanError()
                print("NFC scan error: \(nfcError.localizedDescription)")
            }
        } else {
            // Fallback - immediate response
            if error.localizedDescription.contains("canceled") || error.localizedDescription.contains("cancelled") {
                Constants.Haptics.nfcScanCanceled()
                print("NFC scan canceled")
            } else {
                Constants.Haptics.nfcScanError()
                print("NFC scan failed: \(error.localizedDescription)")
            }
        }
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
            // Notify delegate about the tag scan
            self.delegate?.didScanNFCTag()
            
            // Also pass the tag ID to the delegate
            self.delegate?.didDetectTagWithID(tagID: tagString)
            
            if tagString == "SHIFT_TAG_001" {
                // Provide success haptic feedback
                Constants.Haptics.nfcScanSuccess()
                
                // Notify delegate that focus mode was toggled
                self.delegate?.didToggleFocusMode()
                print("Recognized tag — focus mode toggled")
            } else {
                // Provide error haptic feedback for unrecognized tag
                Constants.Haptics.nfcScanError()
                print("Unrecognized tag content")
            }
        }
    }
    
    // MARK: - Animation Methods
    
    // Create a scanning animation on a view
    func createScanningAnimation(on view: UIView) {
        // Remove any existing animation
        removeScanningAnimation()
        
        // Use the extension method to create the animation
        scanningLayer = view.addScanningAnimation()
    }
    
    // Remove scanning animation
    func removeScanningAnimation() {
        scanningLayer?.removeFromSuperlayer()
        scanningLayer = nil
    }
}
