//
//  CodeView.swift
//  Pyto
//
//  Created by Emma on 12-03-22.
//  Copyright © 2022 Emma Labbé. All rights reserved.
//

import SwiftUI
import Highlightr

struct CodeView: View {
    
    var code: String
    
    var fontSize: CGFloat?
    
    var language = "python"
    
    @Environment(\.colorScheme) var colorScheme
    
    func attributedString(colorScheme: ColorScheme) -> NSAttributedString {
        let highlightr = Highlightr()
//        #if MAIN
        let theme: PTTheme = colorScheme == .light ? XcodeLightTheme() : XcodeDarkTheme()
        let highlightrTheme = HighlightrTheme(themeString: theme.css)
        highlightrTheme.setCodeFont(PTCodeTextView.font.withSize(fontSize ?? CGFloat(ThemeFontSize)))
        highlightrTheme.themeBackgroundColor = theme.sourceCodeTheme.backgroundColor
        highlightrTheme.themeTextColor = theme.sourceCodeTheme.color(for: .plain)
        
        highlightr.theme = highlightrTheme
//        #else
//        highlightr.setTheme(to: "xcode")
//        highlightr.theme.setCodeFont(fontSize == nil ? ExceptionView.viewUIFont : ExceptionView.viewUIFont.withSize(fontSize!))
//        #endif
        return highlightr.highlight(code, as: language) ?? NSAttributedString(string: "")
    }
    
    var body: some View {
        HStack {
//            #if !PREVIEW
            if #available(iOS 15, *) {
                Text(AttributedString(attributedString(colorScheme: colorScheme)))
            } else {
                Text(code).font(.custom("Menlo", size: 17))
            }
//            #else
//            Text(code).font(.custom("Menlo", size: 17))
//            #endif
            Spacer()
        }
    }
}
