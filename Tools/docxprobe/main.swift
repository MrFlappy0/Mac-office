import Foundation
import AppKit
import PaperCore

// Outil de vérification : génère un .docx de test et l'écrit sur disque.
// Utilisation : docxprobe /chemin/vers/sortie.docx

let args = CommandLine.arguments
guard args.count > 1 else {
    print("usage: docxprobe <sortie.docx>")
    exit(1)
}

let body = NSMutableAttributedString(
    string: "Rapport Paper — Été\n",
    attributes: [.font: NSFont.boldSystemFont(ofSize: 24)])

body.append(NSAttributedString(
    string: "Paragraphe normal du document de test.\n",
    attributes: [.font: NSFont(name: "Times New Roman", size: 12) ?? .systemFont(ofSize: 12)]))

let listStyle = NSMutableParagraphStyle()
listStyle.textLists = [NSTextList(markerFormat: NSTextList.MarkerFormat("{•}"), options: 0)]
listStyle.headIndent = 18
body.append(NSAttributedString(
    string: "Élément de liste à puces\n",
    attributes: [.font: NSFont(name: "Times New Roman", size: 12) ?? .systemFont(ofSize: 12),
                 .paragraphStyle: listStyle]))

let centered = NSMutableParagraphStyle()
centered.alignment = .center
body.append(NSAttributedString(
    string: "Paragraphe centré en couleur.\n",
    attributes: [.font: NSFont.systemFont(ofSize: 14),
                 .paragraphStyle: centered,
                 .foregroundColor: NSColor.blue]))

let data = DocxWriter.data(from: body)
let url = URL(fileURLWithPath: args[1])
try data.write(to: url)
print("OK: \(url.path) (\(data.count) octets)")
