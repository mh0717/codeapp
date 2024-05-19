//
//  WebManager.swift
//  Code
//
//  Created by Huima on 2024/5/7.
//

import Foundation
import SwiftUI
import SafariServices
import pydeCommon

class WebExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let toolbarItem = ToolbarItem(
            extenionID: "WEBCONTROL",
            icon: "globe",
            onClick: {
                
            },
            shouldDisplay: {
                guard let _ = app.activeEditor as? PYWebViewEditorInstance else { return false }
                return true
            },
            menuItems: [
                ToolbarMenuItem(icon: "globe", title: "Change URL", onClick: {
                    guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
                        return
                    }
                    var url = editor.webView.url?.absoluteString ?? ""
                    if url.isEmpty {
                        url = editor.url.absoluteString
                    }
                    app.pyapp.addressUrl = url
                    app.pyapp.showAddressbar = true
                }),
                ToolbarMenuItem(icon: "arrow.triangle.2.circlepath", title: "Refresh", onClick: {
                    guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
                        return
                    }
                    if editor.webView.url != nil {
                        editor.webView.reload()
                    } else {
                        editor.webView.load(URLRequest(url: editor.url))
                    }
                    
                }),
                ToolbarMenuItem(icon: "safari", title: "Open in Safari", onClick: {
                    guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
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
                guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
                    return
                }
                editor.webView.goBack()
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? PYWebViewEditorInstance else { return false }
                return true
            }
        )
        
        let forwardItem = ToolbarItem(
            extenionID: "WEBFORWARD",
            icon: "arrow.right",
            onClick: {
                guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
                    return
                }
                editor.webView.goForward()
            },
            shouldDisplay: {
                guard let ditor = app.activeEditor as? PYWebViewEditorInstance else { return false }
                return true
            }
        )
        
        contribution.toolBar.registerItem(item: backwardItem)
        contribution.toolBar.registerItem(item: forwardItem)
        contribution.toolBar.registerItem(item: toolbarItem)
        
        let htmlPreviewItem = ToolbarItem(
            extenionID: "HTMLOFFLINEPREVIEW",
            icon: "newspaper",
            onClick: {
                guard let editor = app.activeEditor as? TextEditorInstance else { return }
                guard ["html", "htm"].contains(editor.url.pathExtension.lowercased()) else {
                    return
                }
                
                let webEditor = PYWebViewEditorInstance(editor.url)
                DispatchQueue.main.async {
                    app.appendAndFocusNewEditor(editor: webEditor, alwaysInNewTab: true)
                }
            },
            shouldDisplay: {
                guard let editor = app.activeEditor as? TextEditorInstance else { return false }
                return ["html", "htm"].contains(editor.url.pathExtension.lowercased())
            }
        )
        contribution.toolBar.registerItem(item: htmlPreviewItem)
    }
}

private var _safariCount = 0


private struct PYWebView: UIViewRepresentable {

    let webView: WKWebView
    
    @EnvironmentObject var App: MainApp

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        let coordinator = WebViewCoordinator(app: App)
        webView.navigationDelegate = coordinator
        return coordinator
    }
}


class PYWebViewEditorInstance: EditorInstanceWithURL {
    let webView: WKWebView
//    private let coordinator = WebViewCoordinator()
    
    var kvoToken: NSKeyValueObservation?
    
    init(_ url: URL) {
        _safariCount += 1
        
        webView = WebViewBase()
//        webView.navigationDelegate = coordinator
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        super.init(
            view: AnyView(PYWebView(webView: webView).id(UUID())),
            title: "Web#\(_safariCount)", url: url
        )
        
        kvoToken = webView.observe(\.title, changeHandler: { [weak self] (view, value) in
            self?.title = view.title ?? self?.title ?? ""
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(1000))) {
            if self.webView.url == nil {
                self.webView.load(URLRequest(url: url))
            }
        }
    }
    
    override func dispose() {
        kvoToken?.invalidate()
        kvoToken = nil
        super.dispose()
    }
    
    override var canEditUrl: Bool {
        return true
    }
    
    override func updateUrl(_ url: URL) {
        let lastTitle = title
        self.url = url
        title = lastTitle
        
        webView.load(URLRequest(url: url))
    }
}

fileprivate class WebViewCoordinator: NSObject, WKNavigationDelegate {
    init(app: MainApp) {
        self.app = app
    }
    
    let app: MainApp
    
    var firstFailed = true
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        firstFailed = false
    }

    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !firstFailed {
            return
        }
        firstFailed = false
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(1000))) {
            webView.reload()
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // 判断服务器采用的验证方法
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if challenge.previousFailureCount == 0 {
                // 如果没有错误的情况下 创建一个凭证，并使用证书
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, credential)
            } else {
                // 验证失败，取消本次验证
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.cancel, preferences)
            if let url = navigationAction.request.url {
                _ = app.pyapp.downloadManager.download(url)
            }
            
        } else {
            decisionHandler(.allow, preferences)
        }
//        return navigationAction.shouldPerformDownload ? decisionHandler(.download, preferences) : decisionHandler(.allow, preferences)
    }
        
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if !navigationResponse.canShowMIMEType {
            decisionHandler(.cancel)
            if let url = navigationResponse.response.url {
                _ = app.pyapp.downloadManager.download(url)
            }
        } else {
            decisionHandler(.allow)
        }
//        navigationResponse.canShowMIMEType ? decisionHandler(.allow) : decisionHandler(.download)
    }
    
    
//    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
//        download.delegate = self
//    }
//        
//        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
//            let fileManager = FileManager.default
//            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            let fileUrl =  documentDirectory.appendingPathComponent("\(suggestedFilename)", isDirectory: false)
//            
//            self.downloadUrl = fileUrl
//            completionHandler(fileUrl)
//            /// Save to photo library (optional)
//             savePhotoToPhotoLibrary(filePath: fileUrl)
//        }
//        
//        // MARK: - Optional
//        func downloadDidFinish(_ download: WKDownload) {
//        }
//        
//        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
//            print("\(error.localizedDescription)")
//        }
}

struct MutableVCRepresentable: UIViewControllerRepresentable {

//    private var vc: UIViewController
//    let vc: Binding<UIViewController?>
    @ObservedObject var model: MutableVCModel

//    init(_ vc: UIViewController) {
//        self.vc = vc
//    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return model.vc ?? UIViewController()
    }
}

class MutableVCModel: ObservableObject {
    @Published var vc: UIViewController?
}

class PYSafariEditorInstance: EditorInstanceWithURL {
//    let safari: SFSafariViewController
//    let model = MutableVCModel()
    let vc = UINavigationController()
    
    init(_ url: URL) {
        _safariCount += 1
        let safari = SFSafariViewController(url: url)
        vc.setNavigationBarHidden(true, animated: false)
        vc.setViewControllers([safari], animated: false)
        
        super.init(
            view: AnyView(VCRepresentable(vc).id(UUID())),
            title: "Safari#\(_safariCount)",
            url: url
        )
        
//        safari.addObserver(proxy, forKeyPath: "title", context: nil)
//        proxy.delegate = self
    }
    
    override var canEditUrl: Bool {
        return true
    }
    
    override func updateUrl(_ url: URL) {
        if url == self.url {
            return
        }
        
        var theUrl = url
        if url.scheme == nil {
            if let  nurl = URL(string: "http://\(url.absoluteString)") {
                theUrl = nurl
            }
        }
        
        if theUrl.scheme != "http" && theUrl.scheme != "https" {
            let config = WKWebViewConfiguration()
            config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
            
            var webView = WKWebView(frame: .zero, configuration: config)
            if #available(iOS 16.4, *) {
#if DEBUG
                webView.isInspectable = true
#endif
            }
            
            let request = URLRequest(url: theUrl)
            webView.load(request)
            let lastTitle = title
            let wvc = UIViewController()
            wvc.view = webView
            vc.setViewControllers([wvc], animated: false)
            self.url = theUrl
            title = lastTitle
            return
        }
        
        let lastTitle = title
        let safari = SFSafariViewController(url: theUrl)
        vc.setViewControllers([safari], animated: false)
        self.url = theUrl
        title = lastTitle
    }
}



//protocol PYObserverProxyDelegate: AnyObject {
//    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
//}
//
//@objc
//class PYObserverProxy: NSObject {
//    weak var delegate: PYObserverProxyDelegate?
//    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        
//        delegate?.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//    }
//}
