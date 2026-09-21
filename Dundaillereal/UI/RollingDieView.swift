import UIKit

/// Six independently drawn faces on a real Core Animation cube. No simulated face
/// changes or random values: its forward face is the engine's committed result.
final class RollingDieView: UIView {
    private let cube = CATransformLayer()
    private let faces = (0..<6).map { _ in CALayer() }
    private let shadow = CAShapeLayer()
    private let value: Int
    private var edge: CGFloat = 0
    private var currentProgress: Double = 1
    private var currentIndex = 0

    init(value: Int) {
        self.value = value
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityLabel = "\(value) pips"
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1.35).isActive = true
        layer.addSublayer(shadow)
        shadow.fillColor = Theme.ink.withAlphaComponent(0.14).cgColor
        layer.addSublayer(cube)
        let second = (1...6).first { $0 != value && $0 != 7 - value }!
        let third = (1...6).first { ![value, 7-value, second, 7-second].contains($0) }!
        let numbers = [value, 7-value, second, 7-second, third, 7-third]
        for (index, face) in faces.enumerated() {
            face.contents = Self.texture(numbers[index], shade: index == 0 ? 1 : 0.91).cgImage
            face.isDoubleSided = false
            face.cornerRadius = 6
            face.masksToBounds = true
            cube.addSublayer(face)
        }
    }
    required init?(coder: NSCoder) { fatalError("Use init(value:)") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        edge = bounds.width * 0.66
        cube.bounds = CGRect(x: 0, y: 0, width: edge, height: edge)
        cube.position = CGPoint(x: bounds.midX, y: bounds.midY)
        var perspective = CATransform3DIdentity
        perspective.m34 = -1 / 550
        layer.sublayerTransform = perspective
        let rotations: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0,0,1,0), (.pi,0,1,0), (.pi/2,0,1,0), (-.pi/2,0,1,0),
            (.pi/2,1,0,0), (-.pi/2,1,0,0)
        ]
        for (face, rotation) in zip(faces, rotations) {
            face.bounds = cube.bounds
            face.position = CGPoint(x: edge / 2, y: edge / 2)
            var t = CATransform3DMakeRotation(rotation.0, rotation.1, rotation.2, rotation.3)
            t = CATransform3DTranslate(t, 0, 0, edge / 2)
            face.transform = t
        }
        CATransaction.commit()
        pose(progress: currentProgress, index: currentIndex)
    }

    func pose(progress: Double, index: Int) {
        currentProgress = progress
        currentIndex = index
        let p = CGFloat(min(1, max(0, progress)))
        // Euler angles are evaluated per frame so complete revolutions cannot
        // collapse into the shortest-path interpolation of an affine transform.
        let remaining = pow(1 - p, 2.1)
        let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
        let lift = sin(p * .pi) * 30 + abs(sin(p * .pi * 3)) * 10 * (1 - p)
        var t = CATransform3DMakeTranslation(sin(p * .pi * 4) * 5 * (1-p), -lift, 0)
        t = CATransform3DRotate(t, -0.18 + remaining * .pi * 4, 1, 0, 0)
        t = CATransform3DRotate(t, 0.23 + remaining * .pi * 6 * direction, 0, 1, 0)
        t = CATransform3DRotate(t, remaining * .pi * 2 * direction, 0, 0, 1)
        CATransaction.begin(); CATransaction.setDisableActions(true)
        cube.transform = t
        let spread = 1 + lift / 80
        shadow.path = UIBezierPath(ovalIn: CGRect(x: bounds.midX - edge * 0.52 * spread, y: bounds.midY + edge * 0.48, width: edge * 1.04 * spread, height: 10)).cgPath
        shadow.opacity = Float(1 - lift / 70)
        CATransaction.commit()
    }

    private static func texture(_ value: Int, shade: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 180, height: 180)).image { context in
            let rect = CGRect(x: 0, y: 0, width: 180, height: 180)
            let colors = [UIColor(white: shade, alpha: 1).cgColor, UIColor(red: 0.9 * shade, green: 0.85 * shade, blue: 0.71 * shade, alpha: 1).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 180, y: 180), options: [])
            UIColor.white.withAlphaComponent(0.65).setStroke()
            let border = UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 10); border.lineWidth = 3; border.stroke()
            let positions: [(CGFloat, CGFloat)]
            switch value {
            case 1: positions = [(0.5,0.5)]
            case 2: positions = [(0.27,0.27),(0.73,0.73)]
            case 3: positions = [(0.27,0.27),(0.5,0.5),(0.73,0.73)]
            case 4: positions = [(0.27,0.27),(0.73,0.27),(0.27,0.73),(0.73,0.73)]
            case 5: positions = [(0.27,0.27),(0.73,0.27),(0.5,0.5),(0.27,0.73),(0.73,0.73)]
            default: positions = [(0.27,0.25),(0.73,0.25),(0.27,0.5),(0.73,0.5),(0.27,0.75),(0.73,0.75)]
            }
            for (x,y) in positions {
                UIColor.white.withAlphaComponent(0.8).setFill()
                UIBezierPath(ovalIn: CGRect(x: x*180-12, y: y*180-10, width: 24, height: 24)).fill()
                Theme.ink.setFill()
                UIBezierPath(ovalIn: CGRect(x: x*180-12, y: y*180-12, width: 24, height: 24)).fill()
            }
        }
    }
}
