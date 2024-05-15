//
//  WithRunnerEditorInstance.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import Foundation
import SwiftUI
import pyde

class WithRunnerEditorInstance: TextEditorInstance {
    
    let runner = PYRunnerWidget()
      
    var runnerView: ConsoleView {
        return runner.consoleView
    }
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        editorView: AnyView,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(
            editor: EditorAndRunnerWidget(editor: editorView, runner: runner).id(UUID()),
            url: url,
            content: content,
            encoding: encoding,
            lastSavedDate: lastSavedDate,
            fileDidChange: fileDidChange
        )
        
        runnerView.resetAndSetNewRootDirectory(url: url.deletingLastPathComponent())
    }
    
    override func dispose() {
        super.dispose()
        runnerView.kill()
        runnerView.clear()
        runnerView.removeFromSuperview()
    }
    
    #if DEBUG
    deinit {
        print("withrunnerEditorInstance deinit")
    }
    #endif
}





struct EditorAndRunnerWidget: View {
    
    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @EnvironmentObject var App: MainApp
    @AppStorage("setting.panel.hide.when.editor.focus") var shouldHidePanel: Bool = true
    
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
    
    @AppStorage("setting.panel.global.show") var showGlobalPanel = true
    
    @State var restoreShowPanel = false
    @State var isEditing = false
    
    let editor: AnyView
    let runner: PYRunnerWidget
    
    let panelManager = PanelManager()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                editor
                if !showGlobalPanel {
                    PYPanelView(currentPanelId: "TERMINAL", windowHeight: geometry.size.height)
                        .environmentObject(panelManager)
                }
            }
        }
//        .onReceive(
//            NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification),
//            perform: { _ in
//                if editor.editorView.textView.isEditing {
//                    editor.editorView.textView.scrollRangeToVisible(editor.editorView.textView.selectedRange)
//                }
//        })
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillShowNotification),
            perform: { notification in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, keyboardFrame.size.height > 150  else {
                    return
                }
                
                restoreShowPanel = false
                if isEditing {
                    if shouldHidePanel && showsPanel {
                        showsPanel = false
                        restoreShowPanel = true
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(50))) {
                        if isEditing && shouldHidePanel && showsPanel {
                            showsPanel = false
                            restoreShowPanel = true
                        }
                    }
                }
            })
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification), perform: { notification in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, keyboardFrame.size.height > 150 else {
                    return
                }
                if isEditing && !restoreShowPanel && shouldHidePanel && showsPanel {
                    showsPanel = false
                    restoreShowPanel = true
                }
            })
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification), perform: { _ in
                isEditing = false
            })
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("rseditor.focus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                isEditing = true
            }
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("editor.focus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                isEditing = true
            }
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("rseditor.unfocus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                isEditing = false
                if shouldHidePanel && restoreShowPanel && !showsPanel {
                    showsPanel = true
                }
            }
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("editor.unfocus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                if shouldHidePanel && restoreShowPanel && !showsPanel {
                    showsPanel = true
                }
            }
        )
        .onAppear {
            if !panelManager.panels.isEmpty {
                return
            }
            let runnerPanel = Panel(
                labelId: "TERMINAL",
                mainView: AnyView(
                    runner
                ),
                toolBarView: AnyView(
                    HStack(spacing: 12) {
                    Button(
                        action: {
                            runner.consoleView.kill()
                        },
                        label: {
                            Image(systemName: "stop")
                        }
                    ).keyboardShortcut("c", modifiers: [.control])

                    Button(
                        action: {
                            runner.consoleView.clear()
                        },
                        label: {
                            Image(systemName: "trash")
                        }
                    ).keyboardShortcut("k", modifiers: [.command])
                        
//                    Button(
//                        action: {
//                            _ = runner.consoleView.terminalView.resignFirstResponder()
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        },
//                        label: {
//                            Image(systemName: "keyboard.chevron.compact.down")
//                        }
//                    )
                })
            )
            panelManager.registerPanel(panel: runnerPanel)
            
            let paramsPanel = Panel(
                labelId: "ARGS",
                mainView: AnyView(
                    RunParamsView()
                ),
                toolBarView: AnyView(
                    HStack(spacing: 12) {
                })
            )
            panelManager.registerPanel(panel: paramsPanel)
        }
        .onDisappear() {
            panelManager.panels.removeAll()
        }
    }
}

