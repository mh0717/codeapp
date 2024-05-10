//
//  MarkdownViewerExtension.swift
//  Code
//
//  Created by Ken Chung on 23/11/2022.
//

import MarkdownView
import SwiftUI
import MarkdownUI

// TODO: Localization

private class MarkdownContent: ObservableObject {
    @Published var content: String = ""
}

private struct MarkdownPreview1: View {
    @EnvironmentObject var App: MainApp
    
    @ObservedObject var content: MarkdownContent
    
    var body: some View {
        ScrollView(content: {
            Markdown(content.content)
            .markdownTheme(.pygitHub())
            .listRowBackground(Color.red)
            .textSelection(.enabled)
            .environment(
                \.openURL,
                 OpenURLAction { url in
                     App.pyapp.openUrl(url)
                     return .handled
                 }
            )
            .padding()
        })
    }
}

private struct MarkdownPreview: UIViewRepresentable {
    @EnvironmentObject var App: MainApp

    weak var view: MarkdownView?

    func updateUIView(_ uiView: MarkdownView, context: Context) {
//        uiView.changeBackgroundColor(color: UIColor(id: "editor.background"))
    }

    func makeUIView(context: Context) -> MarkdownView {
        let mdview = view ?? MarkdownView()
        mdview.onTouchLink = { req in
            guard let url = req.url else {return false}
            
            App.pyapp.openUrl(url)
            return false
            
//            if url.scheme == "file" {
//                App.openFile(url: url, alwaysInNewTab: true)
//                return false
//            }
//            
//            if url.scheme == "jupyter-notebook" {
//                JupyterExtension.jupyterManager.openNotebook(URL(string: App.workSpaceStorage.currentDirectory.url))
//                return false
//            }
//            
//            if url.scheme == "dlhttp" || url.scheme == "dlhttps" {
//                let str = url.absoluteString.replacingFirstOccurrence(of: "dlhttp", with: "http")
//                if let url = URL(string: str) {
//                    DownloadManager.instance.download(url)
//                    App.notificationManager.showInformationMessage("Downloading %@", url.absoluteString)
//                }
//                return false
//            }
//            
//            if url.scheme == "http" || url.scheme == "https" || url.scheme == "ftp" {
//                let editor = PYWebEditorInstance(url)
//                App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
//            } else {
//                UIApplication.shared.open(url)
//            }
        }
        return mdview
    }
}

class MarkdownEditorInstance: EditorInstanceWithURL {

    let mdView = MarkdownView()

    func load(content: String) {
        mdView.load(markdown: content, backgroundColor: UIColor(id: "editor.background"))
    }
    fileprivate let mdcontent = MarkdownContent()

    init(url: URL, content: String, title: String) {
        super.init(view: AnyView(MarkdownPreview(view: mdView).id(UUID())), title: title, url: url)
        load(content: content)
//        mdcontent.content = content
//        super.init(view: AnyView(MarkdownPreview1(content: mdcontent).id(UUID())), title: title, url: url)
    }
}

class MarkdownViewerExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let item = ToolbarItem(
            extenionID: "MARKDOWN",
            icon: "newspaper",
            onClick: {
                guard let content = app.activeTextEditor?.content,
                    let url = app.activeTextEditor?.url
                else {
                    return
                }
                let instance = MarkdownEditorInstance(
                    url: url,
                    content: content, title: "Preview: " + url.lastPathComponent)
                instance.fileWatch?.folderDidChange = { _ in
                    Task {
                        let contentData = try await app.workSpaceStorage.contents(at: url)
                        if let content = String(data: contentData, encoding: .utf8) {
                            await MainActor.run {
                                instance.load(content: content)
//                                instance.mdcontent.content = content
                            }
                        }
                    }
                }
                instance.fileWatch?.startMonitoring()

                DispatchQueue.main.async {
                    app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
                }
            },
            shouldDisplay: {
                ["md", "markdown"].contains(app.activeTextEditor?.languageIdentifier.lowercased())
            }
        )
        contribution.toolBar.registerItem(item: item)
    }

}
