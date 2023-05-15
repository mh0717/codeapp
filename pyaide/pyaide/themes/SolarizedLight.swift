//
//  SolarizedLight.swift
//  Pyto
//
//  Created by Emma Labbé on 1/17/19.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import SavannaKit
import SourceEditor

// MARK: - Source code theme

/// The Solarized Light source code theme.
struct SolarizedLightSourceCodeTheme: SourceCodeTheme {
    
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
    
    let backgroundColor = Color(displayP3Red: 252/255, green: 244/255, blue: 220/255, alpha: 1)
    
    func color(for syntaxColorType: SourceCodeTokenType) -> Color {
        switch syntaxColorType {
        case .comment:
            return Color(red: 147/255, green: 161/255, blue: 161/255, alpha: 1)
        case .editorPlaceholder:
            return defaultTheme.color(for: syntaxColorType)
        case .identifier:
            return Color(red: 33/255, green: 118/255, blue: 199/255, alpha: 1)
        case .builtin:
            return Color(red: 37/255, green: 146/255, blue: 134/255, alpha: 1)
        case .keyword:
            return Color(red: 211/255, green: 54/255, blue: 130/255, alpha: 1)
        case .number:
            return Color(red: 220/255, green: 50/255, blue: 47/255, alpha: 1)
        case .plain:
            return Color(red: 88/255, green: 110/255, blue: 117/255, alpha: 1)
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

#if os(iOS)

/// The Cool Glow theme.
struct SolarizedLightTheme: PTTheme {
    
    let keyboardAppearance: UIKeyboardAppearance = .default
    
    let barStyle: UIBarStyle = .default
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .light
    }
    
    let sourceCodeTheme: SourceCodeTheme = SolarizedLightSourceCodeTheme()
    
    var consoleBackgroundColor: UIColor {
        Color(displayP3Red: 252/255, green: 235/255, blue: 182/255, alpha: 1)
    }
    
    let name: String? = "Solarized Light"
}

#endif
