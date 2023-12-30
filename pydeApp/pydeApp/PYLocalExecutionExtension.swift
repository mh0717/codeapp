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
        
        guard let executor = await activeTextEditor.runnerView.executor else {return}
        let ntidentifier = executor.persistentIdentifier
        guard let bookmark = try? executor.currentWorkingDirectory.bookmarkData() else  {return}
        guard let wbookmark = try? await URL(string: app.workSpaceStorage.currentDirectory.url ?? FileManager.default.currentDirectoryPath)!.bookmarkData() else {return}
        let columns = executor.winsize.0
        let lines = executor.winsize.1
        
        let config: [String: Any] = [
            "workingDirectoryBookmark": bookmark,
            "commands": parsedCommands,
            "identifier": ntidentifier,
            "workspace": wbookmark,
            "COLUMNS": "\(columns)",
            "LINES": "\(lines)",
        ]
        
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
