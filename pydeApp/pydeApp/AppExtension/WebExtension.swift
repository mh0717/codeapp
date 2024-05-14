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
                guard let ditor = app.activeEditor as? PYWebViewEditorInstance else { return false }
                return true
            },
            menuItems: [
                ToolbarMenuItem(icon: "globe", title: "Change URL", onClick: {
                    guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
                        return
                    }
                    app.pyapp.addressUrl = editor.webView.url?.absoluteString ?? ""
                    app.pyapp.showAddressbar = true
                }),
                ToolbarMenuItem(icon: "arrow.triangle.2.circlepath", title: "Refresh", onClick: {
                    guard let editor = app.activeEditor as? PYWebViewEditorInstance else {
                        return
                    }
                    editor.webView.reload()
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

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
}


class PYWebViewEditorInstance: EditorInstanceWithURL {
    let webView: WKWebView
    
    var kvoToken: NSKeyValueObservation?
    
    init(_ url: URL) {
        _safariCount += 1
        
        webView = WebViewBase()
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        super.init(
            view: AnyView(PYWebView(webView: webView).id(UUID())),
            title: "Web#\(_safariCount)", url: url
        )
        
        kvoToken = webView.observe(\.title, changeHandler: { [weak self] (view, value) in
            self?.title = view.title ?? self?.title ?? ""
        })
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
