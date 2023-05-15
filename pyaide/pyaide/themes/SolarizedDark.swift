//
//  SolarizedDark.swift
//  Pyto
//
//  Created by Emma Labbé on 1/17/19.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import SavannaKit
import SourceEditor

// MARK: - Source code theme

/// The Solarized Dark source code theme.
struct SolarizedDarkSourceCodeTheme: SourceCodeTheme {
    
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
    
    let backgroundColor = Color(displayP3Red: 0/255, green: 43/255, blue: 54/255, alpha: 1)
    
    func color(for syntaxColorType: SourceCodeTokenType) -> Color {
        switch syntaxColorType {
        case .comment:
            return Color(red: 88/255, green: 110/255, blue: 117/255, alpha: 1)
        case .editorPlaceholder:
            return defaultTheme.color(for: syntaxColorType)
        case .identifier:
            return Color(red: 38/255, green: 139/255, blue: 210/255, alpha: 1)
        case .builtin:
            return Color(red: 37/255, green: 146/255, blue: 134/255, alpha: 1)
        case .keyword:
            return Color(red: 211/255, green: 54/255, blue: 130/255, alpha: 1)
        case .number:
            return Color(red: 220/255, green: 50/255, blue: 47/255, alpha: 1)
        case .plain:
            return Color(red: 147/255, green: 161/255, blue: 161/255, alpha: 1)
        case .string:
            return Color(red: 203/255, green: 75/255, blue: 22/255, alpha: 1)
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
struct SolarizedDarkTheme: PTTheme {
    
    let keyboardAppearance: UIKeyboardAppearance = .dark
    
    let barStyle: UIBarStyle = .black
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .dark
    }
    
    let sourceCodeTheme: SourceCodeTheme = SolarizedDarkSourceCodeTheme()
    
    var consoleBackgroundColor: UIColor {
        Color(displayP3Red: 0/255, green: 78/255, blue: 97/255, alpha: 1)
    }
    
    let name: String? = "Solarized Dark"
}
