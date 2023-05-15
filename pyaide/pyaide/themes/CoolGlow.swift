//
//  CoolGlow.swift
//  Pyto
//
//  Created by Emma Labbé on 1/17/19.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import SavannaKit
import SourceEditor

// MARK: - Source code theme

// Update: From where tf did I take this theme?? I think it was in Pythonista but now I'm unable to find it anywhere else.. Did I stole the theme from Pythonista???
// Oh no it was from a code editor called TextMate I think

/// The Cool Glow source code theme.
struct CoolGlowSourceCodeTheme: SourceCodeTheme {
    
    let defaultTheme = DefaultSourceCodeTheme()
    
    var lineNumbersStyle: LineNumbersStyle? {
        return LineNumbersStyle(font: defaultTheme.font.withSize(font.pointSize), textColor: defaultTheme.lineNumbersStyle?.textColor ?? color(for: .plain))
    }
    
    var gutterStyle: GutterStyle {
        return GutterStyle(backgroundColor: backgroundColor, minimumWidth: defaultTheme.gutterStyle.minimumWidth)
    }
    
    var font: Font {
        return PTTextEditorView.font.withSize(CGFloat(ThemeFontSize))
    }
    
    let backgroundColor = Color(displayP3Red: 6/255, green: 7/255, blue: 29/255, alpha: 1)
    
    func color(for syntaxColorType: SourceCodeTokenType) -> Color {
        switch syntaxColorType {
        case .comment:
            return Color(displayP3Red: 174/255, green: 174/255, blue: 174/255, alpha: 1)
        case .editorPlaceholder:
            return defaultTheme.color(for: syntaxColorType)
        case .identifier:
            return Color(red: 96/255, green: 164/255, blue: 241/255, alpha: 1)
        case .builtin:
            return Color(red: 182/255, green: 131/255, blue: 202/255, alpha: 1)
        case .keyword:
            return Color(red: 43/255, green: 241/255, blue: 220/255, alpha: 1)
        case .number:
            return Color(red: 248/255, green: 251/255, blue: 177/255, alpha: 1)
        case .plain:
            return .white
        case .string:
            return Color(red: 146/255, green: 255/255, blue: 163/255, alpha: 1)
        }
    }
    
    func globalAttributes() -> [NSAttributedString.Key : Any] {
        
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = font
        attributes[.foregroundColor] = color(for: .plain)
        
        return attributes
    }
}

// MARK: - Theme

/// The Cool Glow theme.
struct CoolGlowTheme: PTTheme {
    
    let keyboardAppearance: UIKeyboardAppearance = .dark
    
    let barStyle: UIBarStyle = .black
    
    let sourceCodeTheme: SourceCodeTheme = CoolGlowSourceCodeTheme()
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .dark
    }
    
    var tintColor: UIColor? {
        return Color(displayP3Red: 175/255, green: 127/255, blue: 196/255, alpha: 1)
    }
    
    var consoleBackgroundColor: UIColor {
        Color(displayP3Red: 87/255, green: 87/255, blue: 102/255, alpha: 1)
    }
    
    let name: String? = "Cool Glow"
}
