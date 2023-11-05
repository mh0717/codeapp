//
//  PYRunnerExtension.swift
//  pydeApp
//
//  Created by Huima on 2023/11/2.
//

import SwiftUI
import SwiftTerm
import ios_system

class PYRunnerExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let root = URL(string: app.workSpaceStorage.currentDirectory.url) ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        let panel = Panel(
            labelId: "RUNNER",
            mainView: AnyView(
                ConsoleWidget()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        GeometryReader{ proxy in
                            let size = proxy.size
                            Color.red
                                .onAppear{
                                    NotificationCenter.default.post(name: .init("panel.size.changed"), object: size)
                                    print("size: \(size)")
                                }
                                .onChange(of: size) { newValue in
                                    NotificationCenter.default.post(name: .init("panel.size.changed"), object: size)
                                    print("wsize: \(newValue)")
                                }
                        }
                    )
            ),
            toolBarView: AnyView(ToolbarView())
        )
        contribution.panel.registerPanel(panel: panel)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        
    }
    
    func handleRunnerSizeChanged(_ size: CGSize) {
        
    }
}

private struct ToolbarView: View {
    @EnvironmentObject var App: MainApp
    
    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    if let editor = App.activeEditor as? PYTextEditorInstance {
                        editor.runnerView.kill()
                    }
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
