//
//  Plugin.swift
//  Code
//
//  Created by huima on 2025/4/10.
//

import Foundation

@objc(Plugin)
protocol Plugin: NSObjectProtocol {
    init()

    func sayHello()
    
    func runRemote(_ path: String) -> Int
}
