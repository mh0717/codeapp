//
//  EpubExtension.swift
//  iPyDE
//
//  Created by Huima on 2024/4/28.
//
import SwiftUI
//import FolioReaderKit
//import RealmSwift
//import SwiftReader
import pydeCommon

class EpubEditorInstance: EditorInstanceWithURL {

//    let viewModel: EBookReaderViewModel
    
//    init(title: String, url: URL) {
//        viewModel = EBookReaderViewModel(file: url, delay: 1000 * 100)
//        viewModel.theme = BookThemeManager.instance.theme
//        
//        super.init(view: AnyView(EBookView(model: viewModel).id(UUID())), title: title, url: url)
//    }
    
    
    let wbview = WebViewBase()
    
    private let coordinator: WebCoordinator
    
    init(title: String, url: URL) {
        coordinator = WebCoordinator(url: url)
//        viewModel = EBookReaderViewModel(file: url, delay: 1000 * 100)
        super.init(view: AnyView(PoliateView(webView: wbview).id(UUID())), title: title, url: url)
        
        let hurl = ConstantManager.FOLIATE.appendingPathComponent("reader.html")
        let aurl = ConstantManager.FOLIATE
        wbview.loadFileURL(hurl, allowingReadAccessTo: aurl)
        
        wbview.navigationDelegate = coordinator
    }
    
    
}

fileprivate class WebCoordinator: NSObject, WKNavigationDelegate {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let data = try? Data(contentsOf: url) else {
            return
        }
        print(data.count)
        let base64String = data.base64EncodedString()
        let jsstr = js.replacingFirstOccurrence(of: "{{base64Content}}", with: base64String)
        webView.evaluateJavaScript(jsstr)
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(250))) {
            let theme = ThemeManager.isDark() ? BookThemeManager.instance.darkTheme : BookThemeManager.instance.lightTheme
            didSetTheme(webView, theme: theme)
        }
    }
}

let js = """
    let base64Content = "{{base64Content}}"
    let bookData = Uint8Array.from(atob(base64Content), c => c.charCodeAt(0))
    console.log(bookData)
    console.log(bookData.byteOffset)
    bookData.byteOffset = 0
    let bookFile = new File([bookData.buffer],  "epub");
    console.log(bookFile.size)
    openBook(bookFile)
    """

fileprivate func didSetTheme(_ webView: WKWebView, theme: BookTheme) {
    let theme = ThemeManager.isDark() ? BookThemeManager.instance.darkTheme : BookThemeManager.instance.lightTheme
    let script = """
    var _style = {
        lineHeight: \(theme.lineHeight),
        justify: \(theme.justify),
        hyphenate: \(theme.hyphenate),
        theme: {bg: "\(theme.bg)", fg: "\(theme.fg)", name: "\(theme.dark ? "dark" : "light")"},
        fontSize: \(theme.fontSize),
    }

    var _layout = {
       gap: \(theme.gap),
       maxInlineSize: \(theme.maxInlineSize),
       maxBlockSize: \(theme.maxBlockSize),
       maxColumnCount: \(theme.maxColumnCount),
       flow: \(theme.flow),
       animated: \(theme.animated),
       margin: \(theme.margin)
    }

    setTheme({style: _style, layout: _layout})
    """
    webView.evaluateJavaScript(script)
}

struct PoliateView: View {
    let webView: WKWebView
    
    @ObservedObject var themeManager = BookThemeManager.instance
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        ViewRepresentable(webView)
            .background(Color.init(id: "editor.background"))
            .onReceive(themeManager.objectWillChange, perform: { _ in
                let theme = ThemeManager.isDark() ? themeManager.darkTheme : themeManager.lightTheme
                didSetTheme(webView, theme: theme)
            })
            .onChange(of: colorScheme, perform: { newValue in
                let theme = ThemeManager.isDark() ? themeManager.darkTheme : themeManager.lightTheme
                didSetTheme(webView, theme: theme)
            })
    }
    
    
}

//struct EBookView: View {
//    @ObservedObject var model: EBookReaderViewModel
//    
//    @EnvironmentObject var themeManager: ThemeManager
//    
//    @ObservedObject var theme = BookThemeManager.instance
//    
//    @Environment(\.colorScheme) var colorScheme: ColorScheme
//    
//    var body: some View {
//        EBookReader(viewModel: model)
//            .background(Color.init(id: "editor.background"))
//            .onReceive(theme.objectWillChange, perform: { _ in
//                if colorScheme == .dark {
//                    model.theme = theme.darkTheme
//                } else {
//                    model.theme = theme.lightTheme
//                }
//                model.setBookTheme()
//            })
//            .onChange(of: colorScheme, perform: { newValue in
//                if newValue == .dark {
//                    model.theme = theme.darkTheme
//                } else {
//                    model.theme = theme.lightTheme
//                }
//                model.setBookTheme()
//            })
//            .sheet(isPresented: $model.showingToc, content: {
//                ReaderContent(toc: model.toc ?? [], isSelected: { item in model.isBookTocItemSelected(item: item) }, tocItemPressed: { item in
//                    model.goTo(cfi: item.href)
//                    model.showingToc.toggle()
//                }, currentTocItemId: model.currentTocItem?.id)
//            })
//    }
//}

//class EpubEditorInstance: EditorInstanceWithURL {
//    let readerVC: FolioReaderContainer
//    
//    let viewModel: EBookReaderViewModel
//    
//    init(title: String, url: URL) {
//        let config = FolioReaderConfig(withIdentifier: "epub")
//            config.shouldHideNavigationOnTap = true
//        config.hideBars = true
////            config.scrollDirection = epub.scrollDirection
//
//        // See more at FolioReaderConfig.swift
////        config.canChangeScrollDirection = false
////        config.enableTTS = false
////        config.displayTitle = true
//        config.allowSharing = false
////        config.tintColor = UIColor.blueColor()
////        config.toolBarTintColor = UIColor.redColor()
////        config.toolBarBackgroundColor = UIColor.purpleColor()
////        config.menuTextColor = UIColor.brownColor()
////        config.menuBackgroundColor = UIColor.lightGrayColor()
////        config.hidePageIndicator = true
//        config.realmConfiguration = Realm.Configuration(fileURL: FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("highlights.realm"))
//
////        // Custom sharing quote background
////        config.quoteCustomBackgrounds = []
////        if let image = UIImage(named: "demo-bg") {
////            let customImageQuote = QuoteImage(withImage: image, alpha: 0.6, backgroundColor: UIColor.black)
////            config.quoteCustomBackgrounds.append(customImageQuote)
////        }
////
////        let textColor = UIColor(red:0.86, green:0.73, blue:0.70, alpha:1.0)
////        let customColor = UIColor(red:0.30, green:0.26, blue:0.20, alpha:1.0)
////        let customQuote = QuoteImage(withColor: customColor, alpha: 1.0, textColor: textColor)
////        config.quoteCustomBackgrounds.append(customQuote)
//        
//        let reader = FolioReader()
//        readerVC = FolioReaderContainer(withConfig: config, folioReader: reader, epubPath: url.path, removeEpub: false)
//        
//        /*super.init(view: AnyView(EpubView(readerVC: readerVC).id(UUID())), title: title, url: url)*/
//        super.init(view: AnyView(EBookReader(url: url)), title: title, url: url)
//        
//        
//    }
//}


//struct EpubView: UIViewControllerRepresentable {
//    let readerVC: FolioReaderContainer
//    
//    func makeUIViewController(context: Self.Context) -> FolioReaderContainer {
//        return readerVC
//    }
//
//    func updateUIViewController(_ uiViewController: FolioReaderContainer, context: Self.Context) {
//        
//    }
//}


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
//                    editor.readerVC.centerViewController?.presentChapterList(nil)
//                    editor.viewModel.showingToc = true
                    editor.wbview.evaluateJavaScript("window.showSide()")
                }
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? EpubEditorInstance else { return false }
                return true
            }
        )
        
//        let fontSizeItem = ToolbarItem(
//            extenionID: "EPUBFONTSIZE",
//            icon: "textformat.size",
//            onClick: {
//                if let editor = app.activeEditor as? EpubEditorInstance {
////                    editor.readerVC.centerViewController?.presentFontsMenu()
//                }
//            },
//            shouldDisplay: {
//                guard let ditor = app.activeEditor as? EpubEditorInstance else { return false }
//                return true
//            }
//        )
        
        
        contribution.toolBar.registerItem(item: toolbarItem)
//        contribution.toolBar.registerItem(item: fontSizeItem)
    }
}


//struct ReaderContent<T: TocItem>: View {
//    @Environment(\.dismiss) var dismiss
////    @Environment(AppTheme.self) var theme
//
//    var toc: [T]
//    var isSelected: ((T) -> Bool)?
//    var tocItemPressed: ((T) -> Void)?
//    var currentTocItemId: Int?
//
//    var body: some View {
//        NavigationView {
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack {
//                        ForEach(toc) { tocItem in
//                            let selected = isSelected?(tocItem) ?? false
//
//                            VStack {
//                                Button {
//                                    tocItemPressed?(tocItem)
//
//                                } label: {
//                                    HStack {
//                                        Text(tocItem.label)
//                                            .lineLimit(2)
//                                            .multilineTextAlignment(.leading)
////                                            .fontWeight(tocItem.depth == 0 ? .semibold : .light)
//
//                                        Spacer()
//
//                                        if let pageNumber = tocItem.pageNumber {
//                                            Text("\(pageNumber)")
//                                        }
//                                        Image(systemName: "chevron.right")
//                                    }
////                                    .foregroundStyle(selected ? theme.tintColor : .white)
//                                }
//                                .padding(.leading, CGFloat(tocItem.depth ?? 0) * 10)
//                            }
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                            .id(tocItem.id)
//                        }
//                    }
//                }
////                .scrollIndicators(.hidden)
//                .onAppear {
//                    if let currentTocItemId {
//                        proxy.scrollTo(currentTocItemId, anchor: .center)
//                    }
//                }
//            }
//            .navigationTitle("Content")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
////                ToolbarItem(placement: .topBarTrailing) {
////                    SRXButton {
////                        dismiss()
////                    }
////                }
//            }
//        }
//    }
//}



public class BookThemeManager:  ObservableObject {
    var theme = BookTheme()
    
    var lightTheme = BookTheme()
    var darkTheme = BookTheme()
    
    init() {
        darkTheme.dark = true
        darkTheme.bg = "#000000"
        darkTheme.fg = "#FFFFFF"
        darkTheme.flow = true
        
        lightTheme.dark = false
        lightTheme.bg = "#FFFFFF"
        lightTheme.fg = "#000000"
        lightTheme.flow = true
        NotificationCenter.default.addObserver(forName: Notification.Name("theme.updated"), object: nil, queue: nil) { notification in
            let isDark = notification.userInfo?["isDark"] as? Bool ?? true
            self.updateTheme(isDark)
        }
        updateTheme(ThemeManager.isDark())
    }
    
    func updateTheme(_ isDark: Bool) {
        
        if let item = globalDarkTheme {
            let colors = item["colors"] as? [String: Any] ?? [:]
            let forgroundColor = colors["foreground"] ?? colors["editor.foreground"] ?? colors["input.foreground"] ?? colors["tab.activeForeground"] ?? "#dfdfdf"
            let backgroundColor = colors["editor.background"] ?? "#101316"
            darkTheme.bg = backgroundColor as? String ?? "#000000"
            darkTheme.fg = forgroundColor as? String ?? "#FFFFFF"
        } else {
            darkTheme.bg = "#000000"
            darkTheme.fg = "#FFFFFF"
        }
        
        if let item = globalLightTheme {
            let colors = item["colors"] as? [String: Any] ?? [:]
            let forgroundColor = colors["foreground"] ?? colors["editor.foreground"] ?? colors["input.foreground"] ?? colors["tab.activeForeground"] ?? "#dfdfdf"
            let backgroundColor = colors["editor.background"] ?? "#101316"
            lightTheme.bg = backgroundColor as? String ?? "#000000"
            lightTheme.fg = forgroundColor as? String ?? "#FFFFFF"
        } else {
            lightTheme.bg = "#FFFFFF"
            lightTheme.fg = "#000000"
        }
        
        theme = isDark ? darkTheme : lightTheme
        
        objectWillChange.send()
    }
    
    static let instance = BookThemeManager()
}


let themeJS = """
const getCSS = ({ lineHeight, justify, hyphenate, theme, fontSize }) => `
@namespace epub "http://www.idpf.org/2007/ops";
@media print {
    html {
        column-width: auto !important;
        height: auto !important;
        width: auto !important;
    }
}
html, body {
  background: none !important;
  color: ${theme.fg};
}
body *{
  background-color: ${theme.bg} !important;
  color: inherit !important;
}
html, body, p, li, blockquote, dd {
    font-size: ${fontSize}%;
    line-height: ${lineHeight} !important;
    text-align: ${justify ? "justify" : "start"};
    -webkit-hyphens: ${hyphenate ? "auto" : "manual"};
    hyphens: ${hyphenate ? "auto" : "manual"};
    -webkit-hyphenate-limit-before: 3;
    -webkit-hyphenate-limit-after: 2;
    -webkit-hyphenate-limit-lines: 2;
    hanging-punctuation: allow-end last;
    widows: 2;
}
/* prevent the above from overriding the align attribute */
[align="left"] { text-align: left; }
[align="right"] { text-align: right; }
[align="center"] { text-align: center; }
[align="justify"] { text-align: justify; }

pre {
    white-space: pre-wrap !important;
}
aside[epub|type~="endnote"],
aside[epub|type~="footnote"],
aside[epub|type~="note"],
aside[epub|type~="rearnote"] {
    display: none;
}
`;

let setTheme = ({ style, layout }) => {
Object.assign(this.style, style);
const { theme } = style;
const $style = document.documentElement.style;
$style.setProperty("--bg", theme.bg);
$style.setProperty("--fg", theme.fg);
const renderer = this.view?.renderer;
if (renderer) {
  renderer.setAttribute("flow", layout.flow ? "scrolled" : "paginated");
  renderer.setAttribute("gap", layout.gap * 100 + "%");
  renderer.setAttribute("margin", layout.margin + "px");
  renderer.setAttribute("max-inline-size", layout.maxInlineSize + "px");
  renderer.setAttribute("max-block-size", layout.maxBlockSize + "px");
  renderer.setAttribute("max-column-count", layout.maxColumnCount);
  renderer.setAttribute("animated", layout.animated);
  renderer.setStyles?.(getCSS(this.style));
}
if (theme.name !== "light") {
  $style.setProperty("--mode", "screen");
} else {
  $style.setProperty("--mode", "multiply");
}
return true;
};

var _style = {
    theme: {bg: "#000000", fg: "#FFFFFF", name: "dark"},
}

var _layout = {

}

setTheme({style: _style, layout: _layout})

var _style = {
    lineHeight: 1.2,
    justify: true,
    hyphenate:  true,
    theme: {bg: "#000000", fg: "#FFFFFF", name: "dark"},
    fontSize: 100,
}

var _layout = {
   gap: 0.0,
   maxInlineSize: 1080,
   maxBlockSize: 2048,
   maxColumnCount: 1,
   flow: true,
   animated: true,
   margin: 0
}
setTheme({style: _style, layout: _layout})
"""

public struct BookTheme: Codable {
    
    // MARK: Layout

    public static let saveKey = "ReaderTheme"

    public var gap = 0.06
    public var maxInlineSize = 1080
    public var maxBlockSize = 1440
    public var maxColumnCount = 1
    public var flow = false
    public var animated = true
    public var margin = 24

    // MARK: Style

    public var lineHeight = 1.5
    public var justify = true
    public var hyphenate = true
    public var fontSize = 100

    // MARK: Book Theme

//    public var bg: ThemeBackground = .dark
//    public var fg: ThemeForeground = .dark
    public var dark: Bool = false
    public var bg: String = "#000000"
    public var fg: String = "#FFFFFF"

    // TODO: SET MINIMUM AND MAXIMUM VALUES

    public mutating func increaseFontSize() {
        fontSize += 2
    }

    public mutating func decreaseFontSize() {
        fontSize -= 2
    }

    public mutating func increaseGap() {
        let newGap = gap + 0.01
        gap = min(100, newGap)
    }

    public mutating func decreaseGap() {
        let newGap = gap - 0.01
        gap = max(0, newGap)
    }

    public mutating func increaseBlockSize() {
        maxBlockSize += 50
    }

    public mutating func decreaseBlockSize() {
        maxBlockSize -= 50
    }

    public mutating func setMaxColumnCount(_ count: Int) {
        maxColumnCount = count
    }

    public mutating func increaseMargin() {
        let newMargin = margin + 2
        margin = min(200, newMargin)
    }

    public mutating func decreaseMargin() {
        let newMargin = margin - 2
        margin = max(0, newMargin)
    }

    public mutating func increaseLineHeight() {
        let new = lineHeight + 0.1

        lineHeight = min(7, new)
    }

    public mutating func decreaseLineHeight() {
        let new = lineHeight - 0.1

        lineHeight = max(0.8, new)
    }

    public init() {
        if let decodedData = UserDefaults.standard.data(forKey: BookTheme.saveKey) {
            if let theme = try? JSONDecoder().decode(BookTheme.self, from: decodedData) {
                self.gap = theme.gap
                self.animated = theme.animated
                self.maxInlineSize = theme.maxInlineSize
                self.maxBlockSize = theme.maxBlockSize
                self.maxColumnCount = theme.maxColumnCount
                self.margin = theme.margin
                self.flow = theme.flow
                self.lineHeight = theme.lineHeight
                self.justify = theme.justify
                self.hyphenate = theme.hyphenate
                self.fontSize = theme.fontSize
                self.bg = theme.bg
                self.fg = theme.fg
            }
        }
    }

    func save() {
        if let encodedTheme = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encodedTheme, forKey: BookTheme.saveKey)
        }
    }
}
