//
//  EditorTheme_.swift
//  Pyto
//
//  Created by Emma Labbé on 1/15/19.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import SourceEditor
import SavannaKit
import UIKit

extension UIColor {
    
    /// Returns an hexadecimal color representation as String.
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: nil)

        if r < 0 {
            r = 0
        } else if r > 1 {
            r = 1
        }
        
        if g < 0 {
            g = 0
        } else if g > 1 {
            g = 1
        }
        
        if b < 0 {
            b = 0
        } else if b > 1 {
            b = 1
        }
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
    }
    
    /// Returns a color from a hexadecimal string.
    ///
    /// - Parameters:
    ///     - hexString: Hexadecimal string.
    ///     - alpha: The alpha of the color.
    convenience init(hexString: String, alpha: CGFloat = 1) {
        let chars = Array(hexString.dropFirst())
        self.init(red:   .init(strtoul(String(chars[0...1]),nil,16))/255,
                  green: .init(strtoul(String(chars[2...3]),nil,16))/255,
                  blue:  .init(strtoul(String(chars[4...5]),nil,16))/255,
                  alpha: alpha)
    }
    
    /// Returns a color from given data.
    ///
    /// - Parameters:
    ///     - data: Data representing the color.
    ///
    /// - Returns: The color represented by `data`.
    class func color(withData data:Data) -> UIColor {
        return try! NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)!
    }

    /// Encodes the color into data.
    ///
    /// - Returns: Data.
    func encode() -> Data {
         return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
}


/// A protocol for implementing an editor and console theme.
protocol PTTheme {
    
    /// The keyboard appearance used in the editor and the console.
    var keyboardAppearance: UIKeyboardAppearance { get }
    
    /// The navigation and tool bar style.
    var barStyle: UIBarStyle { get }
    
    /// The source code theme type.
    var sourceCodeTheme: SourceCodeTheme { get }
    
    /// The user interface style applied to the editor and the console.
    var userInterfaceStyle: UIUserInterfaceStyle { get }
    
    /// The tint color of the interface.
    var tintColor: UIColor? { get }
    
    /// The background color of the console
    var consoleBackgroundColor: UIColor { get }
    
    /// The name of the theme if created by user.
    var name: String? { get }
    
    /// The data corresponding to the theme.
    var data: Data { get }
}

extension PTTheme {
    
    var tintColor: UIColor? {
        return .systemGreen
    }
    
    var name: String? {
        return nil
    }
    
    var consoleBackgroundColor: UIColor {
        sourceCodeTheme.backgroundColor
    }
    
    var data: Data {
        var str = ""
        
        str += name ?? ""
        str += "\n"
        
        if userInterfaceStyle == .dark {
            str += "dark\n"
        } else if userInterfaceStyle == .light {
            str += "light\n"
        } else {
            str += "default\n"
        }
        
        str += "\((tintColor ?? .systemGreen).encode().base64EncodedString())\n"
        
        let tokens: [SourceCodeTokenType] = [.comment, .editorPlaceholder, .identifier, .keyword, .number, .plain, .string]
        
        for token in tokens {
            str += "\(sourceCodeTheme.color(for: token).encode().base64EncodedString())\n"
        }
        
        str += "\(sourceCodeTheme.backgroundColor.encode().base64EncodedString())\n"
        
        str += "\(#colorLiteral(red: 0.6745098039, green: 0.1921568627, blue: 0.1921568627, alpha: 1).encode().base64EncodedString())\n"
        str += "\(#colorLiteral(red: 0.7254901961, green: 0.4784313725, blue: 0.09803921569, alpha: 1).encode().base64EncodedString())\n"
        
        str += "\(sourceCodeTheme.color(for: .builtin).encode().base64EncodedString())\n"
        
        str += "\(consoleBackgroundColor.encode().base64EncodedString())\n"
        
        return str.data(using: .utf8) ?? Data()
    }
}

extension PTTheme {
    
    /// Returns CSS to be used with Highlightr.
    var css: String {
        
        return ".hljs{display:block;overflow-x:auto;padding:.5em;background:\(sourceCodeTheme.backgroundColor.hexString);color:\(sourceCodeTheme.color(for: .plain).hexString)}.hljs-comment,.hljs-quote{color:\(sourceCodeTheme.color(for: .comment) .hexString)}.hljs-keyword,.hljs-literal,.hljs-selector-tag,.hljs-tag,.hljs-section{color:\(sourceCodeTheme.color(for: .keyword) .hexString)}.hljs-name,.hljs-type{color:\(sourceCodeTheme.color(for: .keyword) .hexString)}.hljs-template-variable,.hljs-variable{color:\(sourceCodeTheme.color(for: .identifier).hexString)}.hljs-string{color:\(sourceCodeTheme.color(for: .string) .hexString)}.hljs-link,.hljs-regexp{color:#080}.hljs-bullet,.hljs-meta,.hljs-symbol,.hljs-title{color:\(sourceCodeTheme.color(for: .identifier).hexString)}.hljs-number{color:\(sourceCodeTheme.color(for: .number).hexString)}.hljs-attr,.hljs-class{color:\(sourceCodeTheme.color(for: .identifier).hexString)}.hljs-params{color:\(sourceCodeTheme.color(for: .plain).hexString)}.hljs-attribute,.hljs-subst{color:\(sourceCodeTheme.color(for: .identifier) .hexString)}.hljs-built_in,.hljs-builtin-name{color: \(sourceCodeTheme.color(for: .builtin).hexString)}"
    }
}

/// Returns a theme from given data.
///
/// - Parameters:
///     - data: Data from `Theme.data`
///
/// - Returns: Decoded theme.
func ThemeFromData(_ data: Data) -> PTTheme? {
    
    guard let str = String(data: data, encoding: .utf8) else {
        return nil
    }
    
    let comp = str.components(separatedBy: "\n")
    
    guard comp.count >= 13 else {
        return nil
    }
    
    struct CustomSourceCodeTheme: SourceCodeTheme {
        
        static func decodedColor(from string: String) -> UIColor {
            if let data = Data(base64Encoded: string) {
                return UIColor.color(withData: data)
            } else {
                return .black
            }
        }
        
        let defaultTheme = DefaultSourceCodeTheme()
        
        var comp: [String]
        
        func color(for syntaxColorType: SourceCodeTokenType) -> Color {
            switch syntaxColorType {
            case .comment:
                return CustomSourceCodeTheme.decodedColor(from: comp[3])
            case .editorPlaceholder:
                return CustomSourceCodeTheme.decodedColor(from: comp[4])
            case .identifier:
                return CustomSourceCodeTheme.decodedColor(from: comp[5])
            case .builtin:
                return CustomSourceCodeTheme.decodedColor(from: (comp.indices.contains(13) && !comp[13].isEmpty) ? comp[13] : comp[5])
            case .keyword:
                return CustomSourceCodeTheme.decodedColor(from: comp[6])
            case .number:
                return CustomSourceCodeTheme.decodedColor(from: comp[7])
            case .plain:
                return CustomSourceCodeTheme.decodedColor(from: comp[8])
            case .string:
                return CustomSourceCodeTheme.decodedColor(from: comp[9])
            }
        }
        
        func globalAttributes() -> [NSAttributedString.Key : Any] {
            
            var attributes = [NSAttributedString.Key: Any]()
            
            attributes[.font] = font
            attributes[.foregroundColor] = color(for: .plain)
            
            return attributes
        }
        
        var lineNumbersStyle: LineNumbersStyle? {
            return LineNumbersStyle(font: defaultTheme.font.withSize(font.pointSize), textColor: defaultTheme.lineNumbersStyle?.textColor ?? color(for: .plain))
        }
        
        var gutterStyle: GutterStyle {
            return GutterStyle(backgroundColor: backgroundColor, minimumWidth: defaultTheme.gutterStyle.minimumWidth)
        }
        
        var font: Font {
            return PTCodeTextView.font.withSize(CGFloat(ThemeFontSize))
        }
        
        var backgroundColor: Color {
            return CustomSourceCodeTheme.decodedColor(from: comp[10])
        }
    }
    
    let name = comp[0]
    let userInterfaceStyle: UIUserInterfaceStyle = (comp[1] == "dark" ? .dark : (comp[1] == "light" ? .light : .unspecified))
    let tint = CustomSourceCodeTheme.decodedColor(from: comp[2])
    
    struct CustomTheme: PTTheme {
        var keyboardAppearance: UIKeyboardAppearance
        
        var barStyle: UIBarStyle
        
        var sourceCodeTheme: SourceCodeTheme
        
        var userInterfaceStyle: UIUserInterfaceStyle
        
        var name: String?
        
        var tintColor: UIColor?
        
        var exceptionColor: UIColor
        
        var warningColor: UIColor
        
        var consoleBackgroundColor: UIColor
    }
    
    let sourceCodeTheme = CustomSourceCodeTheme(comp: comp)
    return CustomTheme(keyboardAppearance: (userInterfaceStyle == .dark ? .dark : (userInterfaceStyle == .light ? .light : .default)), barStyle: (userInterfaceStyle == .dark ? .black : .default), sourceCodeTheme: sourceCodeTheme, userInterfaceStyle: userInterfaceStyle, name: name, tintColor: tint, exceptionColor: CustomSourceCodeTheme.decodedColor(from: comp[11]), warningColor: CustomSourceCodeTheme.decodedColor(from: comp[12]), consoleBackgroundColor: (comp.indices.contains(14) && !comp[14].isEmpty) ? CustomSourceCodeTheme.decodedColor(from: comp[14]) : sourceCodeTheme.backgroundColor)
}

/// A dictionary with all themes.
var Themes: [(name: String, value: PTTheme)] {
    var themes: [(name: String, value: PTTheme)] = [
        (name: "Xcode Light", value: XcodeLightTheme()),
        (name: "Xcode Dark", value: XcodeDarkTheme()),
        (name: "Basic", value: BasicTheme()),
        (name: "Dusk", value: DuskTheme()),
        (name: "LowKey", value: LowKeyTheme()),
        (name: "Midnight", value: MidnightTheme()),
        (name: "Sunset", value: SunsetTheme()),
        (name: "WWDC16", value: WWDC16Theme()),
        (name: "Cool Glow", value: CoolGlowTheme()),
        (name: "Solarized Light", value: SolarizedLightTheme()),
        (name: "Solarized Dark", value: SolarizedDarkTheme())
    ]
    
//    if #available(iOS 13.0, *) {
//        for theme in ThemeMakerTableViewController.themes {
//            themes.append((name: theme.name ?? "", value: theme))
//        }
//    }
//
    return themes
}

/// A notification sent when the user choosed theme.
let ThemeDidChangeNotification = Notification.Name("ThemeDidChangeNotification")

/// The font size used on the editor.
var ThemeFontSize: Int {
    get {
        return (UserDefaults.standard.value(forKey: "fontSize") as? Int) ?? 13
    }
    
    set {
        UserDefaults.standard.set(newValue, forKey: "fontSize")
        UserDefaults.standard.synchronize()
    }
}

