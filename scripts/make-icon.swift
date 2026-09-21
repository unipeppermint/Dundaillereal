import AppKit
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSColor(calibratedRed: 0.969, green: 0.953, blue: 0.914, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
let ink = NSColor(calibratedRed: 0.125, green: 0.208, blue: 0.290, alpha: 1)
let coral = NSColor(calibratedRed: 0.929, green: 0.471, blue: 0.369, alpha: 1)
let path = NSBezierPath()
path.move(to: NSPoint(x: 40, y: 250))
path.curve(
    to: NSPoint(x: 990, y: 730), controlPoint1: NSPoint(x: 990, y: 80),
    controlPoint2: NSPoint(x: 80, y: 850))
path.lineWidth = 38
ink.setStroke()
path.stroke()
coral.setFill()
NSBezierPath(ovalIn: NSRect(x: 90, y: 200, width: 100, height: 100)).fill()
NSBezierPath(ovalIn: NSRect(x: 850, y: 670, width: 100, height: 100)).fill()
NSColor.white.setFill()
let dice = NSBezierPath(
    roundedRect: NSRect(x: 282, y: 282, width: 460, height: 460), xRadius: 85, yRadius: 85)
dice.fill()
ink.setStroke()
dice.lineWidth = 14
dice.stroke()
ink.setFill()
for (x, y) in [(400, 400), (624, 400), (512, 512), (400, 624), (624, 624)] {
    NSBezierPath(ovalIn: NSRect(x: x - 37, y: y - 37, width: 74, height: 74)).fill()
}
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(
    to: URL(fileURLWithPath: CommandLine.arguments[1]))
