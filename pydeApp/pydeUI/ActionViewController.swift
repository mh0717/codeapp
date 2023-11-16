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
    
    @objc
    func frame() {
        if SDL_Init(SDL_INIT_VIDEO) < 0 {
            print("init error")
        }
        let window = SDL_CreateWindow(nil, 0, 0, 320, 480, SDL_WINDOW_ALLOW_HIGHDPI.rawValue)
        var winw: Int32 = 0, winh: Int32 = 0
        SDL_GetWindowSize(window, &winw, &winh)
        print("win size: \(winw), \(winh)")
        print("screen size: \(UIScreen.main.bounds.size), \(self.view.bounds.size)")
        let renderer = SDL_CreateRenderer(window, -1, 0)
        SDL_RenderSetLogicalSize(renderer, winw, winh)
        SDL_ShowWindow(window)

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255);
        SDL_RenderClear(renderer)
        SDL_RenderPresent(renderer)
        SDL_RenderPresent(renderer)
        
        var evt: SDL_Event = SDL_Event()
        
        var isRunning = true
        while isRunning {
            while(SDL_PollEvent(&evt) != 0) {
                print("type: \(evt.type)")
                if (evt.type == SDL_QUIT.rawValue) {
                    isRunning = false
                }
            }

            let r = randomInt(50, 255);
            let g = randomInt(50, 255);
            let b = randomInt(50, 255);

            SDL_SetRenderDrawColor(renderer, Uint8(r), Uint8(g), Uint8(b), 255);
            SDL_RenderClear(renderer);
            SDL_RenderPresent(renderer)
            
            SDL_Delay(16)
            
//                RunLoop.current.run(mode: .default, before: Date().advanced(by: 5))
            
//                SDL_Delay(1000)
//                RunLoop.main.schedule(after: RunLoop.main.now.advanced(by: .nanoseconds(5)), tolerance: .milliseconds(5), options: .none) { [weak self] in
//                    print("test: \(Date())")
//                }
        }
        print("end")
        SDL_Quit()
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        replaceCommand("python3", "python3", true)
        replaceCommand("rremote", "rremote", true)
        initRemoteEnv()
        
        tabBar.isHidden = true
        tabBar.isTranslucent = true
        
//        let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as! UIApplication
//        print(application)
        
        setupView()
        
        
        update_sdl_winsize(self.view.bounds)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefreshSDL), name: Notification.Name("SDL_REFRESH_WINDOWS"), object: nil)
        
        if let context = self.extensionContext, context.inputItems.count == 1 {
            remoteExeCommands(context: context, executor: consoleVC?.termView.executor)
        }
        
//        self.performSelector(onMainThread: #selector(frame), with: nil, waitUntilDone: false)
//        RunLoop.main.schedule {
//            self.frame()
//        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(1))) {
//            self.frame()
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
        viewControllers = [consoleVC] as? [UIViewController]
    }
    
    
    
    override func viewDidLayoutSubviews() {
        update_sdl_winsize(self.view.bounds)
    }
    
    @objc func handleRefreshSDL(notify: Notification) {
        guard let vcs = notify.userInfo?["vcs"] as? [UIViewController] else {return}
        
        var newVcs: [UIViewController] = [consoleVC!]
        newVcs.append(contentsOf: vcs)
        self.viewControllers = newVcs
        self.selectedIndex = 0
        if newVcs.count > 1 {
            tabBar.isHidden = false
            newVcs.last?.title = "Window"
//            selectedIndex = 1
        }
        
//        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
//        tv.text = "This is a test!"
//        vcs.last?.view.addSubview(tv)
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


@_cdecl("python3")
public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    if (argc == 1) {
        return python3_exec(argc: argc, argv: argv)
    } else {
        return python3_inmain(argc: argc, argv: argv)
    }
}


@_cdecl("rremote")
public func rremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    cmds.removeFirst()
    return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
}
