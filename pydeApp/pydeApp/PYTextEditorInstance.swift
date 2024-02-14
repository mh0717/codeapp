//
//  PYTextEditorInstance.swift
//  pydeApp
//
//  Created by Huima on 2023/11/2.
//

import Foundation
import SwiftUI
import pydeCommon
import pyde
import Combine

class PYTextEditorInstance: WithRunnerEditorInstance {
    
    let editor = RunestoneEditor()
    
    var editorView: RSCodeEditorView {
        return editor.editorView
    }
    
//    let runner = PYRunnerWidget()
//    
//    lazy var runnerWidget: AnyView = AnyView(runner.id(UUID()))
//    let codeWidget = PYCodeWidget()
//    
//    var runnerView: ConsoleView {
//        return runner.consoleView
//    }
    
//    var rangeCancellable: AnyCancellable?
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(
            url: url,
            content: content,
            encoding: encoding,
            lastSavedDate: lastSavedDate,
            editorView: AnyView(editor),
            fileDidChange: fileDidChange
        )
        
        editorView.text = content
//        runnerView.resetAndSetNewRootDirectory(url: url.deletingLastPathComponent())
        
//        rangeCancellable = $selectedRange.sink {[weak editorView] range in
//            guard let editorView else {return}
//            if editorView.selectedRange != range {
//                editorView.selectedRange = range
//                editorView.textView.goToLine(T##Int)
//            }
//        }
        
//        self.view = AnyView(VStack {
//            TagsIndicator(editor: self).environmentObject(self)
//            rseditor
//        }.environmentObject(self).id(UUID()))
    }
    
    func goToLine(_ line: Int) {
        editorView.goToLine(line)
    }
}


struct RunestoneEditor: UIViewRepresentable {
   
    
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @AppStorage("editorFontSize") var fontSize: Int = 14
    @AppStorage("editorFontFamily") var fontFamily: String = "Menlo"
    @AppStorage("fontLigatures") var fontLigatures: Bool = false
    @AppStorage("quoteAutoCompletionEnabled") var bracketCompletionEnabled: Bool = true
    @AppStorage("editorMiniMapEnabled") var miniMapEnabled: Bool = true
    @AppStorage("editorLineNumberEnabled") var editorLineNumberEnabled: Bool = true
    @AppStorage("editorShowKeyboardButtonEnabled") var editorShowKeyboardButtonEnabled: Bool = true
    @AppStorage("editorTabSize") var edtorTabSize: Int = 4
    @AppStorage("editorRenderWhitespace") var renderWhitespace: Int = 2
    @AppStorage("editorLightTheme") var editorLightTheme: String = "Default"
    @AppStorage("editorDarkTheme") var editorDarkTheme: String = "Default"
    @AppStorage("editorWordWrap") var editorWordWrap: String = "off"
    @AppStorage("preferredColorScheme") var preferredScheme: Int = 0
    @AppStorage("toolBarEnabled") var toolBarEnabled: Bool = true
    @AppStorage("editorSmoothScrolling") var editorSmoothScrolling: Bool = false
    @AppStorage("editorReadOnly") var editorReadOnly = false
//    @AppStorage("editorSpellCheckEnabled") var editorSpellCheckEnabled = false
//    @AppStorage("editorSpellCheckOnContentChanged") var editorSpellCheckOnContentChanged = true
    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    @SceneStorage("activeEditor.monaco.state") var activeEditorMonacoState: String?
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var codeThemeManager = rscodeThemeManager
    
    let editorView = RSCodeEditorView()
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, app: self.App)
    }
    
    
    func makeUIView(context: Context) -> RSCodeEditorView {
        updateUIView(editorView, context: context)
        return editorView
    }
    
    func updateUIView(_ uiView: RSCodeEditorView, context: Context) {
        editorView.textView.isEditable = !editorReadOnly
        editorView.textView.isLineWrappingEnabled = (editorWordWrap != "off")
        editorView.textView.showLineNumbers = editorLineNumberEnabled
        editorView.textView.tabSymbol = String(repeating: " ", count: edtorTabSize)
        if colorScheme == .dark {
            editorView.applyTheme(codeThemeManager.darkTheme)
        } else {
            editorView.applyTheme(codeThemeManager.lightTheme)
        }
        
    }
    
    class Coordinator: RSCodeEditorDelegate {
        
        
        var control: RunestoneEditor
        var App: MainApp

        init(_ control: RunestoneEditor, app: MainApp) {
            self.control = control
            self.App = app
            self.control.editorView.delegate = self
        }
        
        
        
        func onTextChanged(content: String) {
            if let editor = App.activeTextEditor {
                editor.currentVersionId += 1
                editor.content = content
            }
        }
        
        func onSelectionChanged(range: NSRange) {
            if let editor = App.activeTextEditor {
                editor.selectedRange = range
                
                let content = editor.content
                let position = min(editor.selectedRange.upperBound, content.count)
                var row: Int = 0
                var col: Int = 0
                let end = content.index(content.startIndex, offsetBy: position)
                let lines = content[..<end].components(separatedBy: "\n")
                row = lines.count
                col = lines.last?.count ?? 0
                
                NotificationCenter.default.post(
                    name: Notification.Name("monaco.cursor.position.changed"), object: nil,
                    userInfo: [
                        "lineNumber": row, "column": col,
                        "sceneIdentifier": control.App.sceneIdentifier,
                    ])
            }
        }
        
        func didBeginEditing() {
            let notification = Notification(
                name: Notification.Name("rseditor.focus"),
                userInfo: ["sceneIdentifier": control.App.sceneIdentifier]
            )
            NotificationCenter.default.post(notification)
        }
        
        func didEndEditing() {
            let notification = Notification(
                name: Notification.Name("rseditor.unfocus"),
                userInfo: ["sceneIdentifier": control.App.sceneIdentifier]
            )
            NotificationCenter.default.post(notification)
        }
        
        
    }
    
}


struct PYRunnerWidget: UIViewRepresentable {
    
    @EnvironmentObject var App: MainApp
    @ObservedObject var codeThemeManager = rscodeThemeManager
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let consoleView = ConsoleView(root: URL(fileURLWithPath:  FileManager.default.currentDirectoryPath))
    
    func makeUIView(context: Context) -> ConsoleView {
        return consoleView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
//        consoleView.terminalView.font = codeThemeManager.theme.font
        let theme = colorScheme == .dark ? codeThemeManager.darkTheme : codeThemeManager.lightTheme
        consoleView.backgroundColor = theme.backgroundColor
        consoleView.terminalView.backgroundColor = theme.backgroundColor
        consoleView.terminalView.nativeForegroundColor = theme.textColor
        consoleView.terminalView.nativeBackgroundColor = theme.backgroundColor
        consoleView.terminalView.selectedTextBackgroundColor = theme.markedTextBackgroundColor
    }
}



struct PYCodeWidget: View {
    
    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @EnvironmentObject var App: MainApp
    @AppStorage("setting.panel.hide.when.editor.focus") var shouldHidePanel: Bool = true
    
    let editor = RunestoneEditor()
    let runner = PYRunnerWidget()
    
    let panelManager = PanelManager()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                editor
                PYPanelView(currentPanelId: "RUNNER", windowHeight: geometry.size.height)
                    .environmentObject(panelManager)
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification),
            perform: { _ in
                if editor.editorView.textView.isEditing {
                    editor.editorView.textView.scrollRangeToVisible(editor.editorView.textView.selectedRange)
                }
        })
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("rseditor.focus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                if shouldHidePanel {
                    showsPanel = false
                }
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
                if shouldHidePanel && !showsPanel {
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
                        
                    Button(
                        action: {
                            _ = runner.consoleView.terminalView.resignFirstResponder()
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        },
                        label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    )
                })
            )
            panelManager.registerPanel(panel: runnerPanel)
        }
    }
}
