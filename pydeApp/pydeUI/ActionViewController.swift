//
//  ActionViewController.swift
//  pydeUI
//
//  Created by Huima on 2023/10/29.
//

import UIKit

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
    private var activityView: UIActivityIndicatorView?
    
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
                if let activityView = self.activityView {
                    activityView.removeFromSuperview()
                    self.activityView = nil
                }
                vc.title = "test"
                self.vcs.append(vc)
                self.viewControllers = self.vcs
                self.selectedViewController = vc
                self.tabBar.isHidden = self.vcs.count <= 1
                self.preferredContentSize = vc.preferredContentSize;
                
                print(vc.self)
                if NSStringFromClass(type(of: vc)) == "FlutterViewController" {
                    NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
                    vc.perform(Selector("surfaceUpdated:"), with: true)
                }
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
                self.tabBar.isHidden = self.vcs.count <= 1
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
        self.view.backgroundColor = UIColor.systemBackground
        
        let activityView = UIActivityIndicatorView(style: .large)
        activityView.startAnimating()
        self.view.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item: activityView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: activityView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraint(centerX)
        view.addConstraint(centerY)
        self.activityView = activityView
        
        
        let exitBtn = UIButton(type: .close)
//        exitBtn.setTitleColor(UIColor.red, for: .normal)
//        exitBtn.setTitleShadowColor(UIColor.black, for: .normal)
        exitBtn.addTarget(self, action: #selector(handleExit), for: .touchUpInside)
        self.view.addSubview(exitBtn)
        
        exitBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exitBtn.widthAnchor.constraint(equalToConstant: 30),
            exitBtn.heightAnchor.constraint(equalToConstant: 30),
            exitBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            exitBtn.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
        
//        self.preferredContentSize = CGSize(width: 10000, height: 10000)
        
//        self.extensionContext.
        
//        consoleVC = ConsoleViewContrller(root: Bundle.main.bundleURL)
//        consoleVC?.title = "控制台"
//        self.vcs.append(consoleVC!)
//        self.viewControllers = self.vcs
        
//        let flutterEngine = FlutterEngine(name: "/", project: nil, allowHeadlessExecution: false)
//        flutterEngine.run(withEntrypoint: "main", libraryURI: nil, initialRoute: "/", entrypointArgs: ["/", ""])
//        GeneratedPluginRegistrant.register(with: flutterEngine)
//        let vc = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
//        vc.view.backgroundColor = UIColor.red
//        vc.title = "First"
//        self.vcs.append(vc)
//        self.viewControllers = self.vcs
//        self.selectedViewController = vc
    }
    
    
    
    override func viewDidLayoutSubviews() {
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
    }
    
    @objc func handleExit() {
        
        if let ntid = self.ntidentifier {
            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
        }
        wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT)
        
        
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
