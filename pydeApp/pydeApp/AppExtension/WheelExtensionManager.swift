//
//  WheelExtensionManager.swift
//  Code
//
//  Created by Huima on 2024/5/7.
//

import Foundation
import SwiftUI



class WheelExtensionManager: CodeAppExtension {
    
    @MainActor
    static func install(_ url: URL, app: MainApp) {
        let runnerWidget = PYRunnerWidget()
        app.popupManager.showSheet(content: AnyView(
            NavigationView(content: {
                runnerWidget.navigationTitle(Text("pip install \(url.lastPathComponent)")).padding().toolbar(content: {
                    SwiftUI.ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            app.popupManager.showSheet = false
                        }
                    }
                })
            })
            
        ))
        
        app.notificationManager.showAsyncNotification(title: localizedString(forKey: "Installing %@"), task: {
            let result = await withCheckedContinuation { continuation in
                let cmd = "pip3 install \(url.path)"
                runnerWidget.consoleView.feed(text: "\(cmd)\r\n")
                runnerWidget.consoleView.executor?.dispatch(command: "remote \(cmd) --user", completionHandler: { rlt in
                    continuation.resume(returning: rlt)
                })
                
            }
            
            
            if result == 0 {
                let msg = String(format: localizedString(forKey: "Successfully installed %@"), url.lastPathComponent)
                runnerWidget.consoleView.feed(text: msg)
            } else {
                let msg = String(format: localizedString(forKey: "Failed to install %@"), url.lastPathComponent)
                runnerWidget.consoleView.feed(text: msg)
            }
                
            runnerWidget.consoleView.feed(text: "\r\n")
            runnerWidget.consoleView.feed(text: runnerWidget.consoleView.executor.prompt)
            
            if result == 0 {
                app.notificationManager.showSucessMessage(localizedString(forKey: "Successfully installed %@"), url.lastPathComponent)
            } else {
                app.notificationManager.showErrorMessage(localizedString(forKey: "Failed to install %@"), url.lastPathComponent)
            }
            
        }, url.lastPathComponent)
    }
    

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let installToolItem = ToolbarItem(
            extenionID: "WHELL",
            icon: "arrow.down.to.line.compact",
            onClick: {
                guard let editor = app.activeEditor as? EditorInstanceWithURL, editor.url.pathExtension.lowercased() == "whl"  else {
                    return
                }
                
                DispatchQueue.main.async {
                    WheelExtensionManager.install(editor.url, app: app)
                }
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
            DispatchQueue.main.async {
                WheelExtensionManager.install(url, app: app)
            }
        }
        
        app.extensionManager.fileMenuManager.registerItem(item: installItem)

    }
    
    
}
