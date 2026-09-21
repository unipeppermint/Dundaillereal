import UIKit
import SceneKit

/// Cached native renders keep result dice tactile while values stay code-driven.
/// Decorative cover images never supply the actual result or hit target.
enum ResultDieRenderer {
    private static var cache: [Int: UIImage] = [:]

    static func image(value: Int) -> UIImage {
        if let image = cache[value] { return image }
        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        let body = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.12)
        body.chamferSegmentCount = 8
        let ivory = SCNMaterial()
        ivory.diffuse.contents = UIColor(red: 0.96, green: 0.92, blue: 0.83, alpha: 1)
        ivory.lightingModel = .blinn
        ivory.specular.contents = UIColor(white: 0.12, alpha: 1)
        ivory.shininess = 0.18
        body.materials = [ivory]
        let die = SCNNode(geometry: body)
        // No in-plane rotation: all result faces read upright. A near-frontal
        // view exposes only a narrow edge; bevel lighting supplies the depth.
        die.eulerAngles = SCNVector3(-0.045, -0.055, 0)
        scene.rootNode.addChildNode(die)

        let side = (1...6).first { $0 != value && $0 != 7 - value }!
        let top = (1...6).first { ![value, 7-value, side, 7-side].contains($0) }!
        let values = [value, 7-value, side, 7-side, top, 7-top]
        let positions: [SCNVector3] = [.init(0,0,0.501), .init(0,0,-0.501), .init(0.501,0,0), .init(-0.501,0,0), .init(0,0.501,0), .init(0,-0.501,0)]
        let angles: [SCNVector3] = [.init(0,0,0), .init(0,Float.pi,0), .init(0,Float.pi/2,0), .init(0,-Float.pi/2,0), .init(-Float.pi/2,0,0), .init(Float.pi/2,0,0)]
        for index in 0..<6 {
            let face = SCNPlane(width: 0.74, height: 0.74)
            let material = SCNMaterial()
            material.diffuse.contents = pips(values[index])
            material.lightingModel = .constant
            material.isDoubleSided = false
            face.materials = [material]
            let node = SCNNode(geometry: face)
            node.position = positions[index]
            node.eulerAngles = angles[index]
            die.addChildNode(node)
        }
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 0.76
        camera.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(camera)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 600
        keyLight.position = SCNVector3(-3, 5, 6)
        scene.rootNode.addChildNode(keyLight)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 450
        ambient.light?.color = UIColor(red: 1, green: 0.96, blue: 0.88, alpha: 1)
        scene.rootNode.addChildNode(ambient)
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        renderer.pointOfView = camera
        let image = renderer.snapshot(atTime: 0, with: CGSize(width: 300, height: 300), antialiasingMode: .multisampling4X)
        cache[value] = image
        return image
    }

    private static func pips(_ value: Int) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256)).image { renderer in
            let points: [(CGFloat, CGFloat)]
            switch value {
            case 1: points = [(0.5,0.5)]
            case 2: points = [(0.22,0.22),(0.78,0.78)]
            case 3: points = [(0.22,0.22),(0.5,0.5),(0.78,0.78)]
            case 4: points = [(0.22,0.22),(0.78,0.22),(0.22,0.78),(0.78,0.78)]
            case 5: points = [(0.22,0.22),(0.78,0.22),(0.5,0.5),(0.22,0.78),(0.78,0.78)]
            default: points = [(0.22,0.20),(0.78,0.20),(0.22,0.5),(0.78,0.5),(0.22,0.80),(0.78,0.80)]
            }
            let context = renderer.cgContext
            for (x,y) in points {
                let rect = CGRect(x: x*256-22, y: y*256-22, width: 44, height: 44)
                UIColor(red: 0.99, green: 0.96, blue: 0.86, alpha: 0.9).setFill()
                UIBezierPath(ovalIn: rect.offsetBy(dx: 0, dy: 2)).fill()
                context.saveGState()
                UIBezierPath(ovalIn: rect).addClip()
                let colors = [UIColor(white: 0.045, alpha: 1).cgColor, UIColor(white: 0.19, alpha: 1).cgColor] as CFArray
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1])!
                context.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
                context.restoreGState()
            }
        }
    }
}
