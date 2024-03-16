//
//  PYWelcomeView.swift
//  pydeApp
//
//  Created by Huima on 2024/3/12.
//

import SwiftUI
import MarkdownView

struct PYWelcomeView: UIViewRepresentable {
    @EnvironmentObject var themeManager: ThemeManager

    let onCreateNewFile: () -> Void
    let onSelectFolderAsWorkspaceStorage: (URL) -> Void
    let onSelectFolder: () -> Void
    let onSelectFile: () -> Void
    let onNavigateToCloneSection: () -> Void

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
                of: "(https://ipyde.com/ipyde/openfolder)",
                with:
                    "(https://ipyde.com/ipyde/openfolder)\n\n#### \(NSLocalizedString("Recent", comment: ""))"
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
