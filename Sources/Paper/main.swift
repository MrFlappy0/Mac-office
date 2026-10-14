import Cocoa
import WebKit
import PDFKit
import UniformTypeIdentifiers

// MARK: - Réglages persistants

enum Settings {
    static let fonts = [
        "Times New Roman", "Helvetica", "Arial", "Verdana", "Georgia",
        "Palatino", "Optima", "Courier New", "Menlo", "Avenir", "Gill Sans"
    ]
    static let sizes: [Int] = [10, 11, 12, 14, 16, 18, 24, 36]

    static var fontName: String {
        get {
            let v = UserDefaults.standard.string(forKey: "settings.font") ?? "Times New Roman"
            return fonts.contains(v) ? v : "Times New Roman"
        }
        set { UserDefaults.standard.set(newValue, forKey: "settings.font") }
    }

    static var fontSize: Int {
        get {
            let raw = UserDefaults.standard.integer(forKey: "settings.size")
            return raw > 0 ? raw : 12
        }
        set { UserDefaults.standard.set(newValue, forKey: "settings.size") }
    }

    static var margin: Int {
        get {
            let raw = UserDefaults.standard.integer(forKey: "settings.margin")
            return raw > 0 ? raw : 94
        }
        set { UserDefaults.standard.set(newValue, forKey: "settings.margin") }
    }

    static var spellcheck: Bool {
        get { UserDefaults.standard.object(forKey: "settings.spellcheck") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "settings.spellcheck") }
    }

    static var recentDocuments: [URL] {
        get {
            let paths = UserDefaults.standard.stringArray(forKey: "recent.documents") ?? []
            return paths.map { URL(fileURLWithPath: $0) }
        }
        set {
            let paths = Array(newValue.prefix(8).map { $0.path })
            UserDefaults.standard.set(paths, forKey: "recent.documents")
        }
    }

    static func recordRecent(_ url: URL) {
        var recents = recentDocuments.filter { $0 != url }
        recents.insert(url, at: 0)
        recentDocuments = recents
    }
}

// MARK: - Fenêtre Réglages

final class SettingsWindowController: NSWindowController {

    private let fontPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let sizePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let marginField = NSTextField(frame: .zero)
    private let spellButton = NSButton(checkboxWithTitle: "Correcteur orthographique",
                                       target: nil, action: nil)
    var onApply: (() -> Void)?

    convenience init(apply: @escaping () -> Void) {
        let viewController = NSViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "Réglages"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 340, height: 220))
        self.init(window: window)
        onApply = apply

        for font in Settings.fonts {
            fontPopup.addItem(withTitle: font)
        }
        fontPopup.selectItem(withTitle: Settings.fontName)
        fontPopup.action = #selector(changed)

        for size in Settings.sizes {
            sizePopup.addItem(withTitle: "\(size) pt")
        }
        sizePopup.selectItem(at: Settings.sizes.firstIndex(of: Settings.fontSize) ?? 2)
        sizePopup.action = #selector(changed)

        marginField.stringValue = String(Settings.margin)
        marginField.action = #selector(changed)
        spellButton.state = Settings.spellcheck ? .on : .off
        spellButton.action = #selector(changed)

        func label(_ text: String) -> NSTextField {
            let field = NSTextField(labelWithString: text)
            field.font = .systemFont(ofSize: 12, weight: .medium)
            field.textColor = .secondaryLabelColor
            return field
        }

        let grid = NSGridView(views: [
            [label("Police par défaut"), fontPopup],
            [label("Taille"), sizePopup],
            [label("Marges (pixels)"), marginField],
            [spellButton, NSView()],
        ])
        grid.rowSpacing = 10
        grid.columnSpacing = 12

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

    @objc private func changed() {
        if let font = fontPopup.titleOfSelectedItem { Settings.fontName = font }
        let index = sizePopup.indexOfSelectedItem
        if Settings.sizes.indices.contains(index) { Settings.fontSize = Settings.sizes[index] }
        if let value = Int(marginField.stringValue), value >= 20, value <= 200 {
            Settings.margin = value
        } else {
            marginField.stringValue = String(Settings.margin)
        }
        Settings.spellcheck = spellButton.state == .on
        onApply?()
    }
}

// MARK: - Délégué de l'application

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate,
                         WKScriptMessageHandler, WKUIDelegate, NSMenuDelegate {

    var window: NSWindow!
    var webView: WKWebView!
    var docName = "Document sans nom"
    var dirty = false
    var pendingClose = false
    var pendingQuit = false
    var editorLoaded = false
    var settingsWindow: SettingsWindowController?
    let recentMenu = NSMenu(title: "Ouvrir récent")
    let docType = UTType(filenameExtension: "doc") ?? .data
    let docxType = UTType(filenameExtension: "docx") ?? .data

    // MARK: - Démarrage

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = docName
        window.minSize = NSSize(width: 720, height: 460)
        window.delegate = self
        window.center()

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, contentWorld: .page, name: "app")
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.uiDelegate = self
        webView.autoresizingMask = [.width, .height]

        // editor.html : depuis le bundle en production, depuis Resources/ en dev
        let editorURL = Bundle.main.url(forResource: "editor", withExtension: "html")
            ?? URL(fileURLWithPath: "Resources/editor.html").absoluteURL
        if FileManager.default.fileExists(atPath: editorURL.path) {
            webView.loadFileURL(editorURL,
                                allowingReadAccessTo: editorURL.deletingLastPathComponent())
        } else {
            NSLog("Paper: editor.html introuvable (%@)", editorURL.path)
        }
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        buildMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if !dirty { return .terminateNow }
        let a = NSAlert()
        a.messageText = "Enregistrer les modifications ?"
        a.informativeText = "« \(docName) » contient des modifications non enregistrées."
        a.addButton(withTitle: "Enregistrer")
        a.addButton(withTitle: "Ne pas enregistrer")
        a.addButton(withTitle: "Annuler")
        switch a.runModal() {
        case .alertFirstButtonReturn:
            pendingQuit = true
            webView.evaluateJavaScript("requestSave()", completionHandler: nil)
            return .terminateLater
        case .alertSecondButtonReturn:
            return .terminateNow
        default:
            return .terminateCancel
        }
    }

    // MARK: - Titre

    func updateTitle() {
        window.title = (dirty ? "• " : "") + docName
    }

    // MARK: - Réglages

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(apply: { [weak self] in
                self?.applySettings()
            })
        }
        settingsWindow?.showWindow(self)
    }

    func applySettings() {
        let script = "applySettings(\(js(Settings.fontName)), \(Settings.fontSize), \(Settings.margin), \(Settings.spellcheck))"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    // MARK: - Documents récents

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let recents = Settings.recentDocuments.filter {
            FileManager.default.fileExists(atPath: $0.path)
        }
        if recents.isEmpty {
            let empty = NSMenuItem(title: "Aucun document récent", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }
        for url in recents {
            let menuItem = NSMenuItem(title: url.lastPathComponent,
                                      action: #selector(openRecent(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = url.path
            menu.addItem(menuItem)
        }
    }

    @objc private func openRecent(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        openDocument(url: URL(fileURLWithPath: path))
    }

    // MARK: - Messages venant de l'éditeur

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else { return }
        switch dict["type"] as? String ?? "" {
        case "dirty":
            dirty = dict["value"] as? Bool ?? false
            updateTitle()
        case "loaded":
            editorLoaded = true
            applySettings()
            NSLog("Paper: éditeur chargé")
        case "new":
            docName = "Document sans nom"
            dirty = false
            updateTitle()
        case "open":
            openDocument()
        case "save":
            handleSave(html: dict["html"] as? String ?? "",
                      docx: dict["docx"] as? String ?? "")
        case "image":
            pickImage()
        case "print":
            printDocument()
        case "rename":
            let name = (dict["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                docName = name
                updateTitle()
            }
        case "about":
            doAbout()
        default:
            break
        }
    }

    // MARK: - Ouvrir

    func openDocument() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.html, docType, docxType]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openDocument(url: url)
    }

    func openDocument(url: URL) {
        let ext = url.pathExtension.lowercased()
        do {
            let data = try Data(contentsOf: url)
            let isBinaryOffice = data.starts(with: [0xD0, 0xCF, 0x11, 0xE0])
                || data.starts(with: [0x50, 0x4B])
            if (ext == "docx") || (ext == "doc" && isBinaryOffice) {
                // .docx (ZIP) ou .doc binaire Word 97 : conversion via textutil
                guard let html = convertWithTextutil(url: url) else {
                    showAlert("Ouverture impossible",
                              "Ce document ne peut pas être converti. Formats acceptés : .docx, .doc et .html.")
                    return
                }
                webView.evaluateJavaScript("openHTML(\(js(html)))", completionHandler: nil)
            } else if ext == "html" || ext == "htm" || ext == "doc" {
                let s = String(data: data, encoding: .utf8)
                    ?? String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript("openHTML(\(js(s)))", completionHandler: nil)
            } else {
                showAlert("Format non pris en charge",
                          "Paper ouvre les documents .docx, .doc et .html.")
                return
            }
            docName = url.deletingPathExtension().lastPathComponent
            dirty = false
            updateTitle()
            Settings.recordRecent(url)
        } catch {
            showAlert("Ouverture impossible",
                      "Ce document ne peut pas être lu. Formats acceptés : .docx, .doc et .html.")
        }
    }

    /// Convertit un document .docx/.doc binaire en HTML avec l'outil natif textutil.
    func convertWithTextutil(url: URL) -> String? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("paper-\(UUID().uuidString).html")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", "html", "-output", tmp.path, url.path]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        defer { try? FileManager.default.removeItem(at: tmp) }
        guard process.terminationStatus == 0,
              let html = try? String(contentsOf: tmp, encoding: .utf8) else { return nil }
        return html
    }

    // MARK: - Enregistrer (extension choisie dans le panneau, défaut Word .docx)

    func handleSave(html: String, docx: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [docxType, docType, .html, .pdf]
        panel.nameFieldStringValue = docName + ".docx"
        guard panel.runModal() == .OK, let url = panel.url else {
            webView.evaluateJavaScript("saveCancelled()", completionHandler: nil)
            finishPendingSave(false)
            return
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "docx":
            guard let data = Data(base64Encoded: docx) else {
                showAlert("Enregistrement impossible",
                          "Le document n'a pas pu être converti au format Word.")
                finishPendingSave(false)
                return
            }
            do {
                try data.write(to: url, options: .atomic)
                saveSucceeded(url)
            } catch {
                showAlert("Enregistrement impossible", error.localizedDescription)
                webView.evaluateJavaScript("saveError()", completionHandler: nil)
                finishPendingSave(false)
            }
        case "doc":
            let content = "<html xmlns:o=\"urn:schemas-microsoft-com:office:office\""
                + " xmlns:w=\"urn:schemas-microsoft-com:office:word\">"
                + "<head><meta charset=\"utf-8\"><title>\(docName)</title></head>"
                + "<body>\(html)</body></html>"
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                saveSucceeded(url)
            } catch {
                showAlert("Enregistrement impossible", error.localizedDescription)
                webView.evaluateJavaScript("saveError()", completionHandler: nil)
                finishPendingSave(false)
            }
        case "pdf":
            makePDF { [weak self] data in
                guard let self = self, let data = data else {
                    self?.finishPendingSave(false)
                    return
                }
                do {
                    try data.write(to: url, options: .atomic)
                    self.saveSucceeded(url)
                } catch {
                    self.showAlert("Enregistrement impossible", error.localizedDescription)
                    self.webView.evaluateJavaScript("saveError()", completionHandler: nil)
                    self.finishPendingSave(false)
                }
            }
        default:
            let content = "<!DOCTYPE html><html lang=\"fr\"><head><meta charset=\"utf-8\">"
                + "<title>\(docName)</title></head><body>\(html)</body></html>"
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                saveSucceeded(url)
            } catch {
                showAlert("Enregistrement impossible", error.localizedDescription)
                webView.evaluateJavaScript("saveError()", completionHandler: nil)
                finishPendingSave(false)
            }
        }
    }

    func saveSucceeded(_ url: URL) {
        docName = url.deletingPathExtension().lastPathComponent
        dirty = false
        updateTitle()
        Settings.recordRecent(url)
        webView.evaluateJavaScript("afterSave()", completionHandler: nil)
        finishPendingSave(true)
    }

    func finishPendingSave(_ saved: Bool) {
        if pendingClose {
            pendingClose = false
            if saved { window.close() }
        }
        if pendingQuit {
            pendingQuit = false
            NSApp.reply(toApplicationShouldTerminate: saved)
        }
    }

    // MARK: - Images

    func pickImage() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? Data(contentsOf: url) else { return }
        let e = url.pathExtension.lowercased()
        let mime = e == "png" ? "png" : (e == "gif" ? "gif" : "jpeg")
        webView.evaluateJavaScript(
            "insertImage('data:image/\(mime);base64,\(data.base64EncodedString())')",
            completionHandler: nil)
    }

    // MARK: - PDF et impression

    func makePDF(_ done: @escaping (Data?) -> Void) {
        webView.evaluateJavaScript("enterPdfMode()") { _, _ in
            self.webView.createPDF { result in
                self.webView.evaluateJavaScript("exitPdfMode()", completionHandler: nil)
                switch result {
                case .success(let data):
                    done(data)
                case .failure(let error):
                    self.showAlert("Génération du PDF impossible", error.localizedDescription)
                    done(nil)
                }
            }
        }
    }

    func printDocument() {
        makePDF { [weak self] data in
            guard let self = self, let data = data,
                  let pdf = PDFDocument(data: data) else { return }
            let info = NSPrintInfo.shared
            info.paperSize = NSSize(width: 595.28, height: 841.89)
            info.orientation = .portrait
            let pdfView = PDFView(frame: NSRect(x: 0, y: 0, width: 595.28, height: 841.89))
            pdfView.document = pdf
            pdfView.print(with: info, autoRotate: true)
        }
    }

    // MARK: - Fermeture

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if !dirty { return true }
        let a = NSAlert()
        a.messageText = "Enregistrer les modifications ?"
        a.informativeText = "« \(docName) » contient des modifications non enregistrées."
        a.addButton(withTitle: "Enregistrer")
        a.addButton(withTitle: "Ne pas enregistrer")
        a.addButton(withTitle: "Annuler")
        switch a.runModal() {
        case .alertFirstButtonReturn:
            pendingClose = true
            webView.evaluateJavaScript("requestSave()", completionHandler: nil)
            return false
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    // MARK: - Actions des menus

    @objc func doAbout() {
        let a = NSAlert()
        a.messageText = "Paper"
        a.informativeText = """
            Traitement de texte pour macOS, interface à onglets façon Apple.
            Le format (Word .docx, Word 97, HTML, PDF) se choisit au moment d'enregistrer.
            """
        a.runModal()
    }
    @objc func doNew() { webView.evaluateJavaScript("newDoc()", completionHandler: nil) }
    @objc func doOpen() { openDocument() }
    @objc func doSave() { webView.evaluateJavaScript("requestSave()", completionHandler: nil) }
    @objc func doPrint() { printDocument() }
    @objc func doFind() { webView.evaluateJavaScript("toggleFind(true)", completionHandler: nil) }
    @objc func doUndo() { webView.evaluateJavaScript("cmd('undo')", completionHandler: nil) }
    @objc func doRedo() { webView.evaluateJavaScript("cmd('redo')", completionHandler: nil) }
    @objc func doBold() { webView.evaluateJavaScript("cmd('bold')", completionHandler: nil) }
    @objc func doItalic() { webView.evaluateJavaScript("cmd('italic')", completionHandler: nil) }
    @objc func doUnderline() { webView.evaluateJavaScript("cmd('underline')", completionHandler: nil) }
    @objc func doStrike() { webView.evaluateJavaScript("cmd('strikeThrough')", completionHandler: nil) }
    @objc func doOutline() { webView.evaluateJavaScript("toggleOutline()", completionHandler: nil) }
    @objc func doZoomIn() { webView.evaluateJavaScript("zoomIn()", completionHandler: nil) }
    @objc func doZoomOut() { webView.evaluateJavaScript("zoomOut()", completionHandler: nil) }
    @objc func doZoomReset() { webView.evaluateJavaScript("zoomReset()", completionHandler: nil) }
    @objc func doSymbols() { webView.evaluateJavaScript("openDialog('symbols')", completionHandler: nil) }
    @objc func doShortcuts() { webView.evaluateJavaScript("openDialog('shortcuts')", completionHandler: nil) }
    @objc func doCover() { webView.evaluateJavaScript("insertCover()", completionHandler: nil) }
    @objc func doPastePlain() { webView.evaluateJavaScript("pastePlain()", completionHandler: nil) }

    // MARK: - Barre de menus

    private func item(_ title: String, action: Selector, key: String = "",
                      shift: Bool = false) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        if shift { i.keyEquivalentModifierMask = [.command, .shift] }
        return i
    }

    private func std(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        return NSMenuItem(title: title, action: action, keyEquivalent: key)
    }

    func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(item("À propos de Paper", action: #selector(doAbout)))
        appMenu.addItem(.separator())
        appMenu.addItem(item("Réglages…", action: #selector(showSettings), key: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(std("Masquer Paper", action: Selector("hide:"), key: "h"))
        appMenu.addItem(.separator())
        appMenu.addItem(std("Quitter Paper", action: Selector("terminate:"), key: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let fileItem = NSMenuItem()
        let fileMenu = NSMenu(title: "Fichier")
        fileMenu.addItem(item("Nouveau", action: #selector(doNew), key: "n"))
        fileMenu.addItem(item("Ouvrir…", action: #selector(doOpen), key: "o"))
        let recentItem = NSMenuItem(title: "Ouvrir récent", action: nil, keyEquivalent: "")
        recentMenu.delegate = self
        recentItem.submenu = recentMenu
        fileMenu.addItem(recentItem)
        fileMenu.addItem(.separator())
        fileMenu.addItem(item("Enregistrer…", action: #selector(doSave), key: "s"))
        fileMenu.addItem(item("Imprimer…", action: #selector(doPrint), key: "p"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(std("Fermer", action: Selector("performClose:"), key: "w"))
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Édition")
        editMenu.addItem(item("Annuler", action: #selector(doUndo), key: "z"))
        editMenu.addItem(item("Rétablir", action: #selector(doRedo), key: "z", shift: true))
        editMenu.addItem(.separator())
        editMenu.addItem(std("Couper", action: Selector("cut:"), key: "x"))
        editMenu.addItem(std("Copier", action: Selector("copy:"), key: "c"))
        editMenu.addItem(std("Coller", action: Selector("paste:"), key: "v"))
        let plainPasteItem = item("Coller sans mise en forme", action: #selector(doPastePlain), key: "v")
        plainPasteItem.keyEquivalentModifierMask = [.command, .option, .shift]
        editMenu.addItem(plainPasteItem)
        editMenu.addItem(std("Tout sélectionner", action: Selector("selectAll:"), key: "a"))
        editMenu.addItem(.separator())
        editMenu.addItem(item("Rechercher…", action: #selector(doFind), key: "f"))
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        let fmtItem = NSMenuItem()
        let fmtMenu = NSMenu(title: "Format")
        fmtMenu.addItem(item("Gras", action: #selector(doBold), key: "b"))
        fmtMenu.addItem(item("Italique", action: #selector(doItalic), key: "i"))
        fmtMenu.addItem(item("Souligné", action: #selector(doUnderline), key: "u"))
        fmtMenu.addItem(item("Barré", action: #selector(doStrike)))
        fmtMenu.addItem(.separator())
        fmtMenu.addItem(item("Caractères spéciaux…", action: #selector(doSymbols)))
        fmtMenu.addItem(item("Page de garde…", action: #selector(doCover)))
        fmtItem.submenu = fmtMenu
        mainMenu.addItem(fmtItem)

        let viewItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Affichage")
        viewMenu.addItem(item("Plan du document", action: #selector(doOutline)))
        viewMenu.addItem(.separator())
        viewMenu.addItem(item("Zoom avant", action: #selector(doZoomIn), key: "+"))
        viewMenu.addItem(item("Zoom arrière", action: #selector(doZoomOut), key: "-"))
        viewMenu.addItem(item("Zoom 100 %", action: #selector(doZoomReset), key: "0"))
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        let winItem = NSMenuItem()
        let winMenu = NSMenu(title: "Fenêtre")
        winMenu.addItem(std("Réduire", action: Selector("performMiniaturize:"), key: "m"))
        winMenu.addItem(std("Zoom", action: Selector("performZoom:")))
        winItem.submenu = winMenu
        mainMenu.addItem(winItem)

        let helpItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Aide")
        helpMenu.addItem(item("Raccourcis clavier…", action: #selector(doShortcuts)))
        helpItem.submenu = helpMenu
        mainMenu.addItem(helpItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Boîtes de dialogue JS

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.runModal()
        completionHandler()
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.addButton(withTitle: "OK")
        a.addButton(withTitle: "Annuler")
        completionHandler(a.runModal() == .alertFirstButtonReturn)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let a = NSAlert()
        a.messageText = prompt
        a.addButton(withTitle: "OK")
        a.addButton(withTitle: "Annuler")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = defaultText ?? ""
        a.accessoryView = field
        if a.runModal() == .alertFirstButtonReturn {
            completionHandler(field.stringValue)
        } else {
            completionHandler(nil)
        }
    }

    // MARK: - Utilitaires

    func showAlert(_ title: String, _ text: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        a.runModal()
    }

    func js(_ s: String) -> String {
        let d = (try? JSONSerialization.data(withJSONObject: [s])) ?? Data("[]".utf8)
        var t = String(data: d, encoding: .utf8) ?? "\"\""
        t.removeFirst()
        t.removeLast()
        return t
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
