import AppKit
import PaperCore

/// Contrôleur de documents : Paper est l'application qui ouvre
/// les documents non titrés de type PaperDocument.
final class PaperDocumentController: NSDocumentController {
    override var defaultType: String? { Formats.docx.identifier }
    override var documentClassNames: [String] { ["PaperDocument"] }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        if NSApp.windows.isEmpty {
            NSDocumentController.shared.newDocument(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        buildMenu()
    }

    // MARK: - Réglages

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow?.showWindow(self)
    }

    // MARK: - À propos

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Paper \(AppSettings.version)"
        alert.informativeText = """
            Traitement de texte 100 % natif pour macOS.
            Formats : Word (.docx), Word 97 (.doc), RTF, HTML, texte.
            L'extension est choisie au moment de l'enregistrement.
            """
        alert.addButton(withTitle: "Fermer")
        alert.runModal()
    }

    // MARK: - Barre de menus

    private func item(_ title: String, action: Selector, key: String = "",
                      shift: Bool = false, alt: Bool = false) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        if shift || alt {
            var mask: NSEvent.ModifierFlags = [.command]
            if shift { mask.insert(.shift) }
            if alt { mask.insert(.option) }
            i.keyEquivalentModifierMask = mask
        }
        return i
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        // Paper
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(item("À propos de Paper", action: #selector(showAbout)))
        appMenu.addItem(.separator())
        appMenu.addItem(item("Réglages…", action: #selector(showSettings), key: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(item("Masquer Paper", action: Selector("hide:"), key: "h"))
        appMenu.addItem(.separator())
        appMenu.addItem(item("Quitter Paper", action: Selector("terminate:"), key: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        // Fichier
        let fileItem = NSMenuItem()
        let fileMenu = NSMenu(title: "Fichier")
        fileMenu.addItem(item("Nouveau", action: Selector("newDocument:"), key: "n"))
        fileMenu.addItem(item("Ouvrir…", action: Selector("openDocument:"), key: "o"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(item("Enregistrer", action: Selector("saveDocument:"), key: "s"))
        fileMenu.addItem(item("Enregistrer sous…", action: Selector("saveDocumentAs:"), key: "s", shift: true))
        fileMenu.addItem(.separator())
        fileMenu.addItem(item("Imprimer…", action: Selector("printDocument:"), key: "p"))
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

        // Édition
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Édition")
        editMenu.addItem(item("Annuler", action: Selector("undo:"), key: "z"))
        editMenu.addItem(item("Rétablir", action: Selector("redo:"), key: "z", shift: true))
        editMenu.addItem(.separator())
        editMenu.addItem(item("Couper", action: Selector("cut:"), key: "x"))
        editMenu.addItem(item("Copier", action: Selector("copy:"), key: "c"))
        editMenu.addItem(item("Coller", action: Selector("paste:"), key: "v"))
        editMenu.addItem(item("Coller sans mise en forme", action: Selector("pasteAsPlainText:"),
                              key: "v", shift: true, alt: true))
        editMenu.addItem(item("Tout sélectionner", action: Selector("selectAll:"), key: "a"))
        editMenu.addItem(.separator())
        editMenu.addItem(item("Rechercher…", action: Selector("performTextFinderAction:"),
                              key: "f", alt: true))
        editMenu.items.last?.tag = NSTextFinder.Action.showFindInterface.rawValue
        editMenu.addItem(item("Suivant", action: Selector("performTextFinderAction:"), key: "g"))
        editMenu.items.last?.tag = NSTextFinder.Action.nextMatch.rawValue
        editMenu.addItem(item("Précédent", action: Selector("performTextFinderAction:"), key: "g", shift: true))
        editMenu.items.last?.tag = NSTextFinder.Action.previousMatch.rawValue
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        // Format
        let fmtItem = NSMenuItem()
        let fmtMenu = NSMenu(title: "Format")
        fmtMenu.addItem(item("Gras", action: Selector("toggleBoldFace:"), key: "b"))
        fmtMenu.addItem(item("Italique", action: Selector("toggleItalicFace:"), key: "i"))
        fmtMenu.addItem(item("Souligné", action: Selector("toggleUnderline:"), key: "u"))
        fmtMenu.addItem(item("Barré", action: Selector("toggleStrikethrough:")))
        fmtMenu.addItem(.separator())
        fmtMenu.addItem(item("Exposant", action: Selector("superscript:")))
        fmtMenu.addItem(item("Indice", action: Selector("subscript:")))
        fmtMenu.addItem(.separator())
        fmtMenu.addItem(item("Aligner à gauche", action: Selector("alignLeft:"),
                              key: "{", alt: true))
        fmtMenu.addItem(item("Centrer", action: Selector("alignCenter:"),
                              key: "|", alt: true))
        fmtMenu.addItem(item("Aligner à droite", action: Selector("alignRight:"),
                              key: "}", alt: true))
        fmtMenu.addItem(item("Justifier", action: Selector("alignJustified:")))
        fmtMenu.addItem(.separator())
        let lineMenu = NSMenu(title: "Interligne")
        for (label, value) in [("Simple", 1.0), ("Compact", 1.15), ("Normal", 1.45), ("Large", 2.0)] {
            let li = item(label, action: Selector("setLineHeight:"))
            li.representedObject = value
            lineMenu.addItem(li)
        }
        let lineItem = NSMenuItem(title: "Interligne", action: nil, keyEquivalent: "")
        lineItem.submenu = lineMenu
        fmtMenu.addItem(lineItem)
        fmtMenu.addItem(.separator())
        fmtMenu.addItem(item("Liste à puces", action: Selector("toggleBulletList:")))
        fmtMenu.addItem(item("Liste numérotée", action: Selector("toggleNumberedList:")))
        fmtMenu.addItem(.separator())
        fmtMenu.addItem(item("Afficher les polices", action: Selector("orderFrontFontPanel:"), key: "t"))
        fmtMenu.addItem(item("Afficher les couleurs", action: Selector("orderFrontColorPanel:")))
        fmtItem.submenu = fmtMenu
        mainMenu.addItem(fmtItem)

        // Styles
        let styleItem = NSMenuItem()
        let styleMenu = NSMenu(title: "Styles")
        styleMenu.addItem(item("Titre 1", action: Selector("makeHeading1:")))
        styleMenu.addItem(item("Titre 2", action: Selector("makeHeading2:")))
        styleMenu.addItem(item("Titre 3", action: Selector("makeHeading3:")))
        styleMenu.addItem(item("Corps de texte", action: Selector("makeBody:")))
        styleItem.submenu = styleMenu
        mainMenu.addItem(styleItem)

        // Insertion
        let insertItem = NSMenuItem()
        let insertMenu = NSMenu(title: "Insertion")
        insertMenu.addItem(item("Image…", action: Selector("insertImage:")))
        insertMenu.addItem(item("Lien…", action: Selector("insertLinkMenu:")))
        insertMenu.addItem(item("Date du jour", action: Selector("insertDate:")))
        insertMenu.addItem(item("Page de garde…", action: Selector("insertCover:")))
        insertMenu.addItem(item("Caractères spéciaux…", action: Selector("insertSymbols:")))
        insertItem.submenu = insertMenu
        mainMenu.addItem(insertItem)

        // Affichage
        let viewItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Affichage")
        viewMenu.addItem(item("Plan du document", action: Selector("toggleOutline:")))
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        // Fenêtre
        let winItem = NSMenuItem()
        let winMenu = NSMenu(title: "Fenêtre")
        winMenu.addItem(item("Réduire", action: Selector("performMiniaturize:"), key: "m"))
        winMenu.addItem(item("Zoom", action: Selector("performZoom:")))
        winItem.submenu = winMenu
        mainMenu.addItem(winItem)

        NSApp.mainMenu = mainMenu
    }
}
