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
                    PYPanelView(currentPanelId: "RUNNER", windowHeight: geometry.size.height)
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
                labelId: "RUNNER",
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
                            Text("^C")
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

struct RunParamsView: View {
    @EnvironmentObject var App: MainApp
    @ObservedObject var codeThemeManager = rscodeThemeManager
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
    
    @State var lastArgs = ""
    @FocusState private var isFocused: Bool
    
    @State var showPlaceHolder = false
    
    var body: some View {
        TextEditor(text: Binding(get: {
            App.activeTextEditor?.runArgs ?? ""
        }, set: { value in
            App.activeTextEditor?.runArgs = value
            if value.isEmpty {
                showPlaceHolder = true
            } else {
                showPlaceHolder = false
            }
        }))
            .background(Color((colorScheme == .dark ? codeThemeManager.darkTheme : codeThemeManager.lightTheme).backgroundColor)) // To see this
            .focused($isFocused)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .font(.system(size: CGFloat(consoleFontSize)))
            .overlay(alignment: .topLeading, content: {
                Text(showPlaceHolder ? NSLocalizedString("Input run args", comment: "") : "")
                    .font(.system(size: CGFloat(consoleFontSize)))
                    .opacity(0.6)
                    .padding(7)
                    .disabled(true)
                    .allowsHitTesting(false)
            })
            .onAppear {
                if let args = App.activeTextEditor?.runArgs, !args.isEmpty {
                    showPlaceHolder = false
                } else {
                    showPlaceHolder = true
                }
            }
            .onChange(of: isFocused) { isFocused in
                guard let editor = App.activeTextEditor else {return}
                if isFocused {
                    lastArgs = editor.runArgs
                    return
                }
                if lastArgs == editor.runArgs {return}
                
                let fileName = editor.url.lastPathComponent
                let argsName = ".\(fileName).args"
                let argsUrl = editor.url.deletingLastPathComponent().appendingPathComponent(argsName)
                Task {
                    do {
                        guard let argsData = editor.runArgs.data(using: .utf8) else {return}
                        try await App.workSpaceStorage.write(at: argsUrl, content: argsData, atomically: true, overwrite: true)
                    } catch {
                        print(error)
                    }
                    
                }
            }
    }
}

