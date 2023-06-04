//
//  PTEditorInstance.swift
//  pyaide
//
//  Created by Huima on 2023/5/9.
//

import Foundation
import SwiftUI



private class Storage: ObservableObject {
    @Published var isLoading: Bool = true
    weak var editorView: PTCodeTextView?
    weak var editor: TextEditorInstance?
}

private struct PTKitEditorView: UIViewRepresentable {
    @EnvironmentObject var storage: Storage

    func makeUIView(context: Context) -> PTCodeTextView {
        let editorView = storage.editorView ?? PTCodeTextView(frame: .zero, editor: storage.editor!)
        return editorView
    }
    func updateUIView(_ view: PTCodeTextView, context: Context) {
        
    }

}

class PTTextEditorInstance: TextEditorInstance {
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
    
    var app: MainApp?
    var editorView: UIView?
}

func createPTEidtorInstance(url: URL, app: MainApp) async throws -> TextEditorInstance {
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
    let ptView = await PTCodeTextView(frame: .zero, editor: editorInstance)
    storage.editorView = ptView
    editorInstance.editorView = ptView
    return editorInstance
}


//class TextEditorInstance: EditorInstanceWithURL {
//    @Published var lastSavedVersionId = 1
//    @Published var currentVersionId = 1
//
//    var content: String
//    var encoding: String.Encoding = .utf8
//    var isDeleted = false
//    var lastSavedDate: Date? = nil
//
//    var languageIdentifier: String {
//        url.pathExtension
//    }
//    var isSaved: Bool {
//        lastSavedVersionId == currentVersionId
//    }
//    var isSaving: Bool = false
//
//    init(
//        editor: MonacoEditor,
//        url: URL,
//        content: String,
//        encoding: String.Encoding = .utf8,
//        lastSavedDate: Date? = nil,
//        fileDidChange: ((FileState, String?) -> Void)? = nil
//    ) {
//        self.content = content
//        self.encoding = encoding
//        self.lastSavedDate = lastSavedDate
//        super.init(view: AnyView(editor), title: url.lastPathComponent, url: url)
//
//        // Disable this until #722 is fixed.
//
//        // self.fileWatch?.folderDidChange = { [weak self] lastModified in
//        //     guard let self = self else { return }
//
//        //     guard let content = try? String(contentsOf: url, encoding: self.encoding) else {
//        //         return
//        //     }
//
//        //     DispatchQueue.main.async {
//        //         if !self.isSaving, self.isSaved,
//        //             lastModified > self.lastSavedDate ?? Date.distantFuture
//        //         {
//        //             self.content = content
//        //             self.lastSavedDate = lastModified
//        //             fileDidChange?(.modified, content)
//        //         }
//        //     }
//        // }
//        // self.fileWatch?.startMonitoring()
//    }
//}
