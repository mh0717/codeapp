//
//  TogaWindow.swift
//  iPyDE
//
//  Created by Huima on 2024/4/6.
//

import UIKit

@objc(TogaWindow)
class TogaWindow: NSObject {
    
    private var _frame: CGRect = CGRectZero
    
    @objc
    var frame: CGRect {
        set(value) {
            _frame = value
            self.rootViewController?.preferredContentSize = value.size
//            self.rootViewController?.parent?.preferredContentSize = value.size
        }
        
        get {
            if self.rootViewController != nil {
                return self.rootViewController?.view.bounds ?? _frame
            }
            return _frame
        }
    }
    
    @objc(initWithFrame:)
    init(_ frame: CGRect) {
        super.init()
        self.frame = frame
    }
    
    @objc
    var bounds: CGRect {
        return self.frame
    }
    
    @objc
    var title: String? {
        didSet {
            self.rootViewController?.title = title
        }
    }
    
    @objc
    var rootViewController: UIViewController? {
        didSet {
            rootViewController?.preferredContentSize = frame.size
        }
    }
    
    @objc var backgroundColor: UIColor? {
        didSet {
            self.rootViewController?.view.backgroundColor = backgroundColor
        }
    }
    
    @objc
    func makeKeyAndVisible() {
        NotificationCenter.default.post(name: .init("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": self.rootViewController as Any])
    }
}


extension UIViewController {
    @objc
    func present() {
        NotificationCenter.default.post(name: .init("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": self])
    }
    
    @objc
    func dismiss() {
        NotificationCenter.default.post(name: .init("UI_HIDE_VC_IN_TAB"), object: nil, userInfo: ["vc": self])
    }
}

extension UIView {
    @objc
    func present() {
        if let vc = self.next as? UIViewController {
            NotificationCenter.default.post(name: .init("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": vc])
            return
        }
        
        let vc = UIViewController()
        vc.view = self
        if self.bounds.width > 10 && self.bounds.height > 10 {
            vc.preferredContentSize = self.bounds.size
        }
        NotificationCenter.default.post(name: .init("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": vc])
    }
    
    @objc
    func dismiss() {
        if let vc = self.next as? UIViewController {
            NotificationCenter.default.post(name: .init("UI_HIDE_VC_IN_TAB"), object: nil, userInfo: ["vc": vc])
            return
        }
    }
}
