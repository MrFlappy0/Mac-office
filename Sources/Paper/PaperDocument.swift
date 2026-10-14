import AppKit
import ObjectiveC
import PaperCore

/// Document Paper : contenu riche NSAttributedString, lecture et écriture
/// selon l'extension choisie dans le panneau d'enregistrement
/// (par défaut : Word .docx).
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

    override func makeWindowControllers() {
        let editor = EditorViewController()
        editor.document = self
        let window = NSWindow(contentViewController: editor)
        window.styleMask.insert(.resizable)
        window.setContentSize(NSSize(width: 1060, height: 760))
        window.toolbar = EditorToolbar.build(for: self)
        window.toolbar?.delegate = nil
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
        (NSToolbarItem.Identifier.separator, nil),
        (.init("body"), Spec(symbol: "textformat", label: "Corps",
                             action: Selector("makeBody:"))),
        (.init("h1"), Spec(symbol: "textformat.size", label: "Titre 1",
                           action: Selector("makeHeading1:"))),
        (.init("h2"), Spec(symbol: "textformat.size.smaller", label: "Titre 2",
                           action: Selector("makeHeading2:"))),
        (NSToolbarItem.Identifier.separator, nil),
        (.init("bold"), Spec(symbol: "bold", label: "Gras",
                             action: Selector("toggleBoldFace:"))),
        (.init("italic"), Spec(symbol: "italic", label: "Italique",
                               action: Selector("toggleItalicFace:"))),
        (.init("underline"), Spec(symbol: "underline", label: "Souligné",
                                  action: Selector("toggleUnderline:"))),
        (.init("strike"), Spec(symbol: "strikethrough", label: "Barré",
                               action: Selector("toggleStrikethrough:"))),
        (NSToolbarItem.Identifier.separator, nil),
        (.init("color"), nil),
        (NSToolbarItem.Identifier.separator, nil),
        (.init("alignLeft"), Spec(symbol: "text.alignleft", label: "Gauche",
                                  action: Selector("alignLeft:"))),
        (.init("alignCenter"), Spec(symbol: "text.aligncenter", label: "Centrer",
                                    action: Selector("alignCenter:"))),
        (.init("alignRight"), Spec(symbol: "text.alignright", label: "Droite",
                                   action: Selector("alignRight:"))),
        (.init("justify"), Spec(symbol: "text.justify", label: "Justifier",
                                action: Selector("alignJustified:"))),
        (NSToolbarItem.Identifier.separator, nil),
        (.init("bullet"), Spec(symbol: "list.bullet", label: "Liste à puces",
                               action: Selector("toggleBulletList:"))),
        (.init("numbered"), Spec(symbol: "list.number", label: "Liste numérotée",
                                 action: Selector("toggleNumberedList:"))),
        (NSToolbarItem.Identifier.separator, nil),
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
        if itemIdentifier.rawValue == NSToolbarItem.Identifier.separator.rawValue { return nil }
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
