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








private var nbtemplate: String?

struct NoteBookViewReprestable: UIViewRepresentable {
    
    let webView: WKWebView = WebViewBase()
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}


class NoteBookPreviewEditorInstance: WithRunnerEditorInstance  {
    let webViewRepresent = NoteBookViewReprestable()
    
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
            editorView: AnyView(webViewRepresent),
            fileDidChange: fileDidChange
        )
        
        loadNBContent(nbContent: content)
    }

    func loadNBContent(nbContent: String) {
        if nbtemplate == nil {
            nbtemplate = try? String(contentsOf: ConstantManager.NBTEMPLATE_URL)
        }
        let htmlString = nbtemplate?.replacingOccurrences(of: "%nbcontent%", with: nbContent)
        webViewRepresent.webView.loadHTMLString(htmlString ?? "", baseURL: url)
//        webViewRepresent.webView.loadHTMLString("Test", baseURL: url)
    }
}


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
