//
//  EpubExtension.swift
//  iPyDE
//
//  Created by Huima on 2024/4/28.
//
import SwiftUI
import FolioReaderKit
import RealmSwift

class EpubEditorInstance: EditorInstanceWithURL {
    let readerVC: FolioReaderContainer
    
    init(title: String, url: URL) {
        let config = FolioReaderConfig(withIdentifier: "epub")
            config.shouldHideNavigationOnTap = true
        config.hideBars = true
//            config.scrollDirection = epub.scrollDirection

        // See more at FolioReaderConfig.swift
//        config.canChangeScrollDirection = false
//        config.enableTTS = false
//        config.displayTitle = true
        config.allowSharing = false
//        config.tintColor = UIColor.blueColor()
//        config.toolBarTintColor = UIColor.redColor()
//        config.toolBarBackgroundColor = UIColor.purpleColor()
//        config.menuTextColor = UIColor.brownColor()
//        config.menuBackgroundColor = UIColor.lightGrayColor()
//        config.hidePageIndicator = true
        config.realmConfiguration = Realm.Configuration(fileURL: FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("highlights.realm"))

//        // Custom sharing quote background
//        config.quoteCustomBackgrounds = []
//        if let image = UIImage(named: "demo-bg") {
//            let customImageQuote = QuoteImage(withImage: image, alpha: 0.6, backgroundColor: UIColor.black)
//            config.quoteCustomBackgrounds.append(customImageQuote)
//        }
//
//        let textColor = UIColor(red:0.86, green:0.73, blue:0.70, alpha:1.0)
//        let customColor = UIColor(red:0.30, green:0.26, blue:0.20, alpha:1.0)
//        let customQuote = QuoteImage(withColor: customColor, alpha: 1.0, textColor: textColor)
//        config.quoteCustomBackgrounds.append(customQuote)
        
        let reader = FolioReader()
        readerVC = FolioReaderContainer(withConfig: config, folioReader: reader, epubPath: url.path, removeEpub: false)
        
        super.init(view: AnyView(EpubView(readerVC: readerVC).id(UUID())), title: title, url: url)
        
        
    }
}


struct EpubView: UIViewControllerRepresentable {
    let readerVC: FolioReaderContainer
    
    func makeUIViewController(context: Self.Context) -> FolioReaderContainer {
        return readerVC
    }

    func updateUIViewController(_ uiViewController: FolioReaderContainer, context: Self.Context) {
        
    }
}


class EpubExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {

        let provider = EditorProvider(
            registeredFileExtensions: ["epub"],
            onCreateEditor: { url in
                
                let editorInstance = EpubEditorInstance(title: url.lastPathComponent, url: url)

                return editorInstance
            }
        )
        contribution.editorProvider.register(provider: provider)
        
        
        let toolbarItem = ToolbarItem(
            extenionID: "EPUBTOC",
            icon: "list.bullet",
            onClick: {
                if let editor = app.activeEditor as? EpubEditorInstance {
                    editor.readerVC.centerViewController?.presentChapterList(nil)
                }
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? EpubEditorInstance else { return false }
                return true
            }
        )
        
        let fontSizeItem = ToolbarItem(
            extenionID: "EPUBFONTSIZE",
            icon: "textformat.size",
            onClick: {
                if let editor = app.activeEditor as? EpubEditorInstance {
                    editor.readerVC.centerViewController?.presentFontsMenu()
                }
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? EpubEditorInstance else { return false }
                return true
            }
        )
        
        
        contribution.toolBar.registerItem(item: toolbarItem)
        contribution.toolBar.registerItem(item: fontSizeItem)
    }
}
