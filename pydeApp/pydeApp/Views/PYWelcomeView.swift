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

struct PYWelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var App: MainApp
    
    @State var content = ""
    
    let onCreateNewFile: () -> Void
    let onSelectFolderAsWorkspaceStorage: (URL) -> Void
    let onSelectFolder: () -> Void
    let onSelectFile: () -> Void
    let onNavigateToCloneSection: () -> Void
    let onExplorFolder: (URL) -> Void
    
    func onTouchLink(_ url: URL) -> Bool {

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
                onExplorFolder(ConstantManager.pysite)
            case "https://ipyde.com/ipyde/opensysroot":
                onExplorFolder(ConstantManager.SYSROOT)
            case "https://ipyde.com/ipyde/openusersite":
                onExplorFolder(ConstantManager.user_site)
            case "https://ipyde.com/ipyde/openhome":
                onExplorFolder(ConstantManager.HOME)
            case "https://ipyde.com/ipyde/newdjango":
                App.pyapp.showingNewDjangoAlert.toggle()
            case "https://ipyde.com/ipyde/newwebbrowser":
                if let url = URL(string: "https://www.baidu.cn") {
                    let editor = PYWebViewEditorInstance(url)
                    App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        App.pyapp.showAddressbar = true
                        App.pyapp.addressUrl = ""
                    }
                }
            case "https://ipyde.com/ipyde/newterminal":
                if let url = URL(string: App.workSpaceStorage.currentDirectory.url) {
                    let editor = PYTerminalEditorInstance(url)
                    App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                }
            case "https://ipyde.com/ipyde/importmedia":
                App.pyapp.showMediaPicker.toggle()
            case "https://ipyde.com/ipyde/importfile":
                App.pyapp.showFilePicker.toggle()
            case "https://ipyde.com/ipyde/clone":
//                    onNavigateToCloneSection()
                App.pyapp.showCloneAlert.toggle()
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
                        "\n[\(newURL.lastPathComponent)](https://ipyde.com/ipyde/previousFolder/\(i))<br/>"
                        + recentFolders
                }
            }
            if recentFolders.hasSuffix("<br/>") {
                recentFolders.removeLast(5)
            }
            content = content.replacingOccurrences(
                of: "{{recent}}",
                with: recentFolders)
        }
        self.content = content
    }
    
    var body: some View {
        ScrollView(content: {
            Markdown(content)
            .markdownTheme(.pygitHub())
            .listRowBackground(Color.red)
            .textSelection(.enabled)
            .environment(
                \.openURL,
                 OpenURLAction { url in
                     _ = onTouchLink(url)
                     return .handled
                 }
            )
            .padding()
        }).onAppear {
            prepare()
        }
    }
}

struct PYWelcomeView1: UIViewRepresentable {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var App: MainApp

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
    func onTouchLink(_ url: URL) -> Bool {

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
            case "https://ipyde.com/ipyde/newdjango":
                App.pyapp.showingNewDjangoAlert.toggle()
            case "https://ipyde.com/ipyde/newwebbrowser":
                if let url = URL(string: "https://www.baidu.cn") {
                    let editor = PYWebViewEditorInstance(url)
                    App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        App.pyapp.showAddressbar = true
                        App.pyapp.addressUrl = ""
                    }
                }
            case "https://ipyde.com/ipyde/newterminal":
                if let url = URL(string: App.workSpaceStorage.currentDirectory.url) {
                    let editor = PYTerminalEditorInstance(url)
                    App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                }
            case "https://ipyde.com/ipyde/importmedia":
                App.pyapp.showMediaPicker.toggle()
            case "https://ipyde.com/ipyde/importfile":
                App.pyapp.showFilePicker.toggle()
            case "https://ipyde.com/ipyde/clone":
//                    onNavigateToCloneSection()
                App.pyapp.showCloneAlert.toggle()
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
            return onTouchLink(url)
        }
        loadMd(md: md)
        md.isOpaque = true
        return md
    }

}


extension MarkdownUI.Theme {
  /// A theme that mimics the GitHub style.
  ///
  /// Style | Preview
  /// --- | ---
  /// Inline text | ![](GitHubInlines)
  /// Headings | ![](GitHubHeading)
  /// Blockquote | ![](GitHubBlockquote)
  /// Code block | ![](GitHubCodeBlock)
  /// Image | ![](GitHubImage)
  /// Task list | ![](GitHubTaskList)
  /// Bulleted list | ![](GitHubNestedBulletedList)
  /// Numbered list | ![](GitHubNumberedList)
  /// Table | ![](GitHubTable)
    public static func pygitHub() -> MarkdownUI.Theme {
        return MarkdownUI.Theme()
            .text {
                ForegroundColor(.text)
                BackgroundColor(.background)
                FontSize(16)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(.secondaryBackground)
            }
            .strong {
                FontWeight(.semibold)
            }
            .link {
                ForegroundColor(.link)
            }
            .heading1 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .relativeLineSpacing(.em(0.125))
                        .markdownMargin(top: 24, bottom: 16)
                        .markdownTextStyle {
                            FontWeight(.semibold)
                            FontSize(.em(2))
                        }
                    Divider().overlay(Color.divider)
                }
            }
            .heading2 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .relativeLineSpacing(.em(0.125))
                        .markdownMargin(top: 24, bottom: 16)
                        .markdownTextStyle {
                            FontWeight(.semibold)
                            FontSize(.em(1.5))
                        }
                    Divider().overlay(Color.divider)
                }
            }
            .heading3 { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.25))
                    }
            }
            .heading4 { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                    }
            }
            .heading5 { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(0.875))
                    }
            }
            .heading6 { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(0.85))
                        ForegroundColor(.tertiaryText)
                    }
            }
            .paragraph { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.25))
                    .markdownMargin(top: 0, bottom: 16)
            }
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.border)
                        .relativeFrame(width: .em(0.2))
                    configuration.label
                        .markdownTextStyle { ForegroundColor(.secondaryText) }
                        .relativePadding(.horizontal, length: .em(1))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .codeBlock { configuration in
                ScrollView(.horizontal) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .relativeLineSpacing(.em(0.225))
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                        }
                        .padding(16)
                }
                .background(Color.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .markdownMargin(top: 0, bottom: 16)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.25))
            }
            .taskListMarker { configuration in
                Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.checkbox, Color.checkboxBackground)
                    .imageScale(.small)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(color: .border))
                    .markdownTableBackgroundStyle(
                        .alternatingRows(Color.background, Color.secondaryBackground)
                    )
                    .markdownMargin(top: 0, bottom: 16)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 {
                            FontWeight(.semibold)
                        }
                        BackgroundColor(nil)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 13)
                    .relativeLineSpacing(.em(0.25))
            }
            .thematicBreak {
                Divider()
                    .relativeFrame(height: .em(0.25))
                    .overlay(Color.border)
                    .markdownMargin(top: 24, bottom: 24)
            }
    }
}

extension Color {
    fileprivate static let text = Color(
        light: Color(rgba: 0x0606_06ff), dark: Color(rgba: 0xfbfb_fcff)
    )
    fileprivate static let secondaryText = Color(
        light: Color(rgba: 0x6b6e_7bff), dark: Color(rgba: 0x9294_a0ff)
    )
    fileprivate static let tertiaryText = Color(
        light: Color(rgba: 0x6b6e_7bff), dark: Color(rgba: 0x6d70_7dff)
    )
    fileprivate static var background: Color{
        Color.init(id: "editor.background")
    }
    fileprivate static let secondaryBackground = Color(
        light: Color(rgba: 0xf7f7_f9ff), dark: Color(rgba: 0x2526_2aff)
    )
    fileprivate static let link = Color(
        light: Color(rgba: 0x2c65_cfff), dark: Color(rgba: 0x4c8e_f8ff)
    )
    fileprivate static let border = Color(
        light: Color(rgba: 0xe4e4_e8ff), dark: Color(rgba: 0x4244_4eff)
    )
    fileprivate static let divider = Color(
        light: Color(rgba: 0xd0d0_d3ff), dark: Color(rgba: 0x3334_38ff)
    )
    fileprivate static let checkbox = Color(rgba: 0xb9b9_bbff)
    fileprivate static let checkboxBackground = Color(rgba: 0xeeee_efff)
}
