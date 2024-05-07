//
//  WebManager.swift
//  Code
//
//  Created by Huima on 2024/5/7.
//

import Foundation
import SwiftUI

class WebExtensionManager: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let toolbarItem = ToolbarItem(
            extenionID: "WEBCONTROL",
            icon: "globe",
            onClick: {
                
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? PYWebEditorInstance else { return false }
                return true
            },
            menuItems: [
                ToolbarMenuItem(icon: "globe", title: "Change URL", onClick: {
                    guard let editor = app.activeEditor as? PYWebEditorInstance else {
                        return
                    }
                    app.pyapp.addressUrl = editor.webView.url?.absoluteString ?? ""
                    app.pyapp.showAddressbar = true
                }),
                ToolbarMenuItem(icon: "arrow.left", title: "Backward", onClick: {
                    guard let editor = app.activeEditor as? PYWebEditorInstance else {
                        return
                    }
                    editor.webView.goBack()
                }),
                ToolbarMenuItem(icon: "arrow.right", title: "Forward", onClick: {
                    guard let editor = app.activeEditor as? PYWebEditorInstance else {
                        return
                    }
                    editor.webView.goForward()
                }),
                ToolbarMenuItem(icon: "arrow.triangle.2.circlepath", title: "Refresh", onClick: {
                    guard let editor = app.activeEditor as? PYWebEditorInstance else {
                        return
                    }
                    editor.webView.reload()
                }),
            ]
        )
        
        contribution.toolBar.registerItem(item: toolbarItem)
    }
}

