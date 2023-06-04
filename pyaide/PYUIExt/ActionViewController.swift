//
//  ActionViewController.swift
//  PYUIExt
//
//  Created by Huima on 2023/5/31.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UITabBarController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        update_sdl_winsize(self.view.bounds)

        self.modalPresentationStyle = .fullScreen

        NotificationCenter.default.addObserver(self, selector: #selector(refreshSDLWindows), name: NSNotification.Name("SDL_REFRESH_WINDOWS"), object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startSDL()
        }
    }
    
//    open override func viewWillLayoutSubviews() {
//        update_sdl_winsize(self.view.bounds)
//    }
    
    @objc func refreshSDLWindows(_ notify: Notification) {
        guard let vcs = notify.userInfo?["vcs"] as? [UIViewController] else {return}
        self.viewControllers = vcs
        self.selectedIndex = 0
    }
    
    func startSDL() {
        rectangles_main()
        self.done()
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
