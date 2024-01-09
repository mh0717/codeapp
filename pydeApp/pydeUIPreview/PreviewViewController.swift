//
//  PreviewViewController.swift
//  pydeUIPreview
//
//  Created by Huima on 2024/1/7.
//

import UIKit
import QuickLook

import pydeCommon
import ios_system

class PreviewViewController: UITabBarController, QLPreviewingController {
    
    private var vcs: [UIViewController] = []
    
    private var requestInfo: [String: Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        wmessager.listenForMessage(withIdentifier: ConstantManager.PYDE_REMOTE_UI_FORCE_EXIT) { _ in
            if let id = self.requestInfo?["identifier"] as? String{
                wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(id))
                wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT)
            }
            
            sleep(1)
            real_exit(vlaue: 0)
        }
        
        tabBar.isHidden = true
        tabBar.isTranslucent = true
        
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
//        setenv("SDL_SCREEN_SIZE", "320:480", 1)
        
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
                self.tabBar.isHidden = self.vcs.count <= 1
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
    }
    
    
    
    override func viewDidLayoutSubviews() {
//        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
    }
    
    @objc func handleExit() {
//        if let ntid = self.ntidentifier {
//            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
//        }
        
        
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
        
        self.removeFromParent()
        self.dismiss(animated: true)
    }
    
    

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        self.requestInfo = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? [String: Any]
        
        
        if let requestInfo {
            if let ntid = requestInfo["identifier"] as? String {
                
            }
            if let env = requestInfo["env"] as? [String], !env.isEmpty {
                env.forEach { item in
                    putenv(item.utf8CString)
                }
            }
            
            
            initRemotePython3Sub()
//            replaceCommand("python3", "python3RunInMain", false)
            
            Thread.detachNewThread {
                remoteExe(requestInfo: requestInfo)
                if let ntid = requestInfo["identifier"] as? String {
                    wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
                }
                
                wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT)
                sleep(1)
                real_exit(vlaue: 0)
            }
//            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(500))) {
//                remoteExe(requestInfo: requestInfo)
//                if let ntid = requestInfo["identifier"] as? String {
//                    wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
//                }
//
//                wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT)
//                sleep(1)
//                real_exit(vlaue: 0)
//            }
            
        }
        
        handler(nil)
//        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(10))) {
//            handler(nil)
//        }
    }

}
