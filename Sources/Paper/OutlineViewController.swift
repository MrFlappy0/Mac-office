import AppKit
import PaperCore

/// Plan du document : liste des titres (par taille de police),
/// clic pour naviguer vers le paragraphe.
final class OutlineViewController: NSViewController,
                                   NSTableViewDataSource, NSTableViewDelegate {

    struct Heading {
        let title: String
        let range: NSRange
        let level: Int
    }

    private let tableView = NSTableView()
    private let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("titre"))
    private var headings: [Heading] = []
    var jump: ((NSRange) -> Void)?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 232, height: 500))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = nil
        tableView.target = nil
        tableView.action = #selector(rowClicked)
        tableView.rowHeight = 24

        let scroll = NSScrollView(frame: container.bounds)
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.autoresizingMask = [.width, .height]
        container.addSubview(scroll)

        let title = NSTextField(labelWithString: "PLAN DU DOCUMENT")
        title.font = .systemFont(ofSize: 10, weight: .bold)
        title.textColor = .secondaryLabelColor
        title.frame = NSRect(x: 14, y: container.bounds.height - 26, width: 200, height: 16)
        title.autoresizingMask = [.width, .minYMargin]
        container.addSubview(title)

        view = container
    }

    func refresh(from attr: NSAttributedString) {
        headings = []
        let nsText = attr.string as NSString
        for paraRange in TextUtils.paragraphRanges(of: attr.string, length: attr.length) {
            let pStart = paraRange.location
            let pEnd = NSMaxRange(paraRange)
            guard pEnd > pStart else { continue }
            let font = attr.attribute(.font, at: pStart, effectiveRange: nil) as? NSFont
            let traits = font.map { NSFontManager.shared.traits(of: $0) } ?? []
            let size = font?.pointSize ?? 12
            let level: Int? = {
                if size >= 22 && traits.contains(.boldFontMask) { return 0 }
                if size >= 18 && traits.contains(.boldFontMask) { return 1 }
                if size >= 15 && traits.contains(.boldFontMask) { return 2 }
                return nil
            }()
            guard let level = level else { continue }
            var text = nsText.substring(with: NSRange(location: pStart, length: pEnd - pStart))
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                headings.append(Heading(title: text,
                                         range: paraRange,
                                         level: level))
            }
        }
        tableView.reloadData()
    }

    @objc private func rowClicked() {
        let row = tableView.clickedRow
        guard row >= 0, row < headings.count else { return }
        jump?(headings[row].range)
    }

    // MARK: - NSTableView

    func numberOfRows(in tableView: NSTableView) -> Int {
        return max(headings.count, 1)
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?,
                   row: Int) -> Any? {
        if row >= headings.count {
            return "Aucun titre. Utilisez Titre 1 à 3 pour structurer le document."
        }
        let indent = String(repeating: "    ", count: headings[row].level)
        return indent + headings[row].title
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}
