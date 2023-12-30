//
//  ActionViewController.swift
//  pydeUI
//
//  Created by Huima on 2023/10/29.
//

import UIKit

import python3_ui
import pydeCommon
import ios_system


// com.apple.app.ui-extension.multiple-instances
// com.apple.ui-services

func randomInt(_ min: UInt32, _ max: UInt32) -> UInt32 {
    return min + arc4random() % (max - min + 1)
}

class ActionViewController: UITabBarController {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = .currentContext
        self.preferredContentSize = CGSizeMake(800, 600)
        
//        replaceCommand("python3", "python3", true)
//        replaceCommand("rremote", "rremote", true)
//        initRemoteEnv()
        
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
        
//        Thread.detachNewThread {
//            remoteExeCommands(context: self.extensionContext!)
//        }
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


//@_cdecl("python3")
//public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    if (argc == 1) {
//        return python3_exec(argc: argc, argv: argv)
//    } else {
//        return python3_inmain(argc: argc, argv: argv)
//    }
//}
//
//
//@_cdecl("rremote")
//public func rremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
//    cmds.removeFirst()
//    return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
//}


@objc class MyVC: UIViewController {
    
}
