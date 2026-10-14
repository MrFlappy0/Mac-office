import AppKit
import PaperCore

/// Préférences persistées de l'application (UserDefaults).
enum AppSettings {

    static let version = "0.5"
    static let changedNotification = Notification.Name("AppSettingsChanged")

    static let fonts = [
        "Times New Roman", "Helvetica", "Arial", "Verdana", "Georgia",
        "Palatino", "Optima", "Courier New", "Menlo", "Avenir", "Gill Sans"
    ]
    static let sizes: [CGFloat] = [8, 10, 11, 12, 14, 16, 18, 24, 36, 48, 72]

    static var fontName: String {
        get {
            let v = UserDefaults.standard.string(forKey: "settings.font") ?? "Times New Roman"
            return fonts.contains(v) ? v : "Times New Roman"
        }
        set { UserDefaults.standard.set(newValue, forKey: "settings.font") }
    }

    static var fontSize: CGFloat {
        get {
            let raw = UserDefaults.standard.double(forKey: "settings.size")
            return raw > 0 ? raw : 12
        }
        set { UserDefaults.standard.set(Double(newValue), forKey: "settings.size") }
    }

    static var margin: CGFloat {
        get {
            let raw = UserDefaults.standard.double(forKey: "settings.margin")
            return raw > 0 ? raw : 70
        }
        set { UserDefaults.standard.set(Double(newValue), forKey: "settings.margin") }
    }

    static var spellcheck: Bool {
        get { UserDefaults.standard.object(forKey: "settings.spellcheck") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "settings.spellcheck") }
    }

    static var showOutline: Bool {
        get { UserDefaults.standard.object(forKey: "settings.outline") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "settings.outline") }
    }

    static func defaultAttributes() -> [NSAttributedString.Key: Any] {
        let font = NSFont(name: fontName, size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize)
        return [.font: font]
    }

    static func notifyChanged() {
        NotificationCenter.default.post(name: changedNotification, object: nil)
    }
}

/// Fenêtre Paper → Réglages… (Cmd+,)
final class SettingsWindowController: NSWindowController {

    private let fontPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let sizePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let marginField = NSTextField(frame: .zero)
    private let spellButton = NSButton(checkboxWithTitle: "Correcteur orthographique", target: nil, action: nil)
    private let outlineButton = NSButton(checkboxWithTitle: "Afficher le plan du document", target: nil, action: nil)

    convenience init() {
        let viewController = NSViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "Réglages"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 340, height: 300))
        self.init(window: window)

        for font in AppSettings.fonts {
            fontPopup.addItem(withTitle: font)
        }
        fontPopup.selectItem(withTitle: AppSettings.fontName)
        fontPopup.action = #selector(fontChanged)

        for size in AppSettings.sizes {
            sizePopup.addItem(withTitle: "\(Int(size)) pt")
        }
        let currentSize = AppSettings.sizes.firstIndex(of: AppSettings.fontSize) ?? 3
        sizePopup.selectItem(at: currentSize)
        sizePopup.action = #selector(sizeChanged)

        marginField.stringValue = String(format: "%.0f", AppSettings.margin)
        marginField.placeholderString = "Marges (points)"
        marginField.action = #selector(marginChanged)

        spellButton.state = AppSettings.spellcheck ? .on : .off
        spellButton.action = #selector(spellChanged)
        outlineButton.state = AppSettings.showOutline ? .on : .off
        outlineButton.action = #selector(outlineChanged)

        let grid = NSGridView(views: [
            [label("Police par défaut"), fontPopup],
            [label("Taille"), sizePopup],
            [label("Marges (points)"), marginField],
            [spellButton, NSView()],
            [outlineButton, NSView()],
        ])
        grid.rowSpacing = 10
        grid.columnSpacing = 12
        grid.setContentHuggingPriority(.defaultLow, for: .horizontal)

        viewController.view = NSView()
        viewController.view.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: viewController.view.trailingAnchor, constant: -20),
            fontPopup.widthAnchor.constraint(equalToConstant: 180),
        ])
        window.center()
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 12, weight: .medium)
        field.textColor = .secondaryLabelColor
        return field
    }

    @objc private func fontChanged() {
        AppSettings.fontName = fontPopup.titleOfSelectedItem ?? AppSettings.fontName
        AppSettings.notifyChanged()
    }

    @objc private func sizeChanged() {
        let index = sizePopup.indexOfSelectedItem
        if AppSettings.sizes.indices.contains(index) {
            AppSettings.fontSize = AppSettings.sizes[index]
            AppSettings.notifyChanged()
        }
    }

    @objc private func marginChanged() {
        if let value = Double(marginField.stringValue), value >= 0, value <= 200 {
            AppSettings.margin = value
            AppSettings.notifyChanged()
        } else {
            marginField.stringValue = String(format: "%.0f", AppSettings.margin)
        }
    }

    @objc private func spellChanged() {
        AppSettings.spellcheck = spellButton.state == .on
        AppSettings.notifyChanged()
    }

    @objc private func outlineChanged() {
        AppSettings.showOutline = outlineButton.state == .on
        AppSettings.notifyChanged()
    }
}
