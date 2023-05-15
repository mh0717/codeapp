//
//  Sunset.swift
//  Pyto
//
//  Created by Emma Labbé on 1/16/19.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import SavannaKit
import SourceEditor

// MARK: - Source code theme

/// The Sunset source code theme.
struct SunsetSourceCodeTheme: SourceCodeTheme {
    
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
    
    let backgroundColor = Color(displayP3Red: 255/255, green: 252/255, blue: 229/255, alpha: 1)
    
    func color(for syntaxColorType: SourceCodeTokenType) -> Color {
        switch syntaxColorType {
        case .comment:
            return Color(displayP3Red: 195/255, green: 116/255, blue: 28/255, alpha: 1)
        case .editorPlaceholder:
            return defaultTheme.color(for: syntaxColorType)
        case .identifier:
            return Color(red: 71/255, green: 106/255, blue: 151/255, alpha: 1)
        case .builtin:
            return Color(red: 180/255, green: 69/255, blue: 0/255, alpha: 1)
        case .keyword:
            return Color(red: 41/255, green: 66/255, blue: 119/255, alpha: 1)
        case .number:
            return Color(red: 41/255, green: 66/255, blue: 119/255, alpha: 1)
        case .plain:
            return .black
        case .string:
            return Color(red: 223/255, green: 7/255, blue: 0/255, alpha: 1)
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

/// The Sunset theme.
struct SunsetTheme: PTTheme {
    
    let keyboardAppearance: UIKeyboardAppearance = .default
    
    let barStyle: UIBarStyle = .default
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .light
    }
    
    let sourceCodeTheme: SourceCodeTheme = SunsetSourceCodeTheme()
    
    var consoleBackgroundColor: UIColor {
        Color(red: 255/255, green: 248/255, blue: 191/255, alpha: 1)
    }
    
    let name: String? = "Sunset"
}
