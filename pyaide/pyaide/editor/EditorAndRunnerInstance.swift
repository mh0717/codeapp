//
//  EditorAndRunnerInstance.swift
//  Code
//
//  Created by Huima on 2023/5/24.
//

import Foundation
import SwiftUI

private class Storage: ObservableObject {
    weak var editorAndRunerView: EditorAndRunnerView?
    weak var editor: TextEditorInstance?
    weak var app: MainApp?
}

private struct PTKitEditorAndRunnerView: UIViewRepresentable {
    @EnvironmentObject var storage: Storage

    func makeUIView(context: Context) -> EditorAndRunnerView {
        let root = URL(string: storage.app?.workSpaceStorage.currentDirectory.url ?? "") ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let editorView = storage.editorAndRunerView ?? EditorAndRunnerView(root: root, editor: storage.editor!)
        return editorView
    }
    
    func updateUIView(_ view: EditorAndRunnerView, context: Context) {
        
    }

}

func createEditorAndRunnerInstance(url: URL, app: MainApp) async throws -> TextEditorInstance {
    let contentData: Data? = try await app.workSpaceStorage.contents(
        at: url
    )

    guard let contentData, let (content, encoding) = try? app.decodeStringData(data: contentData)
    else {
        throw AppError.unknownFileFormat
    }
    let attributes = try? await app.workSpaceStorage.attributesOfItem(at: url)
    let modificationDate = attributes?[.modificationDate] as? Date
    
    
    let root = URL(string: app.workSpaceStorage.currentDirectory.url) ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    
    let storage = Storage()
    storage.app = app
    
    let editorInstance = await RSCodeEditorInstance(editor: AnyView(PTKitEditorAndRunnerView().environmentObject(storage).id(UUID()).environmentObject(app)), url: url, content: content, encoding: encoding, lastSavedDate: modificationDate)
    editorInstance.app = app
    storage.editor = editorInstance
    
    let ptView = await EditorAndRunnerView(root: root, editor: editorInstance)
    storage.editorAndRunerView = ptView
    editorInstance.editorView = ptView
    
    editorInstance.codeRunHandler = {[weak editorInstance] (commands) in
        guard let editor = editorInstance else {return}
        guard let wview = editor.editorView as? EditorAndRunnerView else {
            return
        }
        guard let app = editor.app else {return}
        
        if !editor.url.path.hasSuffix(".ui.py") {
            DispatchQueue.main.async {
                if wview.consoleView.executor?.state == .idle {
                    wview.consoleView.executor?.evaluateCommands(commands)
                } else {
                    // show alert
                }
            }
            return
        }
        
        DispatchQueue.main.async {
            guard let bookmark = try? wview.consoleView.executor?.currentWorkingDirectory.bookmarkData() else  {return}
            guard let wbookmark = try? URL(string: editor.app?.workSpaceStorage.currentDirectory.url ?? FileManager.default.currentDirectoryPath)!.bookmarkData() else {return}
            let args = commands
            let ntidentifier = wview.consoleView.executor?.persistentIdentifier ?? "ntidentifier"
            let columns = wview.consoleView.executor?.winsize.0 ?? 48
            let lines = wview.consoleView.executor?.winsize.1 ?? 80
            
            let config: [String: Any] = [
                "workingDirectoryBookmark": bookmark,
                "args": ["python3", "-u", "\(editor.url.path)"],
                "identifier": ntidentifier,
                "workspace": wbookmark,
                "COLUMNS": "\(columns)",
                "LINES": "\(lines)",
            ]
            
            let item = NSExtensionItem()
            item.userInfo = config
//            let data = NSKeyedArchiver.archivedData(withRootObject: config)
            
            app.sheetManager.showSheet(content: AnyView(
                ActivityViewController(activityItems: [item])
            ))
        }
        
        
    }
    return editorInstance
}
