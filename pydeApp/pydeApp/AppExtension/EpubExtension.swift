//
//  EpubExtension.swift
//  iPyDE
//
//  Created by Huima on 2024/4/28.
//
import SwiftUI
import pydeCommon

let EBOOK_EXT = ["epub", "fbz", "cbz", "fb2"]

class EpubExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {

        let provider = EditorProvider(
            registeredFileExtensions: EBOOK_EXT,
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
                    editor.wbview.evaluateJavaScript("window.showSide()")
                }
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? EpubEditorInstance else { return false }
                return true
            }
        )
        
        let backwardItem = ToolbarItem(
            extenionID: "BOOKBACKWARD",
            icon: "arrow.left",
            onClick: {
                if let editor = app.activeEditor as? EpubEditorInstance {
                    editor.wbview.evaluateJavaScript("reader.view.goLeft()")
                }
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? EpubEditorInstance else { return false }
                return true
            }
        )
        
        let forwardItem = ToolbarItem(
            extenionID: "BOOKFORWARD",
            icon: "arrow.right",
            onClick: {
                if let editor = app.activeEditor as? EpubEditorInstance {
                    editor.wbview.evaluateJavaScript("reader.view.goRight()")
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
        
        
        
//        contribution.toolBar.registerItem(item: fontSizeItem)
        
        contribution.toolBar.registerItem(item: backwardItem)
        contribution.toolBar.registerItem(item: forwardItem)
        contribution.toolBar.registerItem(item: toolbarItem)
    }
}

class EpubEditorInstance: EditorInstanceWithURL {
    
    let wbview = WebViewBase()
    
    private let coordinator: WebCoordinator
    
    init(title: String, url: URL) {
        coordinator = WebCoordinator(url: url)
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
        let loadBookJS = """
            let base64Content = "\(base64String)"
            let bookData = Uint8Array.from(atob(base64Content), c => c.charCodeAt(0))
            bookData.byteOffset = 0
            let bookFile = new File([bookData.buffer],  "\(url.lastPathComponent)");
            openBook(bookFile)
            """
//        let jsstr = loadBookJS
//            .replacingOccurrences(of: "{{name}}", with: url.lastPathComponent)
//            .replacingFirstOccurrence(of: "{{base64Content}}", with: base64String)
        webView.evaluateJavaScript(loadBookJS)
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(250))) {
            let theme = ThemeManager.isDark() ? BookThemeManager.instance.darkTheme : BookThemeManager.instance.lightTheme
            didSetTheme(webView, theme: theme)
        }
    }
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

public struct BookTheme: Codable {
    
    // MARK: Layout

    public static let saveKey = "ReaderTheme"

    public var gap = 0.00
    public var maxInlineSize = 1080 + 1000
    public var maxBlockSize = 1440 + 1000
    public var maxColumnCount = 1
    public var flow = false
    public var animated = true
    public var margin = 0

    // MARK: Style

    public var lineHeight = 1.5
    public var justify = true
    public var hyphenate = true
    public var fontSize = 100

    // MARK: Book Theme

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
