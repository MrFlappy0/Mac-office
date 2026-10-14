import Cocoa
import WebKit
import PDFKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, WKScriptMessageHandler, WKUIDelegate {

    var window: NSWindow!
    var webView: WKWebView!
    var docName = "Document sans nom"
    var dirty = false
    var pendingClose = false
    var pendingQuit = false
    let docType = UTType(filenameExtension: "doc") ?? .data
    let mdType = UTType(filenameExtension: "md") ?? .plainText

    // MARK: - Demarrage

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

        if let url = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
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
            webView.evaluateJavaScript("requestSave('html')", completionHandler: nil)
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

    // MARK: - Messages venant de l'editeur

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else { return }
        switch dict["type"] as? String ?? "" {
        case "dirty":
            dirty = dict["value"] as? Bool ?? false
            updateTitle()
        case "new":
            docName = "Document sans nom"
            dirty = false
            updateTitle()
        case "open":
            openDocument()
        case "save":
            handleSave(ext: dict["ext"] as? String ?? "html", html: dict["html"] as? String ?? "")
        case "saveText":
            handleSaveText(text: dict["text"] as? String ?? "")
        case "image":
            pickImage()
        case "pdf":
            exportPDF()
        case "print":
            printDocument()
        default:
            break
        }
    }

    // MARK: - Ouvrir

    func openDocument() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.html, .plainText, .rtf, mdType, docType]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let ext = url.pathExtension.lowercased()
        do {
            let data = try Data(contentsOf: url)
            if ext == "doc", data.starts(with: [0xD0, 0xCF, 0x11, 0xE0]) || data.starts(with: [0x50, 0x4B]) {
                showAlert("Format non pris en charge",
                          "Ce fichier .doc/.docx binaire ne peut pas être ouvert. Enregistrez-le au format HTML, RTF ou texte depuis Word, puis réessayez.")
                return
            }
            if ext == "html" || ext == "htm" || ext == "doc" {
                let s = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript("openHTML(\(js(s)))", completionHandler: nil)
            } else if ext == "rtf" {
                let attr = try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil)
                let htmlData = try attr.data(
                    from: NSRange(location: 0, length: attr.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
                let s = String(data: htmlData, encoding: .utf8) ?? ""
                webView.evaluateJavaScript("openHTML(\(js(s)))", completionHandler: nil)
            } else {
                let s = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript("openText(\(js(s)))", completionHandler: nil)
            }
            docName = url.deletingPathExtension().lastPathComponent
            dirty = false
            updateTitle()
        } catch {
            showAlert("Ouverture impossible", error.localizedDescription)
        }
    }

    // MARK: - Enregistrer

    func handleSave(ext: String, html: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = docName + (ext == "doc" ? ".doc" : ".html")
        panel.allowedContentTypes = ext == "doc" ? [docType] : [.html]
        var saved = false
        if panel.runModal() == .OK, let url = panel.url {
            let content: String
            if ext == "doc" {
                content = "<html xmlns:o=\"urn:schemas-microsoft-com:office:office\" xmlns:w=\"urn:schemas-microsoft-com:office:word\"><head><meta charset=\"utf-8\"><title>\(docName)</title></head><body>\(html)</body></html>"
            } else {
                content = "<!DOCTYPE html><html lang=\"fr\"><head><meta charset=\"utf-8\"><title>\(docName)</title></head><body>\(html)</body></html>"
            }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                docName = url.deletingPathExtension().lastPathComponent
                dirty = false
                updateTitle()
                webView.evaluateJavaScript("afterSave()", completionHandler: nil)
                saved = true
            } catch {
                showAlert("Enregistrement impossible", error.localizedDescription)
            }
        }
        if pendingClose {
            pendingClose = false
            if saved { window.close() }
        }
        if pendingQuit {
            pendingQuit = false
            NSApp.reply(toApplicationShouldTerminate: saved)
        }
    }

    func handleSaveText(text: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = docName + ".txt"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                docName = url.deletingPathExtension().lastPathComponent
                dirty = false
                updateTitle()
                webView.evaluateJavaScript("afterSave()", completionHandler: nil)
            } catch {
                showAlert("Enregistrement impossible", error.localizedDescription)
            }
        }
    }

    // MARK: - Images

    func pickImage() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) else { return }
        let e = url.pathExtension.lowercased()
        let mime = e == "png" ? "png" : (e == "gif" ? "gif" : "jpeg")
        webView.evaluateJavaScript("insertImage('data:image/\(mime);base64,\(data.base64EncodedString())')", completionHandler: nil)
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

    func exportPDF() {
        makePDF { data in
            guard let data = data else { return }
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = self.docName + ".pdf"
            if panel.runModal() == .OK, let url = panel.url {
                do {
                    try data.write(to: url, options: .atomic)
                } catch {
                    self.showAlert("Export impossible", error.localizedDescription)
                }
            }
        }
    }

    func printDocument() {
        makePDF { data in
            guard let data = data, let pdf = PDFDocument(data: data) else { return }
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
            webView.evaluateJavaScript("requestSave('html')", completionHandler: nil)
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
        a.messageText = "Paper 1.0"
        a.informativeText = "Traitement de texte pour macOS : mise en forme, styles, plan de navigation du document, tableaux éditables, images, liens, recherche/remplacement, sauvegarde automatique, export Word (.doc), HTML, PDF et texte brut."
        a.runModal()
    }
    @objc func doNew() { webView.evaluateJavaScript("newDoc()", completionHandler: nil) }
    @objc func doOpen() { openDocument() }
    @objc func doSaveHTML() { webView.evaluateJavaScript("requestSave('html')", completionHandler: nil) }
    @objc func doSaveDoc() { webView.evaluateJavaScript("requestSave('doc')", completionHandler: nil) }
    @objc func doSaveTxt() { webView.evaluateJavaScript("requestSaveText()", completionHandler: nil) }
    @objc func doExportPDF() { exportPDF() }
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

    // MARK: - Barre de menus

    private func item(_ title: String, action: Selector, key: String = "", shift: Bool = false) -> NSMenuItem {
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
        appMenu.addItem(std("Masquer Paper", action: Selector("hide:"), key: "h"))
        appMenu.addItem(.separator())
        appMenu.addItem(std("Quitter Paper", action: Selector("terminate:"), key: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let fileItem = NSMenuItem()
        let fileMenu = NSMenu(title: "Fichier")
        fileMenu.addItem(item("Nouveau", action: #selector(doNew), key: "n"))
        fileMenu.addItem(item("Ouvrir…", action: #selector(doOpen), key: "o"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(item("Enregistrer (HTML)…", action: #selector(doSaveHTML), key: "s"))
        fileMenu.addItem(item("Enregistrer au format Word (.doc)…", action: #selector(doSaveDoc), key: "s", shift: true))
        fileMenu.addItem(item("Enregistrer en texte brut (.txt)…", action: #selector(doSaveTxt)))
        fileMenu.addItem(item("Exporter en PDF…", action: #selector(doExportPDF), key: "e"))
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

    // MARK: - Boites de dialogue JS

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.runModal()
        completionHandler()
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.addButton(withTitle: "OK")
        a.addButton(withTitle: "Annuler")
        completionHandler(a.runModal() == .alertFirstButtonReturn)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
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
