//
//  PYSafariEditorInstance.swift
//  iPyDE
//
//  Created by Huima on 2024/4/9.
//

import Foundation
import SwiftUI
import SafariServices
import pydeCommon

private var _safariCount = 0

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
    
    
    let proxy = PYObserverProxy()
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
    
//    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if let title = safari.title {
//            self.title = title
//        }
//    }
//    
//    override func dispose() {
//        super.dispose()
//        safari.removeObserver(proxy, forKeyPath: "title")
//    }
}

private struct PYWebView: UIViewRepresentable {

    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
}


class PYWebEditorInstance: EditorInstanceWithURL, PYObserverProxyDelegate {
    let proxy = PYObserverProxy()
    let webView: WKWebView
    
    init(_ url: URL) {
        _safariCount += 1
        
//        let config = WKWebViewConfiguration()
////        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
//        
//        webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
//        if #available(iOS 16.4, *) {
//            #if DEBUG
////            webView.isInspectable = true
//            #endif
//        }
        webView = WebViewBase()
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        super.init(
            view: AnyView(PYWebView(webView: webView).id(UUID())),
            title: "Web#\(_safariCount)", url: url
        )
        
        webView.addObserver(proxy, forKeyPath: "title", context: nil)
        proxy.delegate = self
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
    
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let title = webView.title, self.title != title {
            self.title = title
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: ConstantManager.MainAppForeceUpdateName, object: nil)
            }
        }
    }
    
    override func dispose() {
        super.dispose()
        webView.removeObserver(proxy, forKeyPath: "title")
    }
}

protocol PYObserverProxyDelegate: AnyObject {
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
}

@objc
class PYObserverProxy: NSObject {
    weak var delegate: PYObserverProxyDelegate?
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        delegate?.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
