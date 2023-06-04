//
//  RSCodeEditorInstance.swift
//  Code
//
//  Created by Huima on 2023/5/22.
//

import Foundation
import SwiftUI

private class Storage: ObservableObject {
    weak var editorView: RSCodeEditorView?
    weak var editor: TextEditorInstance?
}

private struct PTKitEditorView: UIViewRepresentable {
    @EnvironmentObject var storage: Storage

    func makeUIView(context: Context) -> RSCodeEditorView {
        let editorView = storage.editorView ?? RSCodeEditorView(editor: storage.editor!)
        return editorView
    }
    
    func updateUIView(_ view: RSCodeEditorView, context: Context) {
        
    }

}

typealias CodeRunHandler = ([String]) -> Void
class RSCodeEditorInstance: TextEditorInstance {
    override init(
        editor: AnyView,
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(editor: editor, url: url, content: content, encoding: encoding, lastSavedDate: lastSavedDate, fileDidChange: fileDidChange)
    }
    
    weak var app: MainApp?
    var codeRunHandler: CodeRunHandler?
    var editorView: UIView?
    
    deinit {
        print("instance deinit")
    }
}

func createRSCodeEditorInstance(url: URL, app: MainApp) async throws -> TextEditorInstance {
    let contentData: Data? = try await app.workSpaceStorage.contents(
        at: url
    )

    guard let contentData, let (content, encoding) = try? app.decodeStringData(data: contentData)
    else {
        throw AppError.unknownFileFormat
    }
    let attributes = try? await app.workSpaceStorage.attributesOfItem(at: url)
    let modificationDate = attributes?[.modificationDate] as? Date
    
    
    let storage = Storage()
    let editorInstance = await PTTextEditorInstance(editor: AnyView(PTKitEditorView().environmentObject(storage).id(UUID())), url: url, content: content, encoding: encoding, lastSavedDate: modificationDate)
    editorInstance.app = app
    storage.editor = editorInstance
    let ptView = await RSCodeEditorView(editor: editorInstance)
    storage.editorView = ptView
    editorInstance.editorView = ptView
    return editorInstance
}
