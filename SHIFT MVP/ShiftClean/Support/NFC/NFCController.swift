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
        
        // Provide haptic feedback when scanning begins
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session is active")
        
        // Provide haptic feedback when session becomes active
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC scan failed: \(error.localizedDescription)")
        
        // Provide error haptic feedback if not user canceled
        if !error.localizedDescription.contains("canceled") {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
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
                // Toggle focus mode using the unified AppBlockingService
                AppBlockingService.shared.toggleFocusMode()
                
                // Provide success haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
                
                // Also provide a medium impact for physical sensation
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                
                // Notify delegate that focus mode was toggled
                self.delegate?.didToggleFocusMode()
                print("Recognized tag — focus mode toggled")
            } else {
                // Provide error haptic feedback for unrecognized tag
                UINotificationFeedbackGenerator().notificationOccurred(.error)
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
