import AppKit

// Draws a simple timer app icon and writes icon_1024.png next to this script.
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Rounded-square backdrop with an orange gradient.
let margin: CGFloat = 80
let rect = CGRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)
let corner = (size - 2 * margin) * 0.225
let bg = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
ctx.saveGState()
ctx.addPath(bg)
ctx.clip()
let colors = [
    NSColor(srgbRed: 1.00, green: 0.64, blue: 0.18, alpha: 1).cgColor,
    NSColor(srgbRed: 0.96, green: 0.42, blue: 0.16, alpha: 1).cgColor,
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
ctx.restoreGState()

// White timer ring with a small gap at the top.
let center = CGPoint(x: size / 2, y: size / 2)
let radius: CGFloat = 300
ctx.setStrokeColor(NSColor.white.cgColor)
ctx.setLineWidth(74)
ctx.setLineCap(.round)
ctx.addArc(center: center, radius: radius,
           startAngle: .pi / 2 + 0.45,
           endAngle: .pi / 2 - 0.45 + 2 * .pi,
           clockwise: false)
ctx.strokePath()

// Two clock hands.
ctx.setLineWidth(48)
ctx.move(to: center); ctx.addLine(to: CGPoint(x: center.x, y: center.y + 180)); ctx.strokePath()
ctx.move(to: center); ctx.addLine(to: CGPoint(x: center.x + 130, y: center.y + 36)); ctx.strokePath()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("icon render failed\n".data(using: .utf8)!)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: "icon_1024.png"))
print("wrote icon_1024.png")
