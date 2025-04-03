//
//  NBPreviewExtension.swift
//  pydeApp
//
//  Created by Huima on 2024/2/12.
//

import SwiftUI
import UIKit
import pydeCommon
import pyde
import SwiftyJupyter

//class PYPlainTextEditorInstance: TextEditorInstance {
//    let editor = RunestoneEditor()
//    
//    var editorView: RSCodeEditorView {
//        return editor.editorView
//    }
//    
//    init(
//        url: URL,
//        content: String,
//        encoding: String.Encoding = .utf8,
//        lastSavedDate: Date? = nil,
//        fileDidChange: ((FileState, String?) -> Void)? = nil
//    ) {
//        super.init(
//            editor: AnyView(editor).id(UUID()),
//            url: url,
//            content: content,
//            encoding: encoding,
//            lastSavedDate: lastSavedDate,
//            fileDidChange: fileDidChange
//        )
//        
//        editorView.text = content
//        editorView.url = url
//    }
//    
//    func goToLine(_ line: Int) {
//        editorView.goToLine(line)
//    }
//}



class NoteBookEditorInstance: TextEditorInstance {
    
    fileprivate var notebook: NotebookModel?
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(editor: AnyView(EmptyView()), url: url, content: content, lastSavedDate: lastSavedDate, fileDidChange: fileDidChange)
        
        let connFile = ConstantManager.appGroupContainer.appending(path: url.path.crc32Hex() + ".json").path
        let contentBinding = Binding<String>(
            get: {
                self.content
            }, set: {value in
                self.currentVersionId += 1
                self.content = value
            }
        )
        notebook = NotebookModel(fileUrl: url, content: contentBinding, connFile: connFile)
        let view = NotebookView(notebook: notebook!)
        self.view = AnyView(view)
        
        self.keepAlive = true
    }
    
    override func onPlay() {
        notebook?.startKernel(startServer: false)
    }
    
    override func dispose() {
        notebook?.stopKernel()
    }
    
}




class NoteBookPreviewExtension: CodeAppExtension {
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let addItem = ToolbarItem(
            extenionID: "NOTEBOOK",
            icon: "plus",
            onClick: {
                guard let editor = app.activeEditor as? NoteBookEditorInstance else {
                    return
                }
                
                DispatchQueue.main.async {
                    editor.notebook?.addCodeCell()
                }
            },
            shouldDisplay: {
                guard let editor = app.activeEditor as? EditorInstanceWithURL, editor.url.pathExtension.lowercased() == "ipynb"  else {
                    return false
                }
                return true
            }
        )
        
        
        contribution.toolBar.registerItem(item: addItem)

    }
    
    
}




private var nbtemplate: String?

struct NoteBookViewReprestable: UIViewRepresentable {
    
    let webView: WKWebView = WebViewBase()
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}

class NoteBookPreviewEditorInstance: EditorInstanceWithURL  {
    let webViewRepresent = NoteBookViewReprestable()
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(view: AnyView(webViewRepresent), title: url.lastPathComponent, url: url)
        
        loadNBContent(nbContent: content)
    }

    func loadNBContent(nbContent: String) {
        if nbtemplate == nil {
            nbtemplate = try? String(contentsOf: ConstantManager.NBTEMPLATE_URL)
        }
        let htmlString = nbtemplate?.replacingOccurrences(of: "%nbcontent%", with: nbContent)
        webViewRepresent.webView.loadHTMLString(htmlString ?? "", baseURL: url)
    }
}


//class NoteBookPreviewEditorInstance: WithRunnerEditorInstance  {
//    let webViewRepresent = NoteBookViewReprestable()
//    
//    init(
//        url: URL,
//        content: String,
//        encoding: String.Encoding = .utf8,
//        lastSavedDate: Date? = nil,
//        fileDidChange: ((FileState, String?) -> Void)? = nil
//    ) {
//        super.init(
//            url: url,
//            content: content,
//            encoding: encoding,
//            lastSavedDate: lastSavedDate,
//            editorView: AnyView(webViewRepresent),
//            fileDidChange: fileDidChange
//        )
//        
//        loadNBContent(nbContent: content)
//    }
//
//    func loadNBContent(nbContent: String) {
//        if nbtemplate == nil {
//            nbtemplate = try? String(contentsOf: ConstantManager.NBTEMPLATE_URL)
//        }
//        let htmlString = nbtemplate?.replacingOccurrences(of: "%nbcontent%", with: nbContent)
//        webViewRepresent.webView.loadHTMLString(htmlString ?? "", baseURL: url)
////        webViewRepresent.webView.loadHTMLString("Test", baseURL: url)
//    }
//}


//class NBViewerExtension: CodeAppExtension {
//
//    private func loadHTML(url: URL, app: MainApp, webView: WKWebView) {
//        if nbtemplate == nil {
//            nbtemplate = try? String(contentsOf: ConstantManager.NBTEMPLATE_URL)
//        }
//        
//        
//        app.workSpaceStorage.contents(at: url) { data, error in
//            guard let data else {
//                return
//            }
//            let nbContent = String(data: data, encoding: .utf8) ?? ""
//            let htmlString = nbtemplate?.replacingOccurrences(of: "%notebook-json%", with: nbContent)
//            webView.loadHTMLString(htmlString ?? "", baseURL: nil)
//        }
//    }
//
//    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
//        
//        
//
//        let provider = EditorProvider(
//            registeredFileExtensions: ["ipynb"],
//            onCreateEditor: { [weak self] url in
//                
//                
//
//                let editorInstance = NBPreviewEditorInstance(url: url, content: "")
//
//                self?.loadHTML(url: url, app: app, webView: editorInstance.webViewRepresent.webView)
////                editorInstance.fileWatch?.folderDidChange = { _ in
////                    self?.loadHTML(url: url, app: app, webView: editorInstance.webViewRepresent.webView)
////                }
////                editorInstance.fileWatch?.startMonitoring()
//
//                return editorInstance
//            }
//        )
//        contribution.editorProvider.register(provider: provider)
//    }
//}


import Foundation

extension String {
    func crc32Hex() -> String {
        let data = self.data(using: .utf8)!
        var crc: UInt32 = 0xFFFFFFFF
        let table = makeCRCTable()
        
        data.forEach { byte in
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        
        crc = crc ^ 0xFFFFFFFF
        return String(format: "%08x", crc)
    }
    
    private func makeCRCTable() -> [UInt32] {
        let polynomial: UInt32 = 0xEDB88320
        return (0..<256).map { i -> UInt32 in
            var value = UInt32(i)
            (0..<8).forEach { _ in
                value = (value & 1 == 1) ? (value >> 1) ^ polynomial : value >> 1
            }
            return value
        }
    }
}
