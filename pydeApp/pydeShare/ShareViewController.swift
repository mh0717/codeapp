//
//  ShareViewController.swift
//  pydeShare
//
//  Created by Huima on 2023/11/3.
//

import UIKit
import Social

//class ShareViewController: SLComposeServiceViewController {
//
//    override func isContentValid() -> Bool {
//        // Do validation of contentText and/or NSExtensionContext attachments here
//        return true
//    }
//
//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//    
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//    }
//
//    override func configurationItems() -> [Any]! {
//        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
//        return []
//    }
//
//}

import pydeCommon
import ios_system


// com.apple.app.ui-extension.multiple-instances
// com.apple.ui-services

func randomInt(_ min: UInt32, _ max: UInt32) -> UInt32 {
    return min + arc4random() % (max - min + 1)
}

class ShareViewController: UITabBarController {
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        object_setClass(self.tabBar, WeiTabBar.self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        object_setClass(self.tabBar, WeiTabBar.self)
    }
    
    private var consoleVC: ConsoleViewContrller?
    
    private var vcs: [UIViewController] = []
    
    var ntidentifier: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.isHidden = true
        tabBar.isTranslucent = true
        
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
        
        
        setupView()
        
        NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
            if self.vcs.contains(vc) {
                DispatchQueue.main.async {
                    self.selectedViewController = vc
                }
                return
            }
            
            DispatchQueue.main.async {
                self.vcs.append(vc)
                self.viewControllers = self.vcs
                self.selectedViewController = vc
                self.tabBar.isHidden = false
            }
        }
        
        NotificationCenter.default.addObserver(forName: .init("UI_HIDE_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
            DispatchQueue.main.async {
                self.vcs.removeAll(where: {$0==vc})
                self.viewControllers = self.vcs
                if self.selectedIndex >= self.viewControllers!.count {
                    self.selectedIndex = self.viewControllers!.count - 1
                }
            }
        }
        
        if let item = extensionContext!.inputItems.first as? NSExtensionItem,
           let requestInfo = item.userInfo as? [String: Any] {
            if let ntid = requestInfo["identifier"] as? String {
                self.ntidentifier = ntid
            }
            if let env = requestInfo["env"] as? [String], !env.isEmpty {
                env.forEach { item in
                    putenv(item.utf8CString)
                }
            }
            
            
            
            if let commands = requestInfo["commands"] as? [String] {
                print(commands)
            }
        }
        
        initRemotePython3Sub()
        
        Thread.detachNewThread {
            remoteExeCommands(context: self.extensionContext!)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        handleExit()
    }
    
    func setupView() {
        let exitBtn = UIButton(type: .close)
        exitBtn.setTitleColor(UIColor.white, for: .normal)
        exitBtn.setTitleShadowColor(UIColor.black, for: .normal)
        exitBtn.addTarget(self, action: #selector(handleExit), for: .touchUpInside)
        self.view.addSubview(exitBtn)
        
        exitBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exitBtn.widthAnchor.constraint(equalToConstant: 30),
            exitBtn.heightAnchor.constraint(equalToConstant: 30),
            exitBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            exitBtn.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
        
//        self.extensionContext.
        
        consoleVC = ConsoleViewContrller(root: Bundle.main.bundleURL)
        consoleVC?.title = "控制台"
        self.vcs.append(consoleVC!)
        self.viewControllers = self.vcs
    }
    
    
    
    override func viewDidLayoutSubviews() {
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
    }
    
    @objc func handleExit() {
        if let ntid = self.ntidentifier {
            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
        }
        
        
        Thread.detachNewThread {
            sleep(1)
            real_exit(vlaue: 0)
        }
        self.extensionContext!.completeRequest(returningItems: nil) {_ in
            real_exit(vlaue: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            real_exit(vlaue: 0)
        }
        
    }
    
    
    class WeiTabBar: UITabBar {
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var sizeThatFits = super.sizeThatFits(size)
            sizeThatFits.height = 40
            return sizeThatFits
            
        }
        
    }

}
