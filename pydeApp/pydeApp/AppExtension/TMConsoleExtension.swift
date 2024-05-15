////
////  TMConsoleExtension.swift
////  pydeApp
////
////  Created by Huima on 2023/11/1.
////
//
//import SwiftUI
//import pyde
//
//class TMConsoleExtension: CodeAppExtension {
//    
//    var consoleInstance: ConsoleInstance?
//    
//    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
//        let root = URL(string: app.workSpaceStorage.currentDirectory.url) ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
//        consoleInstance = app.consoleInstance
//        let storage = Storage()
//        storage.consoleView = app.consoleInstance.consoleView
//        let panel = Panel(
//            labelId: "TERM",
//            mainView: AnyView(ConsoleWidget().environmentObject(storage)),
//            toolBarView: AnyView(ToolbarView())
//        )
//        contribution.panel.registerPanel(panel: panel)
//    }
//    
//    override func onWorkSpaceStorageChanged(newUrl: URL) {
//        self.consoleInstance?.consoleView.resetAndSetNewRootDirectory(url: newUrl)
//    }
//}
//
//private struct ToolbarView: View {
//    @EnvironmentObject var App: MainApp
//
//    var body: some View {
//        HStack(spacing: 12) {
//            Button(
//                action: {
//                    App.terminalInstance.sendInterrupt()
//                },
//                label: {
//                    Text("^C")
//                }
//            ).keyboardShortcut("c", modifiers: [.control])
//
//            Button(
//                action: {
//                    App.terminalInstance.reset()
//                },
//                label: {
//                    Image(systemName: "trash")
//                }
//            ).keyboardShortcut("k", modifiers: [.command])
//        }
//    }
//}
//
//private struct ConsoleWidget: View {
//    @EnvironmentObject var storage: Storage
//    @EnvironmentObject var App: MainApp
//    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
//
//    var body: some View {
//        if let wv = storage.consoleView {
//            ZStack {
//                ViewRepresentable(wv)
//                    .onAppear(perform: {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
////                            App.terminalInstance.executeScript("fitAddon.fit()")
////                            storage.consoleView?.readLine()
//                        }
//                    })
//            }
//            .foregroundColor(.clear)
//            .onChange(of: consoleFontSize) { value in
////                App.terminalInstance.setFontSize(size: value)
//            }
//        } else {
//            ProgressView()
//        }
//    }
//}
//
//private class Storage: ObservableObject {
//    weak var consoleView: ConsoleView?
//}
