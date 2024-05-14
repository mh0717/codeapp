//
//  ColorTheme+Ext.swift
//  Code
//
//  Created by Huima on 2024/5/14.
//

import Foundation

extension ThemeManager {
    static func isDark() -> Bool {
        switch UserDefaults.standard.integer(forKey: "preferredColorScheme") {
        case 0:
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return true
            } else {
                return false
            }
        case 1:
            return true
        default:
            return false
        }
    }
}
