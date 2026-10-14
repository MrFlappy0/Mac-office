import AppKit
import ObjectiveC
import PaperCore

/// Document Paper : contenu riche NSAttributedString, lecture et écriture
/// selon l'extension choisie dans le panneau d'enregistrement
/// (par défaut : Word .docx).
@objc(PaperDocument)
final class PaperDocument: NSDocument {

    var content: NSAttributedString
    weak var editor: EditorViewController?

    override init() {
        content = NSAttributedString(string: "\n", attributes: AppSettings.defaultAttributes())
        super.init()
        fileType = Formats.docx.identifier
        printInfo.paperSize = NSSize(width: 595.28, height: 841.89)
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
    }

    // MARK: - Fenêtre

    override var windowNibName: NSNib.Name? { nil }

    override func makeWindowControllers() {
        let editor = EditorViewController()
        editor.document = self
        let window = NSWindow(contentViewController: editor)
        window.styleMask.insert(.resizable)
        window.setContentSize(NSSize(width: 1060, height: 760))
        window.toolbar = EditorToolbar.build(for: self)
        let controller = NSWindowController(window: window)
        addWindowController(controller)
        self.editor = editor
        editor.reload()
    }

    // MARK: - Types

    override class var readableTypes: [String] { Formats.readable.map { $0.identifier } }
    override class var writableTypes: [String] { Formats.writable.map { $0.identifier } }

    // MARK: - Lecture / écriture

    override func read(from url: URL, ofType typeName: String) throws {
        content = try Formats.read(url: url)
        editor?.reload()
        AppSettings.recordRecent(url)
    }

    override func save(to url: URL, ofType typeName: String,
                      for saveOperation: NSDocument.SaveOperationType,
                      completionHandler: @escaping (Error?) -> Void) {
        super.save(to: url, ofType: typeName, for: saveOperation) { error in
            if error == nil {
                AppSettings.recordRecent(url)
            }
            completionHandler(error)
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        if let editor = editor {
            content = editor.attributedContent()
        }
        return try Formats.write(content, typeIdentifier: typeName)
    }

    // MARK: - Impression

    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any] = [:])
        throws -> NSPrintOperation {
        let info = printInfo.copy() as! NSPrintInfo
        info.dictionary().addEntries(from: printSettings)
        guard let textView = editor?.textView else {
            return NSPrintOperation()
        }
        return NSPrintOperation(view: textView, printInfo: info)
    }

    /// Interligne demandé par le menu Format.
    func applyLineHeight(_ multiple: CGFloat) {
        if let textView = editor?.textView {
            TextStyles.setLineHeight(textView, multiple: multiple)
            updateChangeCount(.changeDone)
        }
    }

    // MARK: - Zoom

    @objc func zoomIn(_ sender: Any?) { editor?.zoom(by: 0.15) }
    @objc func zoomOut(_ sender: Any?) { editor?.zoom(by: -0.15) }
    @objc func zoomReset(_ sender: Any?) { editor?.zoom(to: 1) }

    // MARK: - Export PDF

    @objc func exportPDF(_ sender: Any?) {
        guard let textView = editor?.textView, let storage = textView.textStorage else { return }
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = (displayName ?? "Document") + ".pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let pageRect = NSRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let margin: CGFloat = 56.7
        let contentSize = NSSize(width: pageRect.width - margin * 2,
                                 height: pageRect.height - margin * 2)

        let container = NSTextContainer(size: contentSize)
        container.widthTracksTextView = false
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(container)
        layoutManager.replaceTextStorage(storage)

        let data = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }

        let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        let total = storage.length
        let fullGlyphs = layoutManager.glyphRange(
            forCharacterRange: NSRange(location: 0, length: total), actualCharacterRange: nil)
        let bounds = layoutManager.boundingRect(forGlyphRange: fullGlyphs, in: container)
        let pageCount = max(1, Int(ceil(bounds.height / contentSize.height)))

        for pageIndex in 0..<pageCount {
            pdfContext.beginPDFPage(nil)
            pdfContext.saveGState()
            pdfContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            pdfContext.fill(pageRect)
            pdfContext.clip(to: CGRect(origin: .zero, size: contentSize))
            pdfContext.translateBy(x: 0, y: -CGFloat(pageIndex) * contentSize.height)
            layoutManager.drawGlyphs(
                forGlyphRange: fullGlyphs,
                at: NSPoint(x: margin, y: margin))
            pdfContext.restoreGState()
            pdfContext.endPDFPage()
        }

        NSGraphicsContext.current = nil
        NSGraphicsContext.restoreGraphicsState()
        pdfContext.closePDF()

        do {
            try data.write(to: url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export impossible"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}

/// Ruban de fenêtre : actions de mise en forme courantes,
/// adressées à la zone de texte via la chaîne de répondeurs.
final class EditorToolbar: NSObject, NSToolbarDelegate {

    struct Spec {
        let symbol: String
        let label: String
        let action: Selector
    }

    static let specs: [(id: NSToolbarItem.Identifier, spec: Spec?)] = [
        (.init("save"), Spec(symbol: "square.and.arrow.down", label: "Enregistrer",
                             action: Selector("saveDocument:"))),
        (.space, nil),
        (.init("body"), Spec(symbol: "textformat", label: "Corps",
                             action: Selector("makeBody:"))),
        (.init("h1"), Spec(symbol: "textformat.size", label: "Titre 1",
                           action: Selector("makeHeading1:"))),
        (.init("h2"), Spec(symbol: "textformat.size.smaller", label: "Titre 2",
                           action: Selector("makeHeading2:"))),
        (.space, nil),
        (.init("bold"), Spec(symbol: "bold", label: "Gras",
                             action: Selector("toggleBoldFace:"))),
        (.init("italic"), Spec(symbol: "italic", label: "Italique",
                               action: Selector("toggleItalicFace:"))),
        (.init("underline"), Spec(symbol: "underline", label: "Souligné",
                                  action: Selector("toggleUnderline:"))),
        (.init("strike"), Spec(symbol: "strikethrough", label: "Barré",
                               action: Selector("toggleStrikethrough:"))),
        (.space, nil),
        (.init("color"), nil),
        (.space, nil),
        (.init("alignLeft"), Spec(symbol: "text.alignleft", label: "Gauche",
                                  action: Selector("alignLeft:"))),
        (.init("alignCenter"), Spec(symbol: "text.aligncenter", label: "Centrer",
                                    action: Selector("alignCenter:"))),
        (.init("alignRight"), Spec(symbol: "text.alignright", label: "Droite",
                                   action: Selector("alignRight:"))),
        (.init("justify"), Spec(symbol: "text.justify", label: "Justifier",
                                action: Selector("alignJustified:"))),
        (.space, nil),
        (.init("bullet"), Spec(symbol: "list.bullet", label: "Liste à puces",
                               action: Selector("toggleBulletList:"))),
        (.init("numbered"), Spec(symbol: "list.number", label: "Liste numérotée",
                                 action: Selector("toggleNumberedList:"))),
        (.space, nil),
        (.init("image"), Spec(symbol: "photo", label: "Image",
                              action: Selector("insertImage:"))),
        (.init("link"), Spec(symbol: "link", label: "Lien",
                             action: Selector("insertLinkMenu:"))),
        (.init("symbols"), Spec(symbol: "character.textbox", label: "Symboles",
                               action: Selector("insertSymbols:"))),
        (.init("cover"), Spec(symbol: "doc.badge.plus", label: "Page de garde",
                              action: Selector("insertCover:"))),
        (.init("outline"), Spec(symbol: "sidebar.leading", label: "Plan",
                                action: Selector("toggleOutline:"))),
    ]

    static func build(for document: PaperDocument) -> NSToolbar {
        let toolbar = NSToolbar(identifier: "PaperToolbar")
        let delegate = EditorToolbar()
        toolbar.delegate = delegate
        objc_setAssociatedObject(toolbar, &AssociateKey.retain,
                                 delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        return toolbar
    }

    private enum AssociateKey {
        nonisolated(unsafe) static var retain = 0
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return EditorToolbar.specs.map { $0.id }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return EditorToolbar.specs.map { $0.id }
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSUserInterfaceItemIdentifier,
                 willBeInsertedInto flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == NSToolbarItem.Identifier.space.rawValue { return nil }
        guard let entry = EditorToolbar.specs.first(where: { $0.id.rawValue == itemIdentifier.rawValue }) else {
            return nil
        }

        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(itemIdentifier.rawValue))
        if itemIdentifier.rawValue == "color" {
            item.label = "Couleur"
            let well = NSColorWell(frame: NSRect(x: 0, y: 0, width: 36, height: 24))
            well.color = .black
            well.action = #selector(PaperDocument.applyToolbarColor(_:))
            item.view = well
            return item
        }
        guard let spec = entry.spec else { return item }
        item.label = spec.label
        item.paletteLabel = spec.label
        item.image = NSImage(systemSymbolName: spec.symbol, accessibilityDescription: spec.label)
        item.action = spec.action
        item.autovalidates = true
        return item
    }
}

extension PaperDocument {
    @objc func applyToolbarColor(_ sender: NSColorWell) {
        if let textView = editor?.textView {
            let color = sender.color
            let range = textView.selectedRange
            if range.length > 0 {
                textView.setTextColor(color, range: range)
                textView.didChangeText()
            } else {
                textView.typingAttributes[.foregroundColor] = color
            }
            updateChangeCount(.changeDone)
        }
    }
}
