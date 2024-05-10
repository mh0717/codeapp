//
//  QuickLookExtension.swift
//  Code
//
//  Created by Huima on 2024/5/6.
//

import Foundation

class QuickLookExtension: CodeAppExtension {
    
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let item = FileMenuItem(iconSystemName: "eye", title: "Open with QuickLook") { url in
            return !url.isDirectory
        } onClick: { url in
//            let vc = QuickPreviewController(url)
//            NotificationCenter.default.post(name: Notification.Name("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": vc])
            let vc = QuickPreviewController(url)
            let editor = VCInTabEditorInstance(url: url, title: url.lastPathComponent, vc: vc)
            DispatchQueue.main.async {
                app.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
            }
        }
        
        app.extensionManager.fileMenuManager.registerItem(item: item)
    }
}
