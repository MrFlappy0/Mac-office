import AppKit

/// Styles de paragraphe et insertions appliqués au NSTextView de l'éditeur.
public enum TextStyles {

    public static let bodySize: CGFloat = 12
    public static let headingSizes: [CGFloat] = [24, 20, 16]
    public static let bulletMarker = "{•}"
    public static let decimalMarker = "{decimal}"

    // MARK: - Titres

    public static func applyHeading(_ textView: NSTextView, level: Int) {
        guard level >= 1, level <= 3 else { return }
        let size = headingSizes[level - 1]
        let bold = NSFontManager.shared.convert(currentFont(textView), toHaveTrait: .boldFontMask)
        let scaled = NSFontManager.shared.convert(bold, toSize: size)
        setTypingAndSelectionAttribute(textView, .font, value: scaled)
    }

    public static func applyBody(_ textView: NSTextView) {
        let scaled = NSFontManager.shared.convert(currentFont(textView), toSize: bodySize)
        setTypingAndSelectionAttribute(textView, .font, value: scaled)
    }

    // MARK: - Listes

    public static func toggleList(_ textView: NSTextView, markerFormat: String) {
        guard let storage = textView.textStorage else { return }
        let range = paragraphRange(textView)
        guard range.length > 0 else { return }
        let attr = storage.attributedSubstring(from: range)
        let working = NSMutableAttributedString(attributedString: attr)

        let alreadyListed: Bool = {
            var listed = true
            for pRange in TextUtils.paragraphRanges(of: working.string, length: working.length) {
                let pStyle = working.attribute(.paragraphStyle, at: pRange.location,
                    effectiveRange: nil) as? NSParagraphStyle
                let lists = pStyle?.textLists ?? []
                if !lists.contains(where: { $0.markerFormat.rawValue == markerFormat }) {
                    listed = false
                }
            }
            return listed
        }()

        for pRange in TextUtils.paragraphRanges(of: working.string, length: working.length) {
            let style = working.attribute(.paragraphStyle, at: pRange.location,
                effectiveRange: nil) as? NSParagraphStyle
            let mutable = (style ?? NSParagraphStyle.default).mutableCopy()
                as! NSMutableParagraphStyle
            if alreadyListed {
                mutable.textLists = []
                mutable.firstLineHeadIndent = max(0, mutable.firstLineHeadIndent - 18)
                mutable.headIndent = max(0, mutable.headIndent - 18)
            } else {
                let list = NSTextList(markerFormat: NSTextList.MarkerFormat(rawValue: markerFormat),
                                      options: 0)
                mutable.textLists = (style?.textLists ?? []) + [list]
                mutable.firstLineHeadIndent = 0
                mutable.headIndent = 18
            }
            working.addAttribute(.paragraphStyle, value: mutable, range: pRange)
        }

        working.fixAttributes(in: NSRange(location: 0, length: working.length))
        storage.beginEditing()
        storage.replaceCharacters(in: range, with: working)
        storage.endEditing()
        textView.didChangeText()
    }

    // MARK: - Interligne

    public static func setLineHeight(_ textView: NSTextView, multiple: CGFloat) {
        applyToParagraphStyles(textView) { style in
            style.lineHeightMultiple = multiple
        }
        textView.didChangeText()
    }

    // MARK: - Insertions

    public static func insertDate(_ textView: NSTextView) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM y"
        let text = NSAttributedString(string: formatter.string(from: Date()) + " ",
                                       attributes: textView.typingAttributes)
        textView.insertText(text)
    }

    public static func insertLink(_ textView: NSTextView, url: URL, label: String?) {
        let text = label ?? url.absoluteString
        let attr = NSAttributedString(
            string: text,
            attributes: [.link: url, .foregroundColor: NSColor.systemBlue])
        if textView.selectedRange.length > 0 {
            textView.textStorage?.setAttributes(
                [.link: url, .foregroundColor: NSColor.systemBlue,
                 .underlineStyle: NSUnderlineStyle.single.rawValue],
                range: textView.selectedRange)
            textView.didChangeText()
        } else {
            textView.insertText(attr)
        }
    }

    public static func insertImage(_ textView: NSTextView, url: URL) {
        guard var image = NSImage(contentsOf: url) else { return }
        let maxWidth: CGFloat = 460
        if image.size.width > maxWidth, image.size.width > 0 {
            let ratio = maxWidth / image.size.width
            let resized = NSImage(size: NSSize(width: image.size.width * ratio,
                                                height: image.size.height * ratio))
            resized.lockFocus()
            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(in: NSRect(origin: .zero, size: resized.size))
            resized.unlockFocus()
            image = resized
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        textView.insertText(NSAttributedString(attachment: attachment))
        textView.insertText(NSAttributedString(string: " ",
                                                attributes: textView.typingAttributes))
    }

    public static func insertCover(_ textView: NSTextView, title: String, subtitle: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let bold = NSFontManager.shared.convert(currentFont(textView), toHaveTrait: .boldFontMask)

        textView.insertText(NSAttributedString(string: "\n",
                                                attributes: textView.typingAttributes))
        textView.insertText(NSAttributedString(
            string: title,
            attributes: [.font: NSFontManager.shared.convert(bold, toSize: 32),
                          .paragraphStyle: paragraph]))
        textView.insertText(NSAttributedString(
            string: "\n\n", attributes: [.paragraphStyle: paragraph]))
        if !subtitle.isEmpty {
            textView.insertText(NSAttributedString(
                string: subtitle,
                attributes: [.font: NSFontManager.shared.convert(currentFont(textView), toSize: 16),
                             .foregroundColor: NSColor.gray,
                             .paragraphStyle: paragraph]))
            textView.insertText(NSAttributedString(
                string: "\n\n", attributes: [.paragraphStyle: paragraph]))
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM y"
        textView.insertText(NSAttributedString(
            string: formatter.string(from: Date()),
            attributes: [.font: currentFont(textView),
                         .foregroundColor: NSColor.gray,
                         .paragraphStyle: paragraph]))
        textView.insertText(NSAttributedString(
            string: "\n\n", attributes: [.paragraphStyle: paragraph]))
    }

    // MARK: - Outils privés

    private static func currentFont(_ textView: NSTextView) -> NSFont {
        let range = textView.selectedRange
        if range.length > 0, range.location < textView.attributedString().length,
           let font = textView.attributedString().attribute(
               .font, at: range.location, effectiveRange: nil) as? NSFont {
            return font
        }
        if let font = textView.typingAttributes[.font] as? NSFont {
            return font
        }
        return NSFont.systemFont(ofSize: bodySize)
    }

    private static func setTypingAndSelectionAttribute(_ textView: NSTextView,
                                                       _ key: NSAttributedString.Key,
                                                       value: Any) {
        var typing = textView.typingAttributes
        typing[key] = value
        textView.typingAttributes = typing
        if textView.selectedRange.length > 0 {
            textView.textStorage?.addAttribute(key, value: value,
                                               range: textView.selectedRange)
            textView.didChangeText()
        }
    }

    private static func applyToParagraphStyles(_ textView: NSTextView,
                                              _ change: (NSMutableParagraphStyle) -> Void) {
        guard let storage = textView.textStorage else { return }
        let range = paragraphRange(textView)
        guard range.length > 0 else { return }
        let attr = storage.attributedSubstring(from: range)
        let working = NSMutableAttributedString(attributedString: attr)
        for pRange in TextUtils.paragraphRanges(of: working.string, length: working.length) {
            let style = working.attribute(.paragraphStyle, at: pRange.location,
                effectiveRange: nil) as? NSParagraphStyle
            let mutable = (style ?? NSParagraphStyle.default).mutableCopy()
                as! NSMutableParagraphStyle
            change(mutable)
            working.addAttribute(.paragraphStyle, value: mutable, range: pRange)
        }
        storage.beginEditing()
        storage.replaceCharacters(in: range, with: working)
        storage.endEditing()
    }

    private static func paragraphRange(_ textView: NSTextView) -> NSRange {
        let sel = textView.selectedRange
        let length = textView.textStorage?.length ?? 0
        guard sel.location != NSNotFound, sel.location < length else {
            return NSRange(location: 0, length: 0)
        }
        let nsText = textView.string as NSString
        let firstLine = nsText.lineRange(for: NSRange(location: sel.location, length: 0))
        let last = sel.length > 0 ? sel.location + sel.length - 1 : sel.location
        let lastLine = nsText.lineRange(for: NSRange(location: last, length: 0))
        return NSRange(location: firstLine.location,
                       length: NSMaxRange(lastLine) - firstLine.location)
    }
}
