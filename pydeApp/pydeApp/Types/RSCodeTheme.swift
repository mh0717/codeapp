import Runestone
import RunestoneTomorrowTheme
import RunestoneThemeCommon
import RunestoneOneDarkTheme
import UIKit

public class RSCodeTheme: EditorTheme {
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
        let toUIColor: (_ color: String) -> UIColor =  {color in
            if color.starts(with: "#") {
                if let ucolor = UIColor(hex: color) {
                    return ucolor
                }
            }
            return UIColor.white
        }
        let colors = theme["colors"] as? [String: Any] ?? [:]
        let forgroundColor =  toUIColor((colors["foreground"] ?? colors["editor.foreground"] ?? colors["input.foreground"] ?? colors["tab.activeForeground"])as? String ?? "#dfdfdf" )
        backgroundColor = toUIColor(colors["editor.background"] as? String ?? "#101316")
        userInterfaceStyle = isDark ? .dark : .light
        textColor = forgroundColor
        gutterBackgroundColor = toUIColor((colors["editorGutter.background"] ?? colors["editor.background"])as? String ?? "#0c0e10")
        lineNumberColor = toUIColor(colors["editorLineNumber.foreground"] as? String ?? "#3b4651")
        selectedLineBackgroundColor = toUIColor(colors["editor.lineHighlightBackground"] as? String ?? "#1b2025")
        selectedLinesLineNumberColor = toUIColor(colors["editorLineNumber.activeForeground"] as? String ?? "#dfdfdf")
        invisibleCharactersColor = forgroundColor/*.withAlphaComponent(0.7)*/
        pageGuideHairlineColor = UIColor.red
        pageGuideBackgroundColor = backgroundColor
        markedTextBackgroundColor = toUIColor((colors["editor.selectionBackground"]) as? String ?? "#007aae8e").withAlphaComponent(0.5)
        
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
        
        commentColor = toUIColor(tokenColors["Comment"] ?? "#60778c")
        operatorColor = forgroundColor/*.withAlphaComponent(0.75)*/
        punctuationColor = forgroundColor/*.withAlphaComponent(0.75)*/
        propertyColor = toUIColor(tokenColors["Variable"] ?? "#019d76")
        functionColor = toUIColor(tokenColors["Function name"] ?? "#15b8ae")
        stringColor = toUIColor(tokenColors["String"] ?? "#7ebea0")
        numberColor = toUIColor(tokenColors["Number"] ?? "#15b8ae")
        keywordColor = toUIColor(tokenColors["Keyword"] ?? "#007aae")
        variableBuildinColor = toUIColor(tokenColors["Variable"] ?? "#019d76")
        if let variable = tokenColors["Variable"] {
            variableColor = toUIColor(variable)
        } else {
            variableColor = textColor
        }
        
    }

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return nil
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
//        case .variable:
//            return variableColor
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
            darkTheme = RSCodeTheme(theme: darkItem, isDark: true)
        } else {
            darkTheme = OneDarkTheme()
        }
        
        if let lightItem = globalLightTheme {
            lightTheme = RSCodeTheme(theme: lightItem, isDark: false)
        } else {
            lightTheme = TomorrowTheme()
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
