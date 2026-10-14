import AppKit

/// Fenêtre flottante de caractères spéciaux (guillemets français,
/// symboles, accents et ligatures).
final class SymbolsPanel {

    static let shared = SymbolsPanel()

    private var panel: NSPanel?
    private var insert: ((String) -> Void)?

    private let characters: [String] = [
        "«", "»", "“", "”", "‘", "’", "—", "–",
        "…", "€", "œ", "Œ", "æ", "Æ", "©", "®",
        "™", "°", "±", "×", "÷", "²", "³", "½",
        "¼", "¾", "§", "¶", "†", "•", "¡", "¿",
        "Á", "À", "Â", "Ä", "É", "È", "Ê", "Ë",
        "Í", "Ì", "Î", "Ï", "Ó", "Ò", "Ô", "Ö",
        "Ú", "Ù", "Û", "Ü", "Ç", "Ÿ", " ", " ",
    ]

    func show(insert: @escaping (String) -> Void) {
        self.insert = insert
        if panel == nil {
            buildPanel()
        }
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
    }

    private func buildPanel() {
        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable, .miniaturizable, .utilityWindow],
            backing: .buffered, defer: false)
        newPanel.title = "Caractères spéciaux"
        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.hidesOnDeactivate = false

        var rows: [[NSView]] = []
        for row in stride(from: 0, to: characters.count, by: 8) {
            let slice = characters[row..<min(row + 8, characters.count)]
            rows.append(slice.map { character in
                let button = NSButton(title: character, target: self,
                                       action: #selector(pick(_:)))
                button.bezelStyle = .texturedRounded
                button.font = .systemFont(ofSize: 15)
                button.widthAnchor.constraint(equalToConstant: 40).isActive = true
                return button
            })
        }
        let grid = NSGridView(views: rows)
        grid.rowSpacing = 6
        grid.columnSpacing = 6
        grid.xPlacement = .fill

        newPanel.contentView = grid
        panel = newPanel
    }

    @objc private func pick(_ sender: NSButton) {
        insert?(sender.title)
        panel?.orderOut(nil)
    }
}
