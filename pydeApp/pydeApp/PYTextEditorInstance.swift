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

class PYTextEditorInstance: TextEditorInstance, RSCodeEditorDelegate {
    @Published var tags: [CTag] = []
    
    func onTextChanged(content: String) {
//        let version = result["VersionID"] as! Int
//        let content = result["currentContent"] as! String
//        control.App.activeTextEditor?.currentVersionId = version
//        control.App.activeTextEditor?.content = content
//
//        let modelUri = result["URI"] as! String
//        requestDiffUpdate(modelUri: modelUri)
//
//        let startOffset = result["startOffset"] as! Int
//        let endOffset = result["endOffset"] as! Int
//        if control.editorSpellCheckEnabled && control.editorSpellCheckOnContentChanged {
//            control.checkSpelling(
//                text: content, uri: modelUri, startOffset: startOffset, endOffset: endOffset
//            )
        self.content = content
        currentVersionId += 1
        
        Task.init {[weak self] in
            if let self, let tags = await requestCTagsService(url.path, content: content) {
                await MainActor.run {
                    self.tags = tags
                }
            }
        }
    }
    
    func didEndEditing() {
        
    }
    
    let rseditor = RunestoneEditor()
    
    var editorView: RSCodeEditorView {
        return rseditor.editorView
    }
    
    let runner = PYRunnerWidget()
    
    lazy var runnerWidget: AnyView = AnyView(runner.id(UUID()))
    
    var runnerView: ConsoleView {
        return runner.consoleView
    }
    
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
        rseditor.editorView.delegate = self
        runnerView.resetAndSetNewRootDirectory(url: url.deletingLastPathComponent())
        
        Task.init {[weak self] in
            if let self, let tags = await requestCTagsService(url.path, content: content) {
                await MainActor.run {
                    self.tags = tags
                    self.objectWillChange.send()
                }
            }
        }
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
    
    
    
    func makeUIView(context: Context) -> RSCodeEditorView {
        return editorView
    }
    
    func updateUIView(_ uiView: RSCodeEditorView, context: Context) {
        
    }
    
//    class Coordinator: NSObject, RSCodeEditorDelegate {
//        var control: RunestoneEditor
//        var env: MainApp
//
//        init(_ control: RunestoneEditor, env: MainApp) {
//            self.control = control
//            self.env = env
//            super.init()
//        }
//        
//        func onTextChanged(content: String) {
//            if let editor = env.activeTextEditor {
//                editor.currentVersionId += 1
//                editor.content = content
//            }
//        }
//        
//        func didEndEditing() {
//            
//        }
//        
//        
//    }
    
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


