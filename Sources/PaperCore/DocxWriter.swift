import AppKit

/// Génération de documents Office Open XML (.docx) à partir d'NSAttributedString.
/// Conteneur ZIP écrit à la main (voir Zip.swift), parties OOXML minimales
/// mais complètes : document, styles, numérotation, relations.
public enum DocxWriter {

    public static func data(from attr: NSAttributedString) -> Data {
        var hyperlinks: [(id: String, target: String)] = []
        var linkCounter = 2
        let body = bodyXml(from: attr, hyperlinks: &hyperlinks, linkCounter: &linkCounter)

        let documentXml = xmlHeader
            + "<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\""
            + " xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">"
            + "<w:body>" + body + sectPr + "</w:body></w:document>"

        var docRels = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
            + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
            + "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"
            + "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering\" Target=\"numbering.xml\"/>"
        for link in hyperlinks {
            docRels += "<Relationship Id=\"\(link.id)\""
                + " Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink\""
                + " Target=\"\(escape(link.target))\" TargetMode=\"External\"/>"
        }
        docRels += "</Relationships>"

        let files: [(name: String, data: [UInt8])] = [
            ("[Content_Types].xml", Array(contentTypes.utf8)),
            ("_rels/.rels", Array(rootRels.utf8)),
            ("word/document.xml", Array(documentXml.utf8)),
            ("word/styles.xml", Array(styles.utf8)),
            ("word/numbering.xml", Array(numbering.utf8)),
            ("word/_rels/document.xml.rels", Array(docRels.utf8)),
        ]
        return Zip.build(files)
    }

    // MARK: - Corps du document

    private static var xmlHeader: String {
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
    }

    private static var sectPr: String {
        "<w:sectPr><w:pgSz w:w=\"11906\" w:h=\"16838\"/>"
            + "<w:pgMar w:top=\"1417\" w:right=\"1417\" w:bottom=\"1417\" w:left=\"1417\""
            + " w:header=\"708\" w:footer=\"708\" w:gutter=\"0\"/></w:sectPr>"
    }

    private static func bodyXml(from attr: NSAttributedString,
                                hyperlinks: inout [(id: String, target: String)],
                                linkCounter: inout Int) -> String {
        let full = NSRange(location: 0, length: attr.length)
        if attr.length == 0 {
            return "<w:p/>"
        }
        var out = ""
        for range in TextUtils.paragraphRanges(of: attr.string, length: attr.length) {
            out += paragraphXml(attr, range: range, hyperlinks: &hyperlinks, linkCounter: &linkCounter)
        }
        return out
    }

    private static func paragraphXml(_ attr: NSAttributedString,
                                    range: NSRange,
                                    hyperlinks: inout [(id: String, target: String)],
                                    linkCounter: inout Int) -> String {
        let para = attr.attributedSubstring(from: range)
        var ppr = ""
        var body = ""

        if range.length > 0, para.length > 0 {
            let pstyle = para.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            let font = para.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
            let size = font?.pointSize ?? 12

            if size >= 22 {
                ppr += "<w:pStyle w:val=\"Heading1\"/>"
            } else if size >= 18 {
                ppr += "<w:pStyle w:val=\"Heading2\"/>"
            } else if size >= 15 {
                ppr += "<w:pStyle w:val=\"Heading3\"/>"
            }

            if let lists = pstyle?.textLists, !lists.isEmpty {
                let isDecimal = lists.last?.markerFormat.rawValue.contains("decimal") ?? false
                let numId = isDecimal ? 2 : 1
                let ilvl = min(lists.count - 1, 5)
                ppr += "<w:numPr><w:ilvl w:val=\"\(ilvl)\"/><w:numId w:val=\"\(numId)\"/></w:numPr>"
            }

            switch pstyle?.alignment {
            case .center: ppr += "<w:jc w:val=\"center\"/>"
            case .right: ppr += "<w:jc w:val=\"right\"/>"
            case .justified: ppr += "<w:jc w:val=\"both\"/>"
            default: break
            }
        }

        para.enumerateAttributes(in: NSRange(location: 0, length: para.length)) { dict, sub, _ in
            let text = (para.string as NSString).substring(with: sub)
            let runText = text.replacingOccurrences(of: "\n", with: "")
            if runText.isEmpty { return }
            if let linkValue = dict[.link] {
                let href: String
                if let url = linkValue as? URL { href = url.absoluteString }
                else if let s = linkValue as? String { href = s }
                else { href = "" }
                if !href.isEmpty {
                    linkCounter += 1
                    let rid = "rId\(linkCounter)"
                    hyperlinks.append((rid, href))
                    body += "<w:hyperlink r:id=\"\(rid)\">"
                        + runXml(text: runText, attrs: dict)
                        + "</w:hyperlink>"
                    return
                }
            }
            body += runXml(text: runText, attrs: dict)
        }

        if body.isEmpty { body = "<w:r><w:t xml:space=\"preserve\"> </w:t></w:r>" }
        return "<w:p>" + (ppr.isEmpty ? "" : "<w:pPr>\(ppr)</w:pPr>") + body + "</w:p>"
    }

    private static func runXml(text: String, attrs: [NSAttributedString.Key: Any]) -> String {
        var rpr = ""
        let font = attrs[.font] as? NSFont
        if let font = font {
            let name = font.fontName
            if name != "Times New Roman" {
                rpr += "<w:rFonts w:ascii=\"\(escape(font.familyName ?? name))\""
                    + " w:hAnsi=\"\(escape(font.familyName ?? name))\"/>"
            }
            let traits = NSFontManager.shared.traits(of: font)
            if traits.contains(.boldFontMask) { rpr += "<w:b/>" }
            if traits.contains(.italicFontMask) { rpr += "<w:i/>" }
            let halfPt = Int(font.pointSize * 2)
            rpr += "<w:sz w:val=\"\(halfPt)\"/><w:szCs w:val=\"\(halfPt)\"/>"
        }
        if let style = attrs[.underlineStyle] as? Int, style != 0 {
            rpr += "<w:u w:val=\"single\"/>"
        }
        if let style = attrs[.strikethroughStyle] as? Int, style != 0 {
            rpr += "<w:strike/>"
        }
        if let color = attrs[.foregroundColor] as? NSColor, let hex = hex(color) {
            rpr += "<w:color w:val=\"\(hex)\"/>"
        }
        if let bg = attrs[.backgroundColor] as? NSColor, let hex = hex(bg) {
            rpr += "<w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"\(hex)\"/>"
        }
        if let sup = attrs[.superscript] as? Int {
            if sup > 0 { rpr += "<w:vertAlign w:val=\"superscript\"/>" }
            else if sup < 0 { rpr += "<w:vertAlign w:val=\"subscript\"/>" }
        }
        return "<w:r>" + (rpr.isEmpty ? "" : "<w:rPr>\(rpr)</w:rPr>")
            + "<w:t xml:space=\"preserve\">\(escape(text))</w:t></w:r>"
    }

    private static func hex(_ color: NSColor) -> String? {
        guard let c = color.usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(round(c.redComponent * 255))
        let g = Int(round(c.greenComponent * 255))
        let b = Int(round(c.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - Parties OOXML

    private static var contentTypes: String {
        xmlHeader
            + "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
            + "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
            + "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
            + "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>"
            + "<Override PartName=\"/word/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\"/>"
            + "<Override PartName=\"/word/numbering.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml\"/>"
            + "</Types>"
    }

    private static var rootRels: String {
        xmlHeader
            + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
            + "<Relationship Id=\"rId1\""
            + " Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\""
            + " Target=\"word/document.xml\"/></Relationships>"
    }

    private static var styles: String {
        xmlHeader
            + "<w:styles xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">"
            + "<w:docDefaults><w:rPrDefault><w:rPr>"
            + "<w:rFonts w:ascii=\"Times New Roman\" w:hAnsi=\"Times New Roman\"/>"
            + "<w:sz w:val=\"24\"/><w:szCs w:val=\"24\"/></w:rPr></w:rPrDefault></w:docDefaults>"
            + "<w:style w:type=\"paragraph\" w:default=\"1\" w:styleId=\"Normal\"><w:name w:val=\"Normal\"/></w:style>"
            + "<w:style w:type=\"paragraph\" w:styleId=\"Heading1\"><w:name w:val=\"heading 1\"/><w:basedOn w:val=\"Normal\"/>"
            + "<w:pPr><w:keepNext/><w:spacing w:before=\"240\" w:after=\"120\"/></w:pPr>"
            + "<w:rPr><w:b/><w:color w:val=\"1D1D1F\"/><w:sz w:val=\"48\"/><w:szCs w:val=\"48\"/></w:rPr></w:style>"
            + "<w:style w:type=\"paragraph\" w:styleId=\"Heading2\"><w:name w:val=\"heading 2\"/><w:basedOn w:val=\"Normal\"/>"
            + "<w:pPr><w:keepNext/><w:spacing w:before=\"200\" w:after=\"100\"/></w:pPr>"
            + "<w:rPr><w:b/><w:color w:val=\"1D1D1F\"/><w:sz w:val=\"40\"/><w:szCs w:val=\"40\"/></w:rPr></w:style>"
            + "<w:style w:type=\"paragraph\" w:styleId=\"Heading3\"><w:name w:val=\"heading 3\"/><w:basedOn w:val=\"Normal\"/>"
            + "<w:pPr><w:keepNext/><w:spacing w:before=\"160\" w:after=\"80\"/></w:pPr>"
            + "<w:rPr><w:b/><w:sz w:val=\"30\"/><w:szCs w:val=\"30\"/></w:rPr></w:style>"
            + "</w:styles>"
    }

    private static var numbering: String {
        func level(_ i: Int, format: String, text: String) -> String {
            "<w:lvl w:ilvl=\"\(i)\"><w:start w:val=\"1\"/>"
                + "<w:numFmt w:val=\"\(format)\"/><w:lvlText w:val=\"\(text)\"/>"
                + "<w:lvlJc w:val=\"left\"/>"
                + "<w:pPr><w:ind w:left=\"\((i + 1) * 720)\" w:hanging=\"360\"/></w:pPr></w:lvl>"
        }
        var bullets = ""
        var decimals = ""
        for i in 0..<6 {
            bullets += level(i, format: "bullet", text: "•")
            decimals += level(i, format: "decimal", text: "%\(i + 1).")
        }
        return xmlHeader
            + "<w:numbering xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">"
            + "<w:abstractNum w:abstractNumId=\"0\">\(bullets)</w:abstractNum>"
            + "<w:abstractNum w:abstractNumId=\"1\">\(decimals)</w:abstractNum>"
            + "<w:num w:numId=\"1\"><w:abstractNumId w:val=\"0\"/></w:num>"
            + "<w:num w:numId=\"2\"><w:abstractNumId w:val=\"1\"/></w:num>"
            + "</w:numbering>"
    }
}
