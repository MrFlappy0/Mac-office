import AppKit
import PaperCore

/// Zone de texte riche : commandes de mise en forme adressées par la barre
/// de menus et le ruban (target nil -> chaine de répondeurs).
final class EditorTextView: NSTextView {

    var onOutlineToggle: (() -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    // MARK: - Styles

    @objc func makeHeading1(_ sender: Any?) { TextStyles.applyHeading(self, level: 1); touch() }
    @objc func makeHeading2(_ sender: Any?) { TextStyles.applyHeading(self, level: 2); touch() }
    @objc func makeHeading3(_ sender: Any?) { TextStyles.applyHeading(self, level: 3); touch() }
    @objc func makeBody(_ sender: Any?) { TextStyles.applyBody(self); touch() }

    // MARK: - Souligné et barré

    @objc func toggleUnderline(_ sender: Any?) {
        let active = attrInt(.underlineStyle, at: selectionStart) != 0
        let value: Int = active ? 0 : NSUnderlineStyle.single.rawValue
        setStyleValue(.underlineStyle, value: value)
        touch()
    }

    @objc func toggleStrikethrough(_ sender: Any?) {
        let active = attrInt(.strikethroughStyle, at: selectionStart) != 0
        let value: Int = active ? 0 : NSUnderlineStyle.single.rawValue
        setStyleValue(.strikethroughStyle, value: value)
        touch()
    }

    // MARK: - Listes et interligne

    @objc func toggleBulletList(_ sender: Any?) {
        TextStyles.toggleList(self, markerFormat: TextStyles.bulletMarker)
        touch()
    }

    @objc func toggleNumberedList(_ sender: Any?) {
        TextStyles.toggleList(self, markerFormat: TextStyles.decimalMarker)
        touch()
    }

    @objc func setLineHeight(_ sender: Any?) {
        let multiple: CGFloat
        if let item = sender as? NSMenuItem, let value = item.representedObject as? Double {
            multiple = value
        } else {
            multiple = 1.45
        }
        TextStyles.setLineHeight(self, multiple: multiple)
        touch()
    }

    // MARK: - Insertions

    @objc func insertImage(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        TextStyles.insertImage(self, url: url)
        touch()
    }

    @objc func insertLinkMenu(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Adresse du lien :"
        alert.addButton(withTitle: "Insérer")
        alert.addButton(withTitle: "Annuler")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = "https://"
        alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn,
              let url = URL(string: field.stringValue), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return }
        let label = selectedRange.length > 0
            ? (string as NSString).substring(with: selectedRange)
            : nil
        TextStyles.insertLink(self, url: url, label: label)
        touch()
    }

    @objc func insertDate(_ sender: Any?) {
        TextStyles.insertDate(self)
        touch()
    }

    @objc func insertCover(_ sender: Any?) {
        let title = prompt("Titre du document :", default: "") ?? ""
        guard !title.isEmpty else { return }
        let subtitle = prompt("Sous-titre (vide pour ignorer) :", default: "") ?? ""
        TextStyles.insertCover(self, title: title, subtitle: subtitle)
        touch()
    }

    @objc func insertSymbols(_ sender: Any?) {
        SymbolsPanel.shared.show { [weak self] character in
            guard let self = self else { return }
            self.insertText(NSAttributedString(string: character,
                                                attributes: self.typingAttributes))
            self.touch()
        }
    }

    // MARK: - Affichage

    @objc func toggleOutline(_ sender: Any?) {
        onOutlineToggle?()
    }

    // MARK: - Outils privés

    private var selectionStart: Int {
        let length = textStorage?.length ?? 0
        return max(0, min(selectedRange.location, max(0, length - 1)))
    }

    private func attrInt(_ key: NSAttributedString.Key, at location: Int) -> Int {
        guard let storage = textStorage, storage.length > 0 else { return 0 }
        let value = storage.attribute(key, at: location, effectiveRange: nil)
        return (value as? Int) ?? 0
    }

    private func setStyleValue(_ key: NSAttributedString.Key, value: Int) {
        var typing = typingAttributes
        typing[key] = value
        typingAttributes = typing
        if selectedRange.length > 0, let storage = textStorage {
            if value == 0 {
                storage.removeAttribute(key, range: selectedRange)
            } else {
                storage.addAttribute(key, value: value, range: selectedRange)
            }
        }
    }

    private func prompt(_ text: String, default defaultValue: String) -> String? {
        let alert = NSAlert()
        alert.messageText = text
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Annuler")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = defaultValue
        alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }

    private func touch() {
        didChangeText()
    }
}
