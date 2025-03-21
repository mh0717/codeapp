//
//  PYMarkdownViewerExtension.swift
//  Code
//
//  Created by huima on 2025/3/21.
//

import MarkdownUI
import MarkdownView
import SwiftUI

// TODO: Localization



private class PYMarkdownContent: ObservableObject {
    @Published var content: String = ""
}

private struct MarkdownPreview1: View {
    @EnvironmentObject var App: MainApp

    @ObservedObject var content: PYMarkdownContent

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

private struct PYMarkdownPreview: UIViewRepresentable {
    @EnvironmentObject var App: MainApp

    weak var view: MarkdownView?

    func updateUIView(_ uiView: MarkdownView, context: Context) {
        //        uiView.changeBackgroundColor(color: UIColor(id: "editor.background"))
    }

    func makeUIView(context: Context) -> MarkdownView {
        let mdview = view ?? MarkdownView()
        mdview.onTouchLink = { req in
            guard let url = req.url else { return false }

            App.pyapp.openUrl(url)
            return false
        }
        return mdview
    }
}

class PYMarkdownEditorInstance: EditorInstanceWithURL {

    let mdView = MarkdownView()

    func load(content: String) {
        mdView.load(markdown: content, backgroundColor: UIColor(id: "editor.background"))
    }
    fileprivate let mdcontent = PYMarkdownContent()

    init(url: URL, content: String, title: String) {
        super.init(view: AnyView(PYMarkdownPreview(view: mdView).id(UUID())), title: title, url: url)
    }
}

class PYMarkdownViewerExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let item = ToolbarItem(
            extenionID: "PYMARKDOWN",
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
