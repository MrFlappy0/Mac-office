// Génère icon_1024.png dans le répertoire courant : icône Paper (P bleu dégradé).
// Utilisé par build.sh pour produire Paper.icns.
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.31, green: 0.52, blue: 0.85, alpha: 1),
    NSColor(calibratedRed: 0.17, green: 0.34, blue: 0.60, alpha: 1)
])!
let path = NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 960, height: 960), xRadius: 210, yRadius: 210)
gradient.draw(in: path, angle: -90)

let para = NSMutableParagraphStyle()
para.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 600),
    .foregroundColor: NSColor.white,
    .paragraphStyle: para
]
let text = NSAttributedString(string: "P", attributes: attrs)
let bounds = text.boundingRect(with: NSSize(width: size, height: size), options: [.usesLineFragmentOrigin])
text.draw(in: NSRect(x: 0, y: (size - bounds.height) / 2 + 14, width: size, height: bounds.height))

img.unlockFocus()

let tiff = img.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "icon_1024.png"))
print("icon_1024.png généré")
