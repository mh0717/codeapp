//
//  PYRunnerExtension.swift
//  pydeApp
//
//  Created by Huima on 2023/11/2.
//

import SwiftUI
import SwiftTerm
import ios_system
import pyde

class PYRunnerExtension: CodeAppExtension {
    
    var consoleInstance: ConsoleView?
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let panel = Panel(
            labelId: "RUNNER",
            mainView: AnyView(
                ConsoleWidget()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        GeometryReader{ proxy in
                            let size = proxy.size
                            Color.clear
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
        
        consoleInstance = app.pyapp.consoleInstance
        if let url = app.workSpaceStorage.currentDirectory._url {
            consoleInstance?.resetAndSetNewRootDirectory(url: url)
        }
        
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        consoleInstance?.resetAndSetNewRootDirectory(url: newUrl)
    }
    
    func handleRunnerSizeChanged(_ size: CGSize) {
        
    }
}

fileprivate var consoleCount = 0

private struct ToolbarView: View {
    @EnvironmentObject var App: MainApp
    
    var body: some View {
        HStack(spacing: 12) {
            Menu {
                Button("Close", systemImage: "apple.terminal", role: .destructive) {
                    App.pyapp.consoles.removeAll(where: {$0.id == App.pyapp.activeConsole.id})
                    App.pyapp.activeConsole = App.pyapp.consoles.last ?? App.pyapp.defaultConsole
                }
                
                Button("New Terminal", systemImage: "plus") {
                    consoleCount += 1
                    let title = NSLocalizedString("Terminal", comment: "") + "#\(consoleCount)"
                    let console = PYRunnerWidget()
                    console.consoleView.title = title
                    App.pyapp.consoles.append(console)
                    App.pyapp.activeConsole = console
                }
                
                Divider()
                
                Button("Terminal", systemImage: App.pyapp.activeConsole.id == App.pyapp.defaultConsole.id ? "checkmark.circle" : "") {
                    App.pyapp.activeConsole = App.pyapp.defaultConsole
                }.background(Color.red)
                
                ForEach(App.pyapp.consoles, id: \.consoleView, content: { item in
                    Button(item.consoleView.title ?? "", systemImage: item.id == App.pyapp.activeConsole.id ? "checkmark.circle" : "") {
                        App.pyapp.activeConsole = item
                    }
                })
            } label: {
                Image(systemName: "ellipsis").padding(2)
            }

            Button(
                action: {
                    if let editor = App.activeEditor as? WithRunnerEditorInstance {
                        editor.runnerView.kill()
                    } else {
                        App.pyapp.consoleInstance.kill()
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
        if let editor = App.activeEditor as? WithRunnerEditorInstance {
            editor.runner.id(editor.id)
        } else {
            App.pyapp.activeConsole.id(App.pyapp.activeConsole.id)
        }
    }
}
