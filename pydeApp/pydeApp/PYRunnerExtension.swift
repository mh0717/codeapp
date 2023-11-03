//
//  PYRunnerExtension.swift
//  pydeApp
//
//  Created by Huima on 2023/11/2.
//

import SwiftUI
import SwiftTerm

class PYRunnerExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let root = URL(string: app.workSpaceStorage.currentDirectory.url) ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        let panel = Panel(
            labelId: "RUNNER",
            mainView: AnyView(ConsoleWidget()),
            toolBarView: AnyView(ToolbarView())
        )
        contribution.panel.registerPanel(panel: panel)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        
    }
}

private struct ToolbarView: View {
    @EnvironmentObject var App: MainApp

    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    App.terminalInstance.sendInterrupt()
                },
                label: {
                    Text("^C")
                }
            ).keyboardShortcut("c", modifiers: [.control])

            Button(
                action: {
                    App.terminalInstance.reset()
                },
                label: {
                    Image(systemName: "trash")
                }
            ).keyboardShortcut("k", modifiers: [.command])
        }
    }
}

private struct ConsoleWidget: View {
    @EnvironmentObject var App: MainApp
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14

    var body: some View {
        if let editor = $App.activeEditor.wrappedValue as? PYTextEditorInstance {
            editor.runnerWidget
        } else {
            ProgressView()
        }
    }
}
