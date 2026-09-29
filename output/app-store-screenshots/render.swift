import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("output/app-store-screenshots")
let output = root.appendingPathComponent("en-US/iphone-6.9")
let source = root.appendingPathComponent("design-assets/screenshots")
let navy = NSColor(srgbRed: 0.12, green: 0.22, blue: 0.29, alpha: 1)
let coral = NSColor(srgbRed: 0.91, green: 0.40, blue: 0.29, alpha: 1)
let sage = NSColor(srgbRed: 0.45, green: 0.55, blue: 0.44, alpha: 1)
let cream = NSColor(srgbRed: 0.97, green: 0.95, blue: 0.90, alpha: 1)
let atlas = NSImage(contentsOf: root.appendingPathComponent("design-assets/dice-variations.png"))!
struct Slide {
    let file: String
    let slug: String
    let title: String
    let subtitle: String
    let label: String
}
let slides = [
    Slide(file: "14.58.32", slug: "01-discover", title: "Small games.\nBig moments.", subtitle: "Three dice games. One place to play.", label: "PLAY YOUR WAY"),
    Slide(file: "15.00.21", slug: "02-roll", title: "Roll the dice.\nFind your stop.", subtitle: "Pick a target. Reroll. Make it count.", label: "MAKE YOUR MOVE"),
    Slide(file: "14.59.25", slug: "03-together", title: "Your turn.\nThen theirs.", subtitle: "Pass the phone. Play with 1–4 players.", label: "SHARE THE TABLE"),
    Slide(file: "14.59.09", slug: "04-rules", title: "A little game.\nReady to go.", subtitle: "Learn the rules and play offline.", label: "PICK UP & PLAY"),
    Slide(file: "14.58.43", slug: "05-create", title: "Your idea.\nYour rules.", subtitle: "Start with a game. Make it your own.", label: "RULE WORKSHOP"),
    Slide(file: "14.58.49", slug: "06-collection", title: "Keep the games\nyou love.", subtitle: "Save favorites. Import a friend’s game.", label: "YOUR COLLECTION")
]
func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func text(_ string: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = navy, tracking: CGFloat = 0) {
    let p = NSMutableParagraphStyle()
    p.lineSpacing = 1
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    (string as NSString).draw(in: CGRect(x:x,y:y,width:w,height:h), withAttributes: [.font:font,.foregroundColor:color,.paragraphStyle:p,.kern:tracking])
}
func canvas(_ width: Int, _ height: Int, _ draw: () -> Void) -> NSBitmapImageRep {
    let bitmap = CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    let context = NSGraphicsContext(cgContext:bitmap,flipped:false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    let transform = AffineTransform(translationByX:0,byY:CGFloat(height))
    (transform as NSAffineTransform).concat()
    let flip = AffineTransform(scaleByX:1,byY:-1)
    (flip as NSAffineTransform).concat()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return NSBitmapImageRep(cgImage:bitmap.makeImage()!)
}
func save(_ rep: NSBitmapImageRep, _ url: URL) {
    try! rep.representation(using:.png,properties:[:])!.write(to:url)
}
for (index, slide) in slides.enumerated() {
    let screen = NSImage(contentsOf: source.appendingPathComponent("\(slide.file).png"))!
    let rep = canvas(1260,2736) {
        cream.setFill(); NSBezierPath(rect:CGRect(x:0,y:0,width:1260,height:2736)).fill()
        let wash = index % 2 == 0 ? sage : coral
        wash.withAlphaComponent(0.07).setFill()
        NSBezierPath(ovalIn:CGRect(x:610,y:-220,width:1000,height:960)).fill()
        sage.withAlphaComponent(0.10).setFill()
        NSBezierPath(ovalIn:CGRect(x:-500,y:1850,width:1450,height:1400)).fill()
        let route = NSBezierPath()
        route.move(to:CGPoint(x:-100,y:950))
        route.curve(to:CGPoint(x:1250,y:2470),controlPoint1:CGPoint(x:1600,y:1200),controlPoint2:CGPoint(x:-500,y:1910))
        route.lineWidth = 5
        route.setLineDash([14,20], count:2, phase:CGFloat(index*10))
        sage.withAlphaComponent(0.28).setStroke(); route.stroke()
        text("DICE WORKSHOP",90,94,710,48,size:32,weight:.bold,tracking:5)
        rounded(CGRect(x:90,y:176,width:58,height:7),3,coral)
        text(slide.title,86,229,1085,240,size:98,weight:.bold,tracking:-3)
        text(slide.subtitle,92,484,1090,66,size:39,weight:.regular,color:navy.withAlphaComponent(0.78))
        // Artwork stays outside the real app screenshot.
        let col = index % 2
        let row = index / 2
        atlas.draw(in:CGRect(x:855,y:12,width:370,height:370),from:CGRect(x:col*512,y:(2-row)*512,width:512,height:512),operation:.sourceOver,fraction:1,respectFlipped:true,hints:nil)
        let frame = CGRect(x:174,y:631,width:912,height:1980)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow(); shadow.shadowColor = navy.withAlphaComponent(0.22); shadow.shadowBlurRadius = 48; shadow.shadowOffset = NSSize(width:0,height:-20); shadow.set()
        rounded(frame,98,navy)
        NSGraphicsContext.restoreGraphicsState()
        rounded(frame.insetBy(dx:4,dy:4),94,NSColor(srgbRed:0.26,green:0.31,blue:0.32,alpha:1))
        rounded(frame.insetBy(dx:9,dy:9),89,NSColor(srgbRed:0.07,green:0.10,blue:0.12,alpha:1))
        let imageRect = CGRect(x:190,y:647,width:880,height:880*2622/1206)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect:imageRect,xRadius:78,yRadius:78).addClip()
        screen.draw(in:imageRect,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:nil)
        NSGraphicsContext.restoreGraphicsState()
        text(slide.label,92,2660,1000,42,size:24,weight:.semibold,color:sage,tracking:4)
        text(String(format:"%02d",index+1),1110,2657,80,45,size:28,weight:.medium,color:sage)
    }
    save(rep,output.appendingPathComponent(slide.slug+".png"))
}
let overview = canvas(1512,815) {
    cream.setFill(); NSBezierPath(rect:CGRect(x:0,y:0,width:1512,height:1192)).fill()
    for (i,slide) in slides.enumerated() {
        let image = NSImage(contentsOf:output.appendingPathComponent(slide.slug+".png"))!
        let w:CGFloat = 242
        image.draw(in:CGRect(x:CGFloat(i)*252+5,y:30,width:w,height:w*2736/1260),from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:nil)
    }
    text("Dice Workshop · App Store screenshots",32,630,1400,90,size:45,weight:.bold)
    text("6 English screenshots · 1260 × 2736 px · Upload in numbered order",32,707,1400,60,size:27)
}
save(overview,root.appendingPathComponent("overview.png"))
print("Rendered 6 screenshots and overview.")
