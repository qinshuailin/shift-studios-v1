import UIKit
import CoreNFC

// Protocol for UI callbacks - moved to a separate file to avoid ambiguity
protocol NFCControllerDelegate: AnyObject {
    func didScanNFCTag()
    func didToggleFocusMode()
    func didDetectTagWithID(tagID: String)
}
