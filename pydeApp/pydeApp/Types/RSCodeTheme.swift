import Runestone
import RunestoneTomorrowTheme
import RunestoneThemeCommon
import RunestoneOneDarkTheme
import UIKit
import ExCodable

public class RSScope {
    public private(set) var fontStyle: String = ""
    public private(set) var name: String = ""
    public private(set) var fontWeight: String = ""
    public private(set) var color: String = ""
    
    required public init(from decoder: Decoder) throws {
        try decodeReference(from: decoder, with: Self.keyMapping)
    }
}

extension RSScope: ExCodable {
    public static var keyMapping: [KeyMap<RSScope>] = [
        KeyMap(ref: \.fontStyle, to: "fontStyle"),
        KeyMap(ref: \.name, to: "name"),
        KeyMap(ref: \.fontWeight, to: "fontWeight"),
        KeyMap(ref: \.color, to: "color"),
    ]
    
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
    }
}

public class RSThemeGutter {

    public private(set) var lineNumber: String = ""
    public private(set) var selectedLinesBackground: String = ""
    public private(set) var hairline: String = ""
    public private(set) var selectedLinesLineNumber: String = ""
    public private(set) var background: String = ""
    
    public init() {
        
    }
    
    required public init(from decoder: Decoder) throws {
        try decodeReference(from: decoder, with: Self.keyMapping)
    }
}

extension RSThemeGutter: ExCodable {
    public static var keyMapping: [KeyMap<RSThemeGutter>] = [
        KeyMap(ref: \.lineNumber, to: "lineNumber"),
        KeyMap(ref: \.selectedLinesBackground, to: "selectedLinesBackground"),
        KeyMap(ref: \.hairline, to: "hairline"),
        KeyMap(ref: \.selectedLinesLineNumber, to: "selectedLinesLineNumber"),
        KeyMap(ref: \.background, to: "background"),
    ]
    
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
    }
    
}

public class RSThemeEditor {
    public private(set) var invisibleCharacters: String = ""
//            "gutter": {
//                "lineNumber": "#0000004D",
//                "selectedLinesBackground": "#0000001A",
//                "hairline": "#0000004D",
//                "selectedLinesLineNumber": "#00000099",
//                "background": "#EFEFEF"
//            },
//            "pageGuide": { "hairline": "#0000004D", "background": "#EFEFEF" },
    public private(set) var highlightedTextBackground: String = ""
    public private(set) var insertedTextBackground: String = ""
    public private(set) var text: String = ""
    public private(set) var selectedLineBackground: String = ""
    public private(set) var background: String = ""
    public private(set) var scrollIndicatorStyle: String = ""
    public private(set) var removedTextBackground: String = ""
    public private(set) var caret: String = ""
    public private(set) var gutter: RSThemeGutter = RSThemeGutter()
    
    init() {
        
    }
    
    required public init(from decoder: Decoder) throws {
        try decodeReference(from: decoder, with: Self.keyMapping)
    }
}





extension RSThemeEditor: ExCodable {
    public static var keyMapping: [KeyMap<RSThemeEditor>] = [
        KeyMap(ref: \.invisibleCharacters, to: "invisibleCharacters"),
        KeyMap(ref: \.highlightedTextBackground, to: "highlightedTextBackground"),
        KeyMap(ref: \.insertedTextBackground, to: "insertedTextBackground"),
        KeyMap(ref: \.text, to: "text"),
        KeyMap(ref: \.selectedLineBackground, to: "selectedLineBackground"),
        KeyMap(ref: \.background, to: "background"),
        KeyMap(ref: \.scrollIndicatorStyle, to: "scrollIndicatorStyle"),
        KeyMap(ref: \.removedTextBackground, to: "removedTextBackground"),
        KeyMap(ref: \.caret, to: "caret"),
        KeyMap(ref: \.gutter, to: "gutter"),
    ]
    
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
    }
    
    
}

public class RSThemeRoot {
    public private(set) var scopes: [RSScope] = []
    public private(set) var editor: RSThemeEditor = RSThemeEditor()
    
    init() {
        
    }
    
    required public init(from decoder: Decoder) throws {
        try decodeReference(from: decoder, with: Self.keyMapping)
    }
}

extension RSThemeRoot: ExCodable {
    public static var keyMapping: [KeyMap<RSThemeRoot>] = [
        KeyMap(ref: \.scopes, to: "scopes"),
        KeyMap(ref: \.editor, to: "editor"),
    ]
    
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
    }
    
    
}

public class RSCodeLocalTheme : EditorTheme {
    public var backgroundColor: UIColor
    
    public var userInterfaceStyle: UIUserInterfaceStyle
    
    public var font: UIFont
    
    public var textColor: UIColor
    
    public var gutterBackgroundColor: UIColor
    
    public var gutterHairlineColor: UIColor
    
    public var lineNumberColor: UIColor
    
    public var lineNumberFont: UIFont
    
    public var selectedLineBackgroundColor: UIColor
    
    public var selectedLinesLineNumberColor: UIColor
    
    public var selectedLinesGutterBackgroundColor: UIColor
    
    public var invisibleCharactersColor: UIColor
    
    public var pageGuideHairlineColor: UIColor
    
    public var pageGuideBackgroundColor: UIColor
    
    public var markedTextBackgroundColor: UIColor
    
    public func textColor(for highlightName: String) -> UIColor? {
        if let scope = theme.scopes.first(where: {$0.name == highlightName}) {
            return UIColor(hex: scope.color) ?? textColor
        }
        
        return textColor
    }
    
    let theme: RSThemeRoot
    
    public init(_ theme: RSThemeRoot) {
        self.theme = theme
        backgroundColor = UIColor.init(hex: theme.editor.background) ?? UIColor.white
        userInterfaceStyle = .light
        font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textColor = UIColor.init(hex: theme.editor.text) ?? UIColor.black
        gutterBackgroundColor = UIColor.init(hex: theme.editor.gutter.background) ?? UIColor.white
        gutterHairlineColor = UIColor.init(hex: theme.editor.gutter.background) ?? UIColor.white
        lineNumberColor = UIColor.init(hex: theme.editor.gutter.lineNumber) ?? UIColor.black
        lineNumberFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
        selectedLineBackgroundColor = UIColor.init(hex: theme.editor.selectedLineBackground) ?? UIColor.white
        selectedLinesLineNumberColor = UIColor.init(hex: theme.editor.gutter.selectedLinesLineNumber) ?? UIColor.white
        selectedLinesGutterBackgroundColor = UIColor.init(hex: theme.editor.gutter.selectedLinesBackground) ?? UIColor.white
        invisibleCharactersColor = UIColor.init(hex: theme.editor.invisibleCharacters) ?? UIColor.black
        pageGuideHairlineColor = UIColor.init(hex: theme.editor.gutter.hairline) ?? UIColor.black
        pageGuideBackgroundColor = UIColor.init(hex: theme.editor.gutter.background) ?? UIColor.black
        markedTextBackgroundColor = UIColor.init(hex: theme.editor.highlightedTextBackground) ?? textColor.withAlphaComponent(0.2)
        
    }
    
    static var light: RSCodeLocalTheme =  {
        let jsonStr = try! String(contentsOfFile: Bundle.main.bundleURL.appendingPathComponent("RSThemes/Light+.json").path)
        let root = try! jsonStr.decoded() as RSThemeRoot
        return RSCodeLocalTheme(root)
    }()
    
    static var dark: RSCodeLocalTheme =  {
        let jsonStr = try! String(contentsOfFile: Bundle.main.bundleURL.appendingPathComponent("RSThemes/Dark+.json").path)
        let root = try! jsonStr.decoded() as RSThemeRoot
        return RSCodeLocalTheme(root)
    }()
}

public class RSCodeCodeTheme: EditorTheme {
    let localTheme: EditorTheme
    
    public let backgroundColor: UIColor
    public let userInterfaceStyle: UIUserInterfaceStyle

    public let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
    public let textColor: UIColor
    
    /// 行号背景色
    public let gutterBackgroundColor: UIColor
    /// 行号与内容分隔线颜色
    public let gutterHairlineColor: UIColor = .clear

    public let lineNumberColor: UIColor
    public let lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    public let selectedLineBackgroundColor: UIColor
    public let selectedLinesLineNumberColor: UIColor
    public let selectedLinesGutterBackgroundColor: UIColor = .clear

    public let invisibleCharactersColor: UIColor

    public let pageGuideHairlineColor: UIColor
    public let pageGuideBackgroundColor: UIColor

    public let markedTextBackgroundColor: UIColor
    public let markedTextBackgroundCornerRadius: CGFloat = 4
    
    public let commentColor: UIColor
    public let operatorColor: UIColor
    public let punctuationColor: UIColor
    public let propertyColor: UIColor
    public let functionColor: UIColor
    public let stringColor: UIColor
    public let numberColor: UIColor
    public let keywordColor: UIColor
    public let variableBuildinColor: UIColor
    public let variableColor: UIColor
    
//    private func toUIColor(_ color: String) -> UIColor {
//        return UIColor()
//    }

    public init(theme: [String: Any], isDark: Bool) {
        localTheme = isDark ? RSCodeLocalTheme.dark : RSCodeLocalTheme.light
        
        let toUIColor: (_ color: String?) -> UIColor? =  {color in
            guard let color else {return nil}
            if color.starts(with: "#") {
                if let ucolor = UIColor(hex: color) {
                    return ucolor
                }
            }
            return nil
        }
        let colors = theme["colors"] as? [String: Any] ?? [:]
        let forgroundColor =  toUIColor((colors["foreground"] ?? colors["editor.foreground"] ?? colors["input.foreground"] ?? colors["tab.activeForeground"])as? String) ?? localTheme.textColor
        backgroundColor = toUIColor(colors["editor.background"] as? String) ?? localTheme.backgroundColor
        userInterfaceStyle = isDark ? .dark : .light
        textColor = forgroundColor
        gutterBackgroundColor = toUIColor((colors["editorGutter.background"] ?? colors["editor.background"])as? String) ?? localTheme.gutterBackgroundColor
        lineNumberColor = toUIColor(colors["editorLineNumber.foreground"] as? String) ?? localTheme.lineNumberColor
        selectedLineBackgroundColor = toUIColor(colors["editor.lineHighlightBackground"] as? String) ?? localTheme.selectedLineBackgroundColor
        selectedLinesLineNumberColor = toUIColor(colors["editorLineNumber.activeForeground"] as? String) ?? localTheme.selectedLinesLineNumberColor
        invisibleCharactersColor = forgroundColor/*.withAlphaComponent(0.7)*/
        pageGuideHairlineColor = localTheme.pageGuideHairlineColor
        pageGuideBackgroundColor = localTheme.pageGuideBackgroundColor
        markedTextBackgroundColor = toUIColor((colors["editor.selectionBackground"]) as? String )?.withAlphaComponent(0.5) ?? localTheme.markedTextBackgroundColor
        
        var tokenColors = [String: String]()
        if let colors = theme["tokenColors"] as? [[String: Any]] {
            colors.forEach { item in
                if let name = item["name"] as? String,
                   let setting = item["settings"] as? [String: Any],
                   let color = setting["foreground"] as? String {
                    tokenColors[name] = color
                }
            }
        }
        
        commentColor = toUIColor(tokenColors["Comment"]) ?? localTheme.textColor(for: "comment") ?? localTheme.textColor
        operatorColor = toUIColor(tokenColors["Operators"]) ?? localTheme.textColor(for: "operator") ?? localTheme.textColor
        punctuationColor = toUIColor(tokenColors["Punctuation"]) ?? localTheme.textColor(for: "punctuation") ?? localTheme.textColor
        
        propertyColor = toUIColor(tokenColors["Variable"])  ?? localTheme.textColor(for: "property") ?? localTheme.textColor
        functionColor = toUIColor(tokenColors["Function name"])  ?? localTheme.textColor(for: "function") ?? localTheme.textColor
        stringColor = toUIColor(tokenColors["String"])  ?? localTheme.textColor(for: "string") ?? localTheme.textColor
        numberColor = toUIColor(tokenColors["Number"])  ?? localTheme.textColor(for: "number") ?? localTheme.textColor
        keywordColor = toUIColor(tokenColors["Keyword"]) ?? localTheme.textColor(for: "keyword") ?? localTheme.textColor
        variableBuildinColor = toUIColor(tokenColors["Variable"]) ?? localTheme.textColor(for: "variable.builtin") ?? localTheme.textColor
        if let variable = tokenColors["Variable"] {
            variableColor = toUIColor(variable) ?? localTheme.textColor(for: "variable") ?? localTheme.textColor
        } else {
            variableColor = localTheme.textColor(for: "variable") ?? localTheme.textColor
        }
        
    }

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return localTheme.textColor(for: rawHighlightName)
        }
        switch highlightName {
        case .comment:
            return commentColor
        case .operator:
            return operatorColor
        case .punctuation:
            return punctuationColor
        case .property:
            return propertyColor
        case .function:
            return functionColor
        case .string:
            return stringColor
        case .number:
            return numberColor
        case .keyword:
            return keywordColor
        case .variableBuiltin:
            return variableBuildinColor
        case .variable:
//            return variableColor
            return textColor
        case .constructor:
            return functionColor
        default:
            return textColor
        }
    }

    public func fontTraits(for rawHighlightName: String) -> FontTraits {
        if let highlightName = HighlightName(rawHighlightName), highlightName == .keyword {
            return .bold
        } else {
            return []
        }
    }
}

//public class RSCodeTheme: EditorTheme {
//    public let backgroundColor: UIColor
//    public let userInterfaceStyle: UIUserInterfaceStyle
//
//    public let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
//    public let textColor: UIColor
//    
//    /// 行号背景色
//    public let gutterBackgroundColor: UIColor
//    /// 行号与内容分隔线颜色
//    public let gutterHairlineColor: UIColor = .clear
//
//    public let lineNumberColor: UIColor
//    public let lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
//
//    public let selectedLineBackgroundColor: UIColor
//    public let selectedLinesLineNumberColor: UIColor
//    public let selectedLinesGutterBackgroundColor: UIColor = .clear
//
//    public let invisibleCharactersColor: UIColor
//
//    public let pageGuideHairlineColor: UIColor
//    public let pageGuideBackgroundColor: UIColor
//
//    public let markedTextBackgroundColor: UIColor
//    public let markedTextBackgroundCornerRadius: CGFloat = 4
//    
//    public let commentColor: UIColor
//    public let operatorColor: UIColor
//    public let punctuationColor: UIColor
//    public let propertyColor: UIColor
//    public let functionColor: UIColor
//    public let stringColor: UIColor
//    public let numberColor: UIColor
//    public let keywordColor: UIColor
//    public let variableBuildinColor: UIColor
//    public let variableColor: UIColor
//    
////    private func toUIColor(_ color: String) -> UIColor {
////        return UIColor()
////    }
//
//    public init(theme: [String: Any], isDark: Bool) {
//        let toUIColor: (_ color: String) -> UIColor =  {color in
//            if color.starts(with: "#") {
//                if let ucolor = UIColor(hex: color) {
//                    return ucolor
//                }
//            }
//            return UIColor.white
//        }
//        let colors = theme["colors"] as? [String: Any] ?? [:]
//        let forgroundColor =  toUIColor((colors["foreground"] ?? colors["editor.foreground"] ?? colors["input.foreground"] ?? colors["tab.activeForeground"])as? String ?? (isDark ? "#FFFFFF" : "#000000") )
//        backgroundColor = toUIColor(colors["editor.background"] as? String ?? (isDark ? "#000000" : "#FFFFFF"))
//        userInterfaceStyle = isDark ? .dark : .light
//        textColor = forgroundColor
//        gutterBackgroundColor = toUIColor((colors["editorGutter.background"] ?? colors["editor.background"])as? String ?? "#0c0e10")
//        lineNumberColor = toUIColor(colors["editorLineNumber.foreground"] as? String ?? "#3b4651")
//        selectedLineBackgroundColor = toUIColor(colors["editor.lineHighlightBackground"] as? String ?? "#1b2025")
//        selectedLinesLineNumberColor = toUIColor(colors["editorLineNumber.activeForeground"] as? String ?? "#dfdfdf")
//        invisibleCharactersColor = forgroundColor/*.withAlphaComponent(0.7)*/
//        pageGuideHairlineColor = UIColor.red
//        pageGuideBackgroundColor = backgroundColor
//        markedTextBackgroundColor = toUIColor((colors["editor.selectionBackground"]) as? String ?? "#007aae8e").withAlphaComponent(0.5)
//        
//        var tokenColors = [String: String]()
//        if let colors = theme["tokenColors"] as? [[String: Any]] {
//            colors.forEach { item in
//                if let name = item["name"] as? String,
//                   let setting = item["settings"] as? [String: Any],
//                   let color = setting["foreground"] as? String {
//                    tokenColors[name] = color
//                }
//            }
//        }
//        
//        commentColor = toUIColor(tokenColors["Comment"] ?? "#60778c")
//        operatorColor = forgroundColor/*.withAlphaComponent(0.75)*/
//        punctuationColor = forgroundColor/*.withAlphaComponent(0.75)*/
//        propertyColor = toUIColor(tokenColors["Variable"] ?? "#019d76")
//        functionColor = toUIColor(tokenColors["Function name"] ?? "#15b8ae")
//        stringColor = toUIColor(tokenColors["String"] ?? "#7ebea0")
//        numberColor = toUIColor(tokenColors["Number"] ?? "#15b8ae")
//        keywordColor = toUIColor(tokenColors["Keyword"] ?? "#007aae")
//        variableBuildinColor = toUIColor(tokenColors["Variable"] ?? "#019d76")
//        if let variable = tokenColors["Variable"] {
//            variableColor = toUIColor(variable)
//        } else {
//            variableColor = textColor
//        }
//        
//    }
//
//    public func textColor(for rawHighlightName: String) -> UIColor? {
//        guard let highlightName = HighlightName(rawHighlightName) else {
//            return nil
//        }
//        switch highlightName {
//        case .comment:
//            return commentColor
//        case .operator:
//            return operatorColor
//        case .punctuation:
//            return punctuationColor
//        case .property:
//            return propertyColor
//        case .function:
//            return functionColor
//        case .string:
//            return stringColor
//        case .number:
//            return numberColor
//        case .keyword:
//            return keywordColor
//        case .variableBuiltin:
//            return variableBuildinColor
////        case .variable:
////            return variableColor
//        case .constructor:
//            return functionColor
//        default:
//            return textColor
//        }
//    }
//
//    public func fontTraits(for rawHighlightName: String) -> FontTraits {
//        if let highlightName = HighlightName(rawHighlightName), highlightName == .keyword {
//            return .bold
//        } else {
//            return []
//        }
//    }
//}


public class RSCodeThemeManager:  ObservableObject {
    @Published var theme: EditorTheme = OneDarkTheme()
    
    @Published var lightTheme: EditorTheme = TomorrowTheme()
    @Published var darkTheme: EditorTheme = OneDarkTheme()
    
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name("theme.updated"), object: nil, queue: nil) { notification in
            let isDark = notification.userInfo?["isDark"] as? Bool ?? true
            self.updateTheme(isDark)
        }
        updateTheme(true)
    }
    
    func updateTheme(_ isDark: Bool) {
        if let darkItem = globalDarkTheme {
            darkTheme = RSCodeCodeTheme(theme: darkItem, isDark: true)
        } else {
            darkTheme = RSCodeLocalTheme.dark
        }
        
        if let lightItem = globalLightTheme {
            lightTheme = RSCodeCodeTheme(theme: lightItem, isDark: false)
        } else {
            lightTheme = RSCodeLocalTheme.light
        }
        
        theme = isDark ? darkTheme : lightTheme
    }
}


public var rscodeThemeManager = RSCodeThemeManager()


extension UIColor {
    public convenience init?(hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6 && cString.count != 8) {
            return nil
        }
        
        var hexNumber:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&hexNumber)

        
        let r, g, b, a: CGFloat
        if cString.count == 8 {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
            self.init(red: r, green: g, blue: b, alpha: a)
            return
        }
        
        if cString.count == 6 {
            self.init(
                red: CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(hexNumber & 0x0000FF) / 255.0,
                alpha: CGFloat(1.0)
            )
            return
        }
        return nil
    }
    
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
}
