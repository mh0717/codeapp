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
