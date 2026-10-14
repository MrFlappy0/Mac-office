import AppKit
import PaperCore

/// Contrôleur principal : éditeur + plan + barre d'état.
final class EditorViewController: NSViewController, NSTextViewDelegate {

    let textView = EditorTextView(frame: .zero)
    private let scrollView = NSScrollView()
    private let statusBar = NSTextField(labelWithString: "")
    private let sidebar = OutlineViewController()
    private var outlineWidth: CGFloat = 232

    weak var document: PaperDocument?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 1060, height: 760))

        // Éditeur
        textView.isRichText = true
        textView.allowsUndo = true
        textView.importsGraphics = true
        textView.allowsImageEditing = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = NSFont(name: AppSettings.fontName, size: AppSettings.fontSize)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.delegate = self
        textView.onOutlineToggle = { [weak self] in self?.setOutlineVisible(!(self?.outlineVisible ?? true)) }

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.autoresizingMask = [.width, .height]

        // Plan
        sidebar.jump = { [weak self] range in
            self?.textView.scrollRangeToVisible(range)
            self?.textView.setSelectedRange(NSRange(location: range.location, length: 0))
        }

        // Barre d'état
        statusBar.font = .systemFont(ofSize: 11)
        statusBar.textColor = .secondaryLabelColor
        statusBar.alignment = .center
        statusBar.backgroundColor = .controlBackgroundColor
        statusBar.isBezeled = false
        statusBar.isEditable = false

        container.addSubview(sidebar.view)
        container.addSubview(scrollView)
        container.addSubview(statusBar)
        view = container

        applySettings()
        layoutViews()
        observeSettings()
    }

    private var outlineVisible = true

    private func layoutViews() {
        let bounds = view.bounds
        statusBar.frame = NSRect(x: 0, y: 0, width: bounds.width, height: 22)
        statusBar.autoresizingMask = [.width, .maxYMargin]

        if outlineVisible {
            sidebar.view.frame = NSRect(x: 0, y: 22, width: outlineWidth,
                                         height: bounds.height - 22)
            sidebar.view.autoresizingMask = [.height]
            scrollView.frame = NSRect(x: outlineWidth, y: 22,
                                      width: bounds.width - outlineWidth,
                                      height: bounds.height - 22)
            scrollView.autoresizingMask = [.width, .height]
        } else {
            sidebar.view.frame = .zero
            scrollView.frame = NSRect(x: 0, y: 22, width: bounds.width,
                                      height: bounds.height - 22)
            scrollView.autoresizingMask = [.width, .height]
        }
    }

    func setOutlineVisible(_ visible: Bool) {
        outlineVisible = visible
        layoutViews()
    }

    // MARK: - Contenu

    func reload() {
        guard let document = document, let storage = textView.textStorage else { return }
        storage.setAttributedString(document.content)
        textView.typingAttributes = AppSettings.defaultAttributes()
        updateStatus()
        refreshOutline()
    }

    func attributedContent() -> NSAttributedString {
        guard let storage = textView.textStorage else {
            return NSAttributedString(string: "")
        }
        return NSAttributedString(attributedString: storage)
    }

    // MARK: - Délégué NSTextView

    func textDidChange(_ notification: Notification) {
        document?.updateChangeCount(.changeDone)
        updateStatus()
        refreshOutline()
    }

    func textDidEndEditing(_ notification: Notification) {
        document?.updateChangeCount(.changeDone)
    }

    // MARK: - Barre d'état et plan

    private func updateStatus() {
        let text = textView.string
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.isEmpty ? 0 : trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let chars = text.count
        var parts = ["\(words) mot\(words > 1 ? "s" : "")",
                     "\(chars) caractère\(chars > 1 ? "s" : "")",
                     "A4 · impression"]
        if words > 150 {
            parts.insert("environ \(Int((Double(words) / 200).rounded(.up))) min de lecture", at: 2)
        }
        statusBar.stringValue = parts.joined(separator: " · ")
    }

    private func refreshOutline() {
        sidebar.refresh(from: attributedContent())
    }

    // MARK: - Réglages

    private func observeSettings() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(settingsChanged),
            name: AppSettings.changedNotification, object: nil)
    }

    @objc private func settingsChanged() {
        applySettings()
    }

    private func applySettings() {
        let margin = AppSettings.margin
        textView.textContainerInset = NSSize(width: margin, height: margin)
        textView.isContinuousSpellCheckingEnabled = AppSettings.spellcheck
        setOutlineVisible(AppSettings.showOutline)
    }
}
