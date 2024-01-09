//
//  LocalExecutionExtension.swift
//  Code
//
//  Created by Ken Chung on 19/11/2022.
//

import Foundation
import pydeCommon
import SwiftUI
import UIKit
import python3_objc
import ios_system
import QuickLook

fileprivate var isPythonUIRunning = false

private let EXTENSION_ID = "PYLOCAL_EXECUTION"

private let LOCAL_EXECUTION_COMMANDS = [
    "py": ["python3 -u {url}"],
    "ui.py": ["python3 -u {url}"],
    "js": ["node {url}"],
    "c": ["clang {url}", "wasm a.out"],
    "cpp": ["clang++ {url}", "wasm a.out"],
    "php": ["php {url}"],
]

class PYLocalExecutionExtension: CodeAppExtension {
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let toolbarItem = ToolbarItem(
            extenionID: EXTENSION_ID,
            icon: "play",
            onClick: {
                Task {
                    await self.runCodeLocally(app: app)
                }
            },
            shortCut: .init("r", modifiers: [.command]),
            panelToFocusOnTap: "RUNNER",
            shouldDisplay: {
                guard let activeTextEditor = app.activeTextEditor else { return false }
                return activeTextEditor.url.isFileURL
                    && LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] != nil
            }
        )
        contribution.toolBar.registerItem(item: toolbarItem)
        
        wmessager.listenForMessage(withIdentifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT) { _ in
            isPythonUIRunning = false
        }
    }

    private func runCodeLocally(app: MainApp) async {

        guard let activeTextEditor = await app.activeTextEditor as? PYTextEditorInstance else {
            return
        }
        
        guard await activeTextEditor.runnerView.executor?.state == .idle else {return}

        guard let commands = LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] else {
            return
        }

        await app.saveCurrentFile()

        let sanitizedUrl = activeTextEditor.url.path.replacingOccurrences(of: " ", with: #"\ "#)
        let parsedCommands = (sanitizedUrl.hasSuffix(".ui.py") ? LOCAL_EXECUTION_COMMANDS["ui.py"]! : commands)
        .map {
            $0.replacingOccurrences(of: "{url}", with: sanitizedUrl)
        }

//        let compilerShowPath = UserDefaults.standard.bool(forKey: "compilerShowPath")
//        if compilerShowPath {
//            app.terminalInstance.executeScript(
//                "localEcho.println(`\(parsedCommands.joined(separator: " && "))`);readLine('');")
//        } else {
//            let commandName =
//                parsedCommands.first?.components(separatedBy: " ").first
//                ?? activeTextEditor.languageIdentifier
//            app.terminalInstance.executeScript("localEcho.println(`\(commandName)`);readLine('');")
//        }
        if (!activeTextEditor.url.path.hasSuffix(".ui.py")) {
            await activeTextEditor.runnerView.executor?.evaluateCommands(parsedCommands)
            return
        }
        
//        if isPythonUIRunning {
//            await activeTextEditor.runnerView.executor?.evaluateCommands(["echo 请关闭其它解释器！"])
//            return
//        }
        
        isPythonUIRunning = true
        guard let executor = await activeTextEditor.runnerView.executor else {return}
        let ntidentifier = executor.persistentIdentifier
        guard let bookmark = try? executor.currentWorkingDirectory.bookmarkData() else  {return}
        guard let wbookmark = try? await URL(string: app.workSpaceStorage.currentDirectory.url ?? FileManager.default.currentDirectoryPath)!.bookmarkData() else {return}
        guard let libbookmark = try? ConstantManager.libraryURL.bookmarkData() else {return}
        let columns = executor.winsize.0
        let lines = executor.winsize.1
        let env = environmentAsArray()
        
        let config: [String: Any] = [
            "workingDirectoryBookmark": bookmark,
            "libraryBookmark": libbookmark,
            "commands": parsedCommands,
            "identifier": ntidentifier,
            "workspace": wbookmark,
            "COLUMNS": "\(columns)",
            "LINES": "\(lines)",
            "env": env,
        ]
        
//        let name = activeTextEditor.url.lastPathComponent.replacingFirstOccurrence(of: ".ui.py", with: "")
//        let uid = UUID().uuidString
//        let dir = ConstantManager.appGroupContainer.appendingPathComponent(uid)
//        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
//        let fileUrl = dir.appendingPathComponent("\(name).pyui")
//        NSKeyedArchiver.archiveRootObject(config, toFile: fileUrl.path)
//        let vc = await PYQLUIPreviewController(fileUrl, ntidentifier)
////        NotificationCen/*ter.default.post(name: Notification.Name("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": vc])*/
//        
//        DispatchQueue.main.async {
//            if #available(iOS 16.0, *) {
//                app.popupManager.showSheet(
//                    content: AnyView(VCRepresentable(
//                        vc
//                    ).presentationDetents([.height(400)]))
//                )
//            } else {
//                // Fallback on earlier versions
//            }
//        }
//        executor.evaluateCommands(["readremote"])
//        return
        
        
        let provider = NSItemProvider(item: "provider" as NSSecureCoding, typeIdentifier: "mh.pydeApp.pydeUI")
        let item = NSExtensionItem()
        item.attributedTitle = NSAttributedString(string: "This is title")
        item.accessibilityLabel = "run pyde ui"
        item.userInfo = config
        item.attachments = [provider]
        
        let url = activeTextEditor.url.appendingPathComponent("ui")
        
        
//        DispatchQueue.main.async {
//            let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
//            let instance = VCInTabEditorInstance(url: url, title: "ui: window", vc: vc)
//            app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
//        }
       
        
        DispatchQueue.main.async {
            app.popupManager.showSheet(
                content: AnyView(VCRepresentable(
                    UIActivityViewController(activityItems: [item], applicationActivities: nil)
                ))
            )
        }
        
        executor.evaluateCommands(["readremote"])
    }
}

class ConsoleInstance {
    let consoleView: ConsoleView
    
    var executor: pydeCommon.Executor? {
        return consoleView.executor
    }
    
    init(root: URL) {
        self.consoleView = ConsoleView(root: root)
    }
}


struct VCRepresentable: UIViewControllerRepresentable {

    private var vc: UIViewController

    init(_ vc: UIViewController) {
        self.vc = vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return vc
    }
}




class PYQLUIPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    let fileUrl: URL
    let identifier: String
    init(_ fileUrl: URL, _ identifier: String) {
        self.fileUrl = fileUrl
        self.identifier = identifier
        super.init(nibName: nil, bundle: nil)
        
        self.dataSource = self
        self.reloadData()
        
        self.preferredContentSize = CGSize(width: 800, height: 600)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func handleExit() {
        isPythonUIRunning = false
        let id = self.identifier
        wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_FORCE_EXIT)
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(200))) {
            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(id))
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }

    func previewController(
      _ controller: QLPreviewController,
      previewItemAt index: Int
    ) -> QLPreviewItem {
      return fileUrl as QLPreviewItem
    }
    
    
}
