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

class PYPlainTextEditorInstance: TextEditorInstance {
    let editor = RunestoneEditor()
    
    var editorView: RSCodeEditorView {
        return editor.editorView
    }
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(
            editor: AnyView(editor).id(UUID()),
            url: url,
            content: content,
            encoding: encoding,
            lastSavedDate: lastSavedDate,
            fileDidChange: fileDidChange
        )
        
        editorView.text = content
        editorView.url = url
    }
    
    func goToLine(_ line: Int) {
        editorView.goToLine(line)
    }
}


class PYTextEditorInstance: WithRunnerEditorInstance {
    
    let editor = RunestoneEditor()
    
    var editorView: RSCodeEditorView {
        return editor.editorView
    }
    
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
        editorView.url = url
    }
    
    func goToLine(_ line: Int) {
        editorView.goToLine(line)
    }
    
    override func dispose() {
        super.dispose()
        
        editorView.removeFromSuperview()
    }
    
    #if DEBUG
    deinit {
        print("textEditorInstance edinit")
    }
    #endif
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
    @AppStorage("editorRenderWhitespace") var renderWhitespace: Int = 0
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
    
    var text: String? = nil
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, app: self.App)
    }
    
    
    func makeUIView(context: Context) -> RSCodeEditorView {
        if editorView.text.count == 0, let text {
            editorView.text = text
        }
        updateUIView(editorView, context: context)
        return editorView
    }
    
    func updateUIView(_ uiView: RSCodeEditorView, context: Context) {
        editorView.textView.isEditable = !editorReadOnly
        if let editor = App.activeTextEditor {
            if editor.readOnly {
                editorView.textView.isEditable = false
            }
        }
        editorView.textView.isLineWrappingEnabled = (editorWordWrap != "off")
        editorView.textView.lineBreakMode = .byWordWrapping
        editorView.textView.showLineNumbers = editorLineNumberEnabled
        editorView.textView.tabSymbol = String(repeating: " ", count: edtorTabSize)
        editorView.enableCharactorPair = bracketCompletionEnabled
        if renderWhitespace == 0 {
            editorView.textView.showSpaces = false
            editorView.textView.showTabs = false
            editorView.textView.showLineBreaks = false
        } else {
            editorView.textView.showSpaces = true
            editorView.textView.showTabs = true
            editorView.textView.showLineBreaks = true
        }
        if colorScheme == .dark {
            editorView.applyTheme(codeThemeManager.darkTheme)
        } else {
            editorView.applyTheme(codeThemeManager.lightTheme)
        }
        
    }
    
    static func dismantleUIView(_ uiView: RSCodeEditorView, coordinator: Coordinator) {
        print("dismantleUIView rseditorview")
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


var PYDE_IMAGE_COUNT = 0

struct PYRunnerWidget: UIViewRepresentable {
    let id: UUID = UUID()
    
    @EnvironmentObject var App: MainApp
    @ObservedObject var codeThemeManager = rscodeThemeManager
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    func onOpenLink(_ url: String) {
        if let url = URL(string: url) {
            App.pyapp.openUrl(url)
        }
    }
    
    func onOpenImage(_ image: UIImage) {
//        let editor = EditorInstance(view: AnyView(Image(uiImage: image).resizable().scaledToFit().id(UUID())), title: "Image")
        PYDE_IMAGE_COUNT += 1
        let editor = PYImageEditorInstance(image: image, title: "Image#\(PYDE_IMAGE_COUNT)")
        App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
    }
    
    let consoleView = ConsoleView(root: URL(fileURLWithPath:  FileManager.default.currentDirectoryPath))
    
    func makeUIView(context: Context) -> ConsoleView {
        consoleView.onOpenLink = onOpenLink
        consoleView.onOpenImage = onOpenImage
        return consoleView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
//        consoleView.terminalView.font = codeThemeManager.theme.font
        let theme = colorScheme == .dark ? codeThemeManager.darkTheme : codeThemeManager.lightTheme
        consoleView.backgroundColor = UIColor(id: "editor.background")
        consoleView.terminalView.backgroundColor = theme.backgroundColor
        consoleView.terminalView.nativeForegroundColor = ThemeManager.isDark() ? UIColor.white : UIColor.black
        consoleView.terminalView.nativeBackgroundColor = UIColor(id: "editor.background")
        consoleView.terminalView.selectedTextBackgroundColor = UIColor(id: "editor.background").blendAlpha(coverColor: theme.markedTextBackgroundColor.withAlphaComponent(0.4)) 
//        consoleView.terminalView.selectedTextBackgroundColor =  theme.markedTextBackgroundColor.blendAlpha(coverColor: UIColor(id: "editor.background"))
    }
    
}