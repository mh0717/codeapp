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

class PYTextEditorInstance: TextEditorInstance {
    
    let rseditor = RunestoneEditor()
    
    var editorView: RSCodeEditorView {
        return rseditor.editorView
    }
    
    let runner = PYRunnerWidget()
    
    lazy var runnerWidget: AnyView = AnyView(runner.id(UUID()))
    
    var runnerView: ConsoleView {
        return runner.consoleView
    }
    
//    var rangeCancellable: AnyCancellable?
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(
            editor: rseditor.id(UUID()),
            url: url,
            content: content,
            encoding: encoding,
            lastSavedDate: lastSavedDate,
            fileDidChange: fileDidChange
        )
        
        rseditor.editorView.text = content
        runnerView.resetAndSetNewRootDirectory(url: url.deletingLastPathComponent())
        
//        rangeCancellable = $selectedRange.sink {[weak editorView] range in
//            guard let editorView else {return}
//            if editorView.selectedRange != range {
//                editorView.selectedRange = range
//                editorView.textView.goToLine(<#T##Int#>)
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
    @AppStorage("editorSpellCheckEnabled") var editorSpellCheckEnabled = false
    @AppStorage("editorSpellCheckOnContentChanged") var editorSpellCheckOnContentChanged = true
    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    @SceneStorage("activeEditor.monaco.state") var activeEditorMonacoState: String?
    
    let editorView = RSCodeEditorView()
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, app: self.App)
    }
    
    
    func makeUIView(context: Context) -> RSCodeEditorView {
        return editorView
    }
    
    func updateUIView(_ uiView: RSCodeEditorView, context: Context) {
        
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
        
        func didEndEditing() {
            
        }
        
        
    }
    
}


struct PYRunnerWidget: UIViewRepresentable {
    
    @EnvironmentObject var App: MainApp
    
    let consoleView = ConsoleView(root: URL(fileURLWithPath:  FileManager.default.currentDirectoryPath))
    
    func makeUIView(context: Context) -> ConsoleView {
        return consoleView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}


