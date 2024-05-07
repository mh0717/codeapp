//
//  WheelExtensionManager.swift
//  Code
//
//  Created by Huima on 2024/5/7.
//

import Foundation
import SwiftUI



class WheelExtensionManager: CodeAppExtension {
    
    static func install(_ url: URL, app: MainApp) {
        
    }
    

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let installToolItem = ToolbarItem(
            extenionID: "WHELL",
            icon: "arrow.down.to.line.compact",
            onClick: {
                guard let editor = app.activeEditor as? EditorInstanceWithURL, editor.url.pathExtension.lowercased() == "whl"  else {
                    return
                }
                
                WheelExtensionManager.install(editor.url, app: app)
            },
            shouldDisplay: {
                guard let editor = app.activeEditor as? EditorInstanceWithURL, editor.url.pathExtension.lowercased() == "whl"  else {
                    return false
                }
                return true
            }
        )
        
        
        contribution.toolBar.registerItem(item: installToolItem)
        
        let installItem = FileMenuItem(iconSystemName: "arrow.down.to.line.compact", title: "Install") { url in
            url.pathExtension.lowercased() == "whl"
        } onClick: { url in
            WheelExtensionManager.install(url, app: app)
        }
        
        app.extensionManager.fileMenuManager.registerItem(item: installItem)

    }
    
    
}
