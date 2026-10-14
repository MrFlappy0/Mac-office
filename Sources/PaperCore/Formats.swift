import AppKit
import UniformTypeIdentifiers

/// Formats de documents acceptés par Paper et conversion vers/depuis
/// NSAttributedString. L'extension est choisie dans le panneau d'enregistrement,
/// la valeur par défaut est le format Word (.docx).
public enum Formats {

    public static let docx = UTType(filenameExtension: "docx") ?? .data
    public static let doc = UTType(filenameExtension: "doc") ?? .data
    public static let rtf = UTType.rtf
    public static let html = UTType.html
    public static let txt = UTType.plainText

    public static var readable: [UTType] { [docx, doc, rtf, html, txt] }
    public static var writable: [UTType] { [docx, doc, rtf, html, txt] }

    // MARK: - Lecture

    public static func read(url: URL) throws -> NSAttributedString {
        let ext = url.pathExtension.lowercased()
        let data = try Data(contentsOf: url)

        switch ext {
        case "docx":
            if let attr = openDocx(url: url) { return attr }
            throw PaperError.conversionDocx
        case "doc":
            if let attr = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.docFormat],
                documentAttributes: nil) {
                return attr
            }
            return try readHtml(data: data)
        case "rtf":
            guard let attr = NSAttributedString(rtf: data, documentAttributes: nil) else {
                throw PaperError.lecture
            }
            return attr
        case "html", "htm":
            return try readHtml(data: data)
        default:
            let text = String(data: data, encoding: .utf8)
                ?? String(decoding: data, as: UTF8.self)
            return NSAttributedString(string: text)
        }
    }

    private static func readHtml(data: Data) throws -> NSAttributedString {
        let s = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        let normalized = s.data(using: .utf8) ?? data
        return try NSAttributedString(
            data: normalized,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)
    }

    /// Les .docx ne sont pas lisibles par NSAttributedString sur macOS :
    /// conversion via textutil (outil natif du système).
    private static func openDocx(url: URL) -> NSAttributedString? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("paper-\(UUID().uuidString).rtf")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", "rtf", "-output", tmp.path, url.path]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        defer { try? FileManager.default.removeItem(at: tmp) }
        guard process.terminationStatus == 0 else { return nil }
        let data = (try? Data(contentsOf: tmp)) ?? Data()
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }

    // MARK: - Écriture

    public static func write(_ attr: NSAttributedString, typeIdentifier: String) throws -> Data {
        switch typeIdentifier {
        case docx.identifier:
            return DocxWriter.data(from: attr)
        case doc.identifier:
            if let data = try? attr.data(
                from: NSRange(location: 0, length: attr.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.docFormat]) {
                return data
            }
            // Repli : .doc au contenu HTML, ouvrable par Word et Pages
            return try htmlData(attr, docFlavour: true)
        case rtf.identifier:
            return try attr.data(
                from: NSRange(location: 0, length: attr.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        case html.identifier:
            return try htmlData(attr, docFlavour: false)
        case txt.identifier:
            return Data(attr.string.utf8)
        default:
            throw PaperError.formatInconnu(typeIdentifier)
        }
    }

    private static func htmlData(_ attr: NSAttributedString, docFlavour: Bool) throws -> Data {
        var options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if docFlavour {
            options[.textEncodingName] = "UTF-8"
        }
        var data = try attr.data(
            from: NSRange(location: 0, length: attr.length),
            documentAttributes: options)
        if docFlavour {
            // Motif compatible Word : HTML dans un conteneur .doc
            let header = Data("<html xmlns:o=\"urn:schemas-microsoft-com:office:office\" xmlns:w=\"urn:schemas-microsoft-com:office:word\"><head><meta charset=\"utf-8\"></head><body>".utf8)
            let footer = Data("</body></html>".utf8)
            var full = header
            full.append(stripFullHtmlTags(data))
            full.append(footer)
            data = full
        }
        return data
    }

    /// Retire l'enveloppe <html><head>…</head> pour ne garder que le corps.
    private static func stripFullHtmlTags(_ data: Data) -> Data {
        guard let s = String(data: data, encoding: .utf8) else { return data }
        guard let bodyRange = s.range(of: "<body>", options: .caseInsensitive),
              let endRange = s.range(of: "</body>", options: .caseInsensitive) else {
            return data
        }
        return Data(s[bodyRange.upperBound..<endRange.lowerBound].utf8)
    }
}

public enum PaperError: LocalizedError {
    case lecture
    case conversionDocx
    case formatInconnu(String)

    public var errorDescription: String? {
        switch self {
        case .lecture:
            return "Ce document ne peut pas être lu. Formats acceptés : .docx, .doc, .rtf, .html, .txt."
        case .conversionDocx:
            return "La conversion du document .docx a échoué."
        case .formatInconnu(let id):
            return "Format non pris en charge : \(id)"
        }
    }
}
