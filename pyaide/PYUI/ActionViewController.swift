//
//  Action.swift
//  pyaide
//
//  Created by Huima on 2023/5/30.
//

import Foundation
import UIKit

open class ActionViewController: UITabBarController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.tabBar.isHidden = true
        update_sdl_winsize(self.view.bounds)
        
        self.modalPresentationStyle = .fullScreen
        
        let exitBtn = UIButton(type: .close)
        exitBtn.addTarget(self, action: #selector(handleExit), for: .touchUpInside)
        self.view.addSubview(exitBtn)
        
        exitBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exitBtn.widthAnchor.constraint(equalToConstant: 30),
            exitBtn.heightAnchor.constraint(equalToConstant: 30),
            exitBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            exitBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10)
        ])
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshSDLWindows), name: NSNotification.Name("SDL_REFRESH_WINDOWS"), object: nil)
        
        
    }
    
    open override func viewWillLayoutSubviews() {
        update_sdl_winsize(self.view.bounds)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        let item = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.userInfo
        print(item)
        if let items = self.extensionContext?.inputItems, let item = items.first as? NSExtensionItem, let config = item.userInfo as? [String: Any] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                execute(config)
            }
        }
//        DispatchQueue.main.asyncAfter(deadline: .now()+0.05) {
//            self.startSDL()
//        }
    }
    
    @objc func refreshSDLWindows(_ notify: Notification) {
        guard let vcs = notify.userInfo?["vcs"] as? [UIViewController] else {return}
        self.viewControllers = vcs
        if (self.selectedIndex >= vcs.count) {
            self.selectedIndex = 0
        }
        
        self.tabBar.isHidden = (vcs.count <= 1)
    }
    
    func startSDL() {
//        rectangles_main()
        mytest()
    }
    
    @objc func handleExit() {
        Thread.detachNewThread {
            sleep(1)
            real_exit(vlaue: 0)
        }
        SDL_Quit()
        self.extensionContext!.completeRequest(returningItems: nil) {_ in
            real_exit(vlaue: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            real_exit(vlaue: 0)
        }
    }
}


func mytest() {
    
    let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
    let pypath = Bundle.main.url(forResource: "mysdl", withExtension: "py")
    guard let bookmark = try? URL(fileURLWithPath: docPath).bookmarkData() else {
        return
    }
    let args = ["python3 -u \(pypath!.path)"]
    let ntidentifier = "ntidentifier"
    let wbookmark = bookmark
    let config: [String: Any] = [
        "workingDirectoryBookmark": bookmark,
        "args": args,
        "identifier": ntidentifier,
        "workspace": wbookmark,
        "COLUMNS": "48",
        "LINES": "80",
    ]
    
    execute(config)
    
//    initIntepreters()
    
    DispatchQueue.main.asyncAfter(deadline: .now()+0.05) {
        pymain(pypath!.path)
    }
    
    
}
