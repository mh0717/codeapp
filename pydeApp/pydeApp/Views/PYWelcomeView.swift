//
//  PYWelcomeView.swift
//  pydeApp
//
//  Created by Huima on 2024/3/12.
//

import SwiftUI
import MarkdownView
import MarkdownUI
import pydeCommon

struct PYWelcomeView2: View {
    @State var content = ""
    
    let onCreateNewFile: () -> Void
    let onSelectFolderAsWorkspaceStorage: (URL) -> Void
    let onSelectFolder: () -> Void
    let onSelectFile: () -> Void
    let onNavigateToCloneSection: () -> Void
    
    func prepare() {
        var content = NSLocalizedString("Welcome Message", comment: "")
        if let datas = UserDefaults.standard.value(forKey: "recentFolder") as? [Data] {
            var recentFolders = "\n"

            for i in datas.indices.reversed() {
                var isStale = false
                if let newURL = try? URL(
                    resolvingBookmarkData: datas[i], bookmarkDataIsStale: &isStale)
                {
                    recentFolders =
                        "\n[\(newURL.lastPathComponent)](https://ipyde.com/ipyde/previousFolder/\(i))"
                        + recentFolders
                }
            }
            content = content.replacingOccurrences(
                of: "(https://ipyde.com/ipyde/openfolder)",
                with:
                    "(https://ipyde.com/ipyde/openfolder)\n\n#### \(NSLocalizedString("Recent", comment: ""))"
                    + recentFolders)
        }
        self.content = content
    }
    
    var body: some View {
        Markdown(content).onAppear {
            prepare()
        }.textSelection(.enabled)
            .markdownTheme(.gitHub)
            // Some themes may have a custom background color that we need to set as
//            // the row's background color.
//            .listRowBackground(MarkdownUI.Theme.gitHub.textBackgroundColor)
//            // By resetting the state when the theme changes, we avoid mixing the
//            // the previous theme block spacing preferences with the new theme ones,
//            // which can only happen in this particular use case.
//            .id(Theme.gitHub.name)
    }
}

struct PYWelcomeView: UIViewRepresentable {
    @EnvironmentObject var themeManager: ThemeManager

    let onCreateNewFile: () -> Void
    let onSelectFolderAsWorkspaceStorage: (URL) -> Void
    let onSelectFolder: () -> Void
    let onSelectFile: () -> Void
    let onNavigateToCloneSection: () -> Void
    let onExplorFolder: (URL) -> Void

    func updateUIView(_ uiView: MarkdownView, context: Context) {
        uiView.changeBackgroundColor(color: UIColor(Color.init(id: "editor.background")))
        return
    }

//    func makeCoordinator() -> PYWelcomeView.Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextViewDelegate, MFMailComposeViewControllerDelegate {
//        var control: WelcomeView
//
//        init(_ control: WelcomeView) {
//            self.control = control
//            super.init()
//
//        }
//
//    }

    func loadMd(md: MarkdownView) {
        var content = NSLocalizedString("Welcome Message", comment: "")
        if let datas = UserDefaults.standard.value(forKey: "recentFolder") as? [Data] {
            var recentFolders = "\n"

            for i in datas.indices.reversed() {
                var isStale = false
                if let newURL = try? URL(
                    resolvingBookmarkData: datas[i], bookmarkDataIsStale: &isStale)
                {
                    recentFolders =
                        "\n[\(newURL.lastPathComponent)](https://ipyde.com/ipyde/previousFolder/\(i))"
                        + recentFolders
                }
            }
            content = content.replacingOccurrences(
                of: "(https://ipyde.com/ipyde/importfile)",
                with:
                    "(https://ipyde.com/ipyde/importfile)\n\n#### \(NSLocalizedString("Recent", comment: ""))"
                    + recentFolders)
        }

        md.load(markdown: content, backgroundColor: UIColor(Color.init(id: "editor.background")))
    }

    func makeUIView(context: Context) -> MarkdownView {
        let md = MarkdownView()
        md.changeBackgroundColor(color: UIColor(Color.init(id: "editor.background")))
        md.onTouchLink = { request in
            guard let url = request.url else { return false }

            if url.scheme == "file" {
                return false
            } else if url.scheme == "https" || url.scheme == "mailto" {
                switch url.absoluteString {
                case "https://ipyde.com/ipyde/newfile":
                    onCreateNewFile()
                case "https://ipyde.com/ipyde/openfolder":
                    onSelectFolder()
                case "https://ipyde.com/ipyde/openfile":
                    onSelectFile()
                case "https://ipyde.com/ipyde/openexamples":
                    onExplorFolder(ConstantManager.EXAMPLES)
                case "https://ipyde.com/ipyde/openpyhome":
                    onExplorFolder(ConstantManager.pyhome)
                case "https://ipyde.com/ipyde/opensitepackages":
                    onExplorFolder(ConstantManager.LOCAL_SITE_PACKAGES_URL)
                case "https://ipyde.com/ipyde/openhome":
                    onExplorFolder(ConstantManager.appGroupContainer)
                case "https://ipyde.com/ipyde/importfile":
                    print("import")
                case "https://ipyde.com/ipyde/clone":
                    onNavigateToCloneSection()
                case let i where i.hasPrefix("https://ipyde.com/ipyde/previousFolder/"):
                    let key = Int(
                        i.replacingOccurrences(
                            of: "https://ipyde.com/ipyde/previousFolder/", with: ""))!
                    if let datas = UserDefaults.standard.value(forKey: "recentFolder") as? [Data] {
                        var isStale = false
                        if let newURL = try? URL(
                            resolvingBookmarkData: datas[key], bookmarkDataIsStale: &isStale)
                        {
                            onSelectFolderAsWorkspaceStorage(newURL)
                        }
                    }
                default:
                    UIApplication.shared.open(url)
                }
                return false
            } else {
                return false
            }
        }
        loadMd(md: md)
        md.isOpaque = true
        return md
    }

}
