//
//  LocalExecutionExtension.swift
//  Code
//
//  Created by Ken Chung on 19/11/2022.
//

import Foundation
import SwiftUI

private let EXTENSION_ID = "PTLOCAL_EXECUTION"

private let LOCAL_EXECUTION_COMMANDS = [
    "py": ["python3 -u {url}"],
    "js": ["node {url}"],
    "c": ["clang {url}", "wasm a.out"],
    "cpp": ["clang++ {url}", "wasm a.out"],
    "php": ["php {url}"],
]

class PTLocalExecutionExtension: CodeAppExtension {
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
//            panelToFocusOnTap: "TERMINAL",
            shouldDisplay: {
                guard let activeTextEditor = app.activeTextEditor else { return false }
                return activeTextEditor.url.isFileURL
                    && LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] != nil
            }
        )
        contribution.toolbarItem.registerItem(item: toolbarItem)
    }

    private func runCodeLocally(app: MainApp) async {
        

        guard let activeTextEditor = app.activeTextEditor else {
            return
        }
        
        guard let textEditor = activeTextEditor as? RSCodeEditorInstance else {
            return
        }
        
        guard let codeRunner = textEditor.codeRunHandler else {
            return
        }
        
        await app.saveCurrentFile()

        guard var commands = LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] else {
            return
        }
        
//        if (textEditor.url.path.hasSuffix(".ui.py")) {
//            commands = ["python3ui -u {url}"]
//        }

        

        let sanitizedUrl = activeTextEditor.url.path.replacingOccurrences(of: " ", with: #"\ "#)
        var parsedCommands = commands.map {
            $0.replacingOccurrences(of: "{url}", with: sanitizedUrl)
        }

        let compilerShowPath = UserDefaults.standard.bool(forKey: "compilerShowPath")
        if compilerShowPath {
//            app.terminalInstance.executeScript(
//                "localEcho.println(`\(parsedCommands.joined(separator: " && "))`);readLine('');")
            let echo = "echo \(parsedCommands.joined(separator: " && "))"
            parsedCommands.insert(echo, at: 0)
        } else {
            let commandName =
                parsedCommands.first?.components(separatedBy: " ").first
                ?? activeTextEditor.languageIdentifier
//            app.terminalInstance.executeScript("localEcho.println(`\(commandName)`);readLine('');")
            parsedCommands.insert("echo \(commandName)", at: 0)
        }
//        app.terminalInstance.executor?.evaluateCommands(parsedCommands)
        codeRunner(parsedCommands)
    }
}

struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}
