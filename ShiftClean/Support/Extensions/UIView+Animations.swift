import UIKit

// MARK: - UIView Animation Extensions
extension UIView {
    
    /// Creates a circular scanning animation on the view
    /// - Returns: The created shape layer for reference
    @discardableResult
    func addScanningAnimation() -> CAShapeLayer {
        // Create a circular path
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 20
        let circlePath = UIBezierPath(arcCenter: center,
                                     radius: radius,
                                     startAngle: 0,
                                     endAngle: 2 * CGFloat.pi,
                                     clockwise: true)
        
        // Create a shape layer for the scanning effect
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 3
        shapeLayer.strokeEnd = 0
        layer.addSublayer(shapeLayer)
        
        // Create the animation
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 2.0
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = .infinity
        shapeLayer.add(animation, forKey: "scanningAnimation")
        
        // Add a pulse effect
        addPulseEffect(at: center, withRadius: radius)
        
        return shapeLayer
    }
    
    /// Adds a pulsing effect to the view
    /// - Parameters:
    ///   - center: Center point of the pulse
    ///   - radius: Radius of the pulse
    private func addPulseEffect(at center: CGPoint, withRadius radius: CGFloat) {
        let pulseLayer = CAShapeLayer()
        let pulsePath = UIBezierPath(arcCenter: center,
                                    radius: radius,
                                    startAngle: 0,
                                    endAngle: 2 * CGFloat.pi,
                                    clockwise: true)
        
        pulseLayer.path = pulsePath.cgPath
        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.strokeColor = UIColor(white: 1.0, alpha: 0.5).cgColor
        pulseLayer.lineWidth = 2
        layer.addSublayer(pulseLayer)
        
        // Create pulse animation group
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.8
        opacityAnimation.toValue = 0
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.2
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [opacityAnimation, scaleAnimation]
        animationGroup.duration = 1.5
        animationGroup.repeatCount = .infinity
        
        pulseLayer.add(animationGroup, forKey: "pulseAnimation")
    }
    
    /// Creates a ripple effect from a specific point
    /// - Parameter center: The center point of the ripple
    func createRippleEffect(from center: CGPoint) {
        let rippleView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        rippleView.backgroundColor = .clear
        rippleView.layer.borderColor = UIColor.white.cgColor
        rippleView.layer.borderWidth = 2
        rippleView.layer.cornerRadius = 10
        rippleView.center = center
        addSubview(rippleView)
        
        UIView.animate(withDuration: 0.8, animations: {
            rippleView.transform = CGAffineTransform(scaleX: 15, y: 15)
            rippleView.alpha = 0
        }, completion: { _ in
            rippleView.removeFromSuperview()
        })
    }
    
    /// Shows a toast message at the bottom of the view
    /// - Parameter message: The message to display
    func showToast(message: String) {
        let toastLabel = UILabel(frame: CGRect(x: frame.width/2 - 150, y: frame.height - 100, width: 300, height: 40))
        toastLabel.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.layer.cornerRadius = 20
        toastLabel.clipsToBounds = true
        addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
}
