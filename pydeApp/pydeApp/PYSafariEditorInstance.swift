//
//  PYSafariEditorInstance.swift
//  iPyDE
//
//  Created by Huima on 2024/4/9.
//

import Foundation
import SwiftUI
import SafariServices

private var _safariCount = 0
class PYSafariEditorInstance: EditorInstance, PYObserverProxyDelegate {
    
    
    let proxy = PYObserverProxy()
    let safari: SFSafariViewController
    
    init(_ url: URL) {
        _safariCount += 1
        safari = SFSafariViewController(url: url)
        super.init(
            view: AnyView(VCRepresentable(safari).id(UUID())),
            title: "Safari#\(_safariCount)"
        )
        
        safari.addObserver(proxy, forKeyPath: "title", context: nil)
        proxy.delegate = self
    }
    
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let title = safari.title {
            self.title = title
        }
    }
    
    override func dispose() {
        super.dispose()
        safari.removeObserver(proxy, forKeyPath: "title")
    }
}

private struct PYWebView: UIViewRepresentable {

    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
}


class PYWebEditorInstance: EditorInstance, PYObserverProxyDelegate {
    let proxy = PYObserverProxy()
    let webView: WKWebView
    
    init(_ url: URL) {
        _safariCount += 1
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        webView = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        super.init(
            view: AnyView(PYWebView(webView: webView).id(UUID())),
            title: "Web#\(_safariCount)"
        )
        
        webView.addObserver(proxy, forKeyPath: "title", context: nil)
        proxy.delegate = self
    }
    
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let title = webView.title {
            self.title = title
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
