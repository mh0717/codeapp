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
import pydeCommon
import AVKit


class PYRunnerExtension: CodeAppExtension, PictureInPictureDelegate {
    func didEnterPictureInPicture() {
        isPipPlaying = true
        
        app?.pyapp.defaultConsole.consoleView.onChanged = onConsoleChanged
        
        var _updateCount = 0
        pipTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
            _updateCount += 1
            if self._consoleChanged {
                self._consoleChanged = false
                self.app?.pyapp.defaultConsole.consoleView.updatePictureInPictureSnapshot()
            }
            
            if _updateCount >= 50 {
                _updateCount = 0
                self._consoleChanged = false
                self.app?.pyapp.defaultConsole.consoleView.updatePictureInPictureSnapshot()
            }
        })
    }
    
    func didExitPictureInPicture() {
        isPipPlaying = false
        pipTimer?.invalidate()
        pipTimer = nil
        app?.pyapp.defaultConsole.consoleView.onChanged = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func didFailToEnterPictureInPicture(error: any Error) {
        print(error.localizedDescription)
    }
    
    func didPause() {
        isPipPlaying = false
    }
    
    func didResume() {
        isPipPlaying = true
    }
    
    var isPlaying: Bool {
        return isPipPlaying
    }
    
    private var isPipPlaying = false
    
    
    weak var app: MainApp?
    
    var pipTimer: Timer?
    private var _consoleChanged = false
    private func onConsoleChanged(_ console: ConsoleView) {
        _consoleChanged = true
    }
    
    private func handlePipPlay() {
        guard let app else {
            return
        }
        if app.pyapp.defaultConsole.consoleView.pictureInPictureController?.isPictureInPictureActive == false {
            
            // Start an audio session and PIP
            app.pyapp.defaultConsole.consoleView.updatePictureInPictureSnapshot()
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true, options: [])
            } catch {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                app.pyapp.defaultConsole.consoleView.pictureInPictureController?.startPictureInPicture()
            }
            
        } else {
            
            // Stop PIP
            pipTimer?.invalidate()
            pipTimer = nil
            app.pyapp.defaultConsole.consoleView.onChanged = nil
            app.pyapp.defaultConsole.consoleView.pictureInPictureController?.stopPictureInPicture()
        }
    }
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let panel = Panel(
            labelId: "TERMINAL",
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
            toolBarView: AnyView(ToolbarView(onPipPlay: handlePipPlay))
        )
        contribution.panel.registerPanel(panel: panel)
        
        let consoleInstance = app.pyapp.consoleInstance
        if let url = app.workSpaceStorage.currentDirectory._url {
            consoleInstance.resetAndSetNewRootDirectory(url: url)
        }
        self.app = app
        app.pyapp.defaultConsole.consoleView.pictureInPictureDelegate = self
        
        NotificationCenter.default.addObserver(forName: .init("RUN_ROMOTE_COMMAND_IN_LOCAL_CONSOLE"), object: nil, queue: .main) { notify in
            guard let info = notify.userInfo?["info"] as? [String: Any] else {
                return
            }
            
            consoleCount += 1
            let title = NSLocalizedString("Terminal", comment: "") + "#\(consoleCount)"
            let console = PYRunnerWidget()
            console.consoleView.title = title
            app.pyapp.consoles.append(console)
            app.pyapp.activeConsole = console
            let parsedCommands = info["commands"] as? [String] ?? ["commands"]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let compilerShowPath = UserDefaults.standard.bool(forKey: "compilerShowPath")
                if compilerShowPath {
                    console.consoleView.feed(text: parsedCommands.joined(separator: " && "))
                } else {
                    let commandName = parsedCommands.first?.components(separatedBy: " ").first ?? "command"
                    console.consoleView.feed(text: commandName)
                }
                console.consoleView.feed(text: "\r\n")
                
                console.consoleView.executor.dispatchBlock(command: {clientReqCommands(info: info)}, name: parsedCommands.joined(separator: " "))
            }
        }
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        app?.pyapp.defaultConsole.consoleView.resetAndSetNewRootDirectory(url: newUrl)
        app?.pyapp.consoles.forEach({item in
            item.consoleView.resetAndSetNewRootDirectory(url: newUrl)
        })
    }
    
    func handleRunnerSizeChanged(_ size: CGSize) {
        
    }
    
    private static var _hasRunSplitCommand = false
}

fileprivate var consoleCount = 0

private struct ToolbarView: View {
    @EnvironmentObject var App: MainApp
    
    var onPipPlay: (()->Void)
    
    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    if let editor = App.activeEditor as? WithRunnerEditorInstance {
                        editor.runnerView.kill()
                    } else {
                        App.pyapp.consoleInstance.kill()
                    }
                },
                label: {
                    Image(systemName: "stop").frame(width: 25, height: 20)
                }
            )
            .contentShape(Rectangle())
            .keyboardShortcut("c", modifiers: [.control])
            
            if AVPictureInPictureController.isPictureInPictureSupported() {
                Button(
                    action: {
                        onPipPlay()
                    },
                    label: {
                        Image(systemName: "pip").frame(width: 25, height: 20)
                    }
                )
                .contentShape(Rectangle())
                .keyboardShortcut("c", modifiers: [.control])
            }
            
            Menu {
                
                Button("Clear", systemImage: "trash", role: .none) {
                    App.pyapp.activeConsole.consoleView.clear()
                }
                
                Divider()
                
                Button("Run Pasteboard", systemImage: "play", role: .none) {
                    if let script = UIPasteboard.general.string, !script.isEmpty {
                        runString(app: App, script: script)
                    }
                }
                
                Divider()
                
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
                Image(systemName: "ellipsis").frame(width: 25, height: 20)
            }.contentShape(Rectangle())
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


