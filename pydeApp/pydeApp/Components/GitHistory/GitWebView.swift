//
//  GitWebView.swift
//  pydeApp
//
//  Created by Huima on 2023/11/21.
//

import SwiftUI
import pydeCommon


fileprivate class GitWebViewBase: WKWebView {
    
    var isMessageHandlerAdded = false
    
    init() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "shouldAllowUserInstalledFonts")
        super.init(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            self.isInspectable = true
        }
        contentMode = .scaleToFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct GitWebView: UIViewRepresentable {
    
    @EnvironmentObject var App: MainApp
    
    
    private let webView = GitWebViewBase()
    
    
    
    func makeUIView(context: Context) -> WKWebView {
        if !webView.isMessageHandlerAdded {
            let url = ConstantManager.GIT_HISTORY_H5_RUL
            let request = URLRequest(url: url)
            webView.load(request)
            
            let contentManager = webView.configuration.userContentController
            webView.isMessageHandlerAdded = true
            contentManager.add(context.coordinator, name: "toggleGitMessageHandler")
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
    
    func makeCoordinator() -> GitWebView.Coordinator {
        Coordinator(self, env: App)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler,
        WKNavigationDelegate
    {

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
//            control.App.stateManager.isMonacoEditorInitialized = false
            webView.reload()
        }

        

        func userContentController(
            _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
        ) {
            guard let result = message.body as? [String: AnyObject] else {
                return
            }
            guard let event = result["Event"] as? String else { return }

            switch event {
            case "focus":
                let notification = Notification(
                    name: Notification.Name("editor.focus"),
                    userInfo: ["sceneIdentifier": control.App.sceneIdentifier]
                )
                

            default:
                print("[Error] \(event) not handled")
            }
        }

        var control: GitWebView
        var env: MainApp

        init(_ control: GitWebView, env: MainApp) {
            self.control = control
            self.env = env
            super.init()
        }
    }
}


