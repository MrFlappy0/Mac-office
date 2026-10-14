// Génère l'icône Paper (icon_1024.png) avec CoreGraphics/CoreText.
// Compatible avec les environnements sans serveur d'affichage (CI macOS).
// Écrit icon_1024.png dans le répertoire courant ; build.sh produit ensuite
// le .icns avec sips + iconutil.

import Foundation
import CoreGraphics
import CoreText
import ImageIO

let size = 1024

guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Impossible de créer le contexte CoreGraphics")
}

// Carré arrondi avec dégradé bleu
let rect = CGRect(x: 32, y: 32, width: size - 64, height: size - 64)
let path = CGPath(
    roundedRect: rect,
    cornerWidth: 210,
    cornerHeight: 210,
    transform: nil
)
ctx.addPath(path)
ctx.clip()

let top = CGColor(red: 0.31, green: 0.52, blue: 0.85, alpha: 1)
let bottom = CGColor(red: 0.17, green: 0.34, blue: 0.60, alpha: 1)
let gradient = CGGradient(colorsSpace: nil, colors: [top, bottom] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: 0, y: CGFloat(size)),
    options: []
)

// Lettre P
let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 620, nil)
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let attributes: [CFString: Any] = [
    kCTFontAttributeName: font,
    kCTForegroundColorAttributeName: white,
]
let attributed = CFAttributedStringCreate(nil, "P" as CFString, attributes as CFDictionary)!
let line = CTLineCreateWithAttributedString(attributed)
let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
ctx.textPosition = CGPoint(
    x: (CGFloat(size) - bounds.width) / 2,
    y: (CGFloat(size) - bounds.height) / 2 - 30
)
CTLineDraw(line, ctx)

// Écriture du PNG
let image = ctx.makeImage()!
let url = URL(fileURLWithPath: "icon_1024.png")
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Impossible de créer le fichier PNG")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("icon_1024.png généré")
