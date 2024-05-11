//
//  URL+Ext.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import Foundation


extension URL {
    func isInBundle() -> Bool {
        return self.path.hasPrefix(Bundle.main.bundlePath)
    }
}
