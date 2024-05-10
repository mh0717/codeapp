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
                ToolbarMenuItem(icon: "arrow.triangle.2.circlepath", title: "Refresh", onClick: {
                    guard let editor = app.activeEditor as? PYWebEditorInstance else {
                        return
                    }
                    editor.webView.reload()
                }),
                ToolbarMenuItem(icon: "safari", title: "Open in safari", onClick: {
                    guard let editor = app.activeEditor as? PYWebEditorInstance else {
                        return
                    }
                    if let url = editor.webView.url {
                        UIApplication.shared.open(url)
                    }
                }),
            ]
        )
        
        
        
        let backwardItem = ToolbarItem(
            extenionID: "WEBBACKWARD",
            icon: "arrow.left",
            onClick: {
                guard let editor = app.activeEditor as? PYWebEditorInstance else {
                    return
                }
                editor.webView.goBack()
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? PYWebEditorInstance else { return false }
                return true
            }
        )
        
        let forwardItem = ToolbarItem(
            extenionID: "WEBFORWARD",
            icon: "arrow.right",
            onClick: {
                guard let editor = app.activeEditor as? PYWebEditorInstance else {
                    return
                }
                editor.webView.goForward()
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? PYWebEditorInstance else { return false }
                return true
            }
        )
        
        contribution.toolBar.registerItem(item: backwardItem)
        contribution.toolBar.registerItem(item: forwardItem)
        contribution.toolBar.registerItem(item: toolbarItem)
    }
}

