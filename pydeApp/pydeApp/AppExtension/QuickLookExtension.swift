//
//  QuickLookExtension.swift
//  Code
//
//  Created by Huima on 2024/5/6.
//

import Foundation
import SwiftUI

class QuickLookExtension: CodeAppExtension {
    
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let item = FileMenuItem(iconSystemName: "eye", title: "Open with QuickLook") { url in
            return !url.isDirectory
        } onClick: { url in
            let editor = QuickLookEditorInstance(title: url.lastPathComponent, url: url)
            DispatchQueue.main.async {
                app.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
            }
        }
        
        app.extensionManager.fileMenuManager.registerItem(item: item)
    }
}


class QuickLookEditorInstance: EditorInstanceWithURL {
    let quickVC: QuickPreviewController
    
    init(title: String, url: URL) {
        quickVC = QuickPreviewController(url)
        super.init(view: AnyView(VCRepresentable(quickVC)), title: title, url: url)
    }
}
