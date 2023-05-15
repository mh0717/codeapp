//
//  EditorTheme.swift
//  Pyto
//
//  Created by Emma Labbé on 12/21/18.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import SavannaKit
import SourceEditor

// MARK: - Source code theme

/// The Xcode source code theme.
struct XcodeLightSourceCodeTheme: SourceCodeTheme {
    
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
    
    let backgroundColor = Color.white
    
    func color(for syntaxColorType: SourceCodeTokenType) -> Color {
        switch syntaxColorType {
        case .comment:
            return Color(red: 83/255, green: 101/255, blue: 121/255, alpha: 1)
        case .editorPlaceholder:
            return defaultTheme.color(for: syntaxColorType)
        case .identifier:
            return Color(red: 50/255, green: 109/255, blue: 116/255, alpha: 1)
        case .builtin:
            return Color(red: 57/255, green: 0/255, blue: 160/255, alpha: 1)
        case .keyword:
            return Color(red: 155/255, green: 35/255, blue: 147/255, alpha: 1)
        case .number:
            return Color(red: 28/255, green: 0/255, blue: 207/255, alpha: 1)
        case .plain:
            return .black
        case .string:
            return Color(red: 196/255, green: 26/255, blue: 22/255, alpha: 1)
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

/// The Xcode theme.
struct XcodeLightTheme: PTTheme {
    
    let keyboardAppearance: UIKeyboardAppearance = .default
    
    let barStyle: UIBarStyle = .default
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .light
    }
    
    let sourceCodeTheme: SourceCodeTheme = XcodeLightSourceCodeTheme()
    
    var consoleBackgroundColor: UIColor {
        .secondarySystemBackground
    }
    
    let name: String? = "Xcode Light"
}
