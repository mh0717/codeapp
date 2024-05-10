//
//  LocalizedUtils.swift
//  pydeApp
//
//  Created by Huima on 2024/3/9.
//

import Foundation


func localizedString(forKey key: String) -> String {
    var result = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

    if result == key {
        result = Bundle.main.localizedString(forKey: key, value: nil, table: "PydeLocalizable")
    }

    return result
}


func localizedString(_ key: String, comment: String = "") -> String {
    var result = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

    if result == key {
        result = Bundle.main.localizedString(forKey: key, value: nil, table: "PydeLocalizable")
    }

    return result
}
