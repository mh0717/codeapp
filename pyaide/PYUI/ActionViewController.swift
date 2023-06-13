//
//  Action.swift
//  pyaide
//
//  Created by Huima on 2023/5/30.
//

import Foundation
import UIKit
import ios_system

open class ActionViewController: UITabBarController {
    
    var termVC:TermViewContrller? = nil
    
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
            exitBtn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20)
        ])
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshSDLWindows), name: NSNotification.Name("SDL_REFRESH_WINDOWS"), object: nil)
        
        
    }
    
    open override func viewWillLayoutSubviews() {
        update_sdl_winsize(self.view.bounds)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        let item = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.userInfo
        print(item)
        guard let items = self.extensionContext?.inputItems, let item = items.first as? NSExtensionItem, let config = item.userInfo as? [String: Any] else{
            return
        }
        
        
        
        numPythonInterpreters = 1
        
        replaceCommand("backgroundCmdQueue", "backgroundCmdQueue", true)
        replaceCommand("python3", "python3", true)
        
        joinMainThread = false
        
        guard let ncid: String = config["identifier"] as? String else {return}
        
        setenv("npm_config_prefix", sharedURL.appendingPathComponent("lib").path, 1)
        setenv("npm_config_cache", FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.path, 1)
        setenv("npm_config_userconfig", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(".npmrc").path, 1)
        
        let libraryURL = try! FileManager().url(
            for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        // Main Python install: $APPDIR/Library/lib/python3.x
        let pybundle = URL(fileURLWithPath: Bundle.main.resourcePath!).appendingPathComponent("../../pyhome")
        
        setenv("PYTHONHOME", pybundle.path.toCString(), 1)
        
        let pysite1 = URL(fileURLWithPath: Bundle.main.resourcePath!).appendingPathComponent("../../site-packages1")
        setenv("PYTHONPATH", pysite1.path.toCString(), 1)
        // Compiled files: ~/Library/__pycache__
        setenv(
            "PYTHONPYCACHEPREFIX",
            (libraryURL.appendingPathComponent("__pycache__")).path.toCString(), 1)
        setenv("PYTHONUSERBASE", libraryURL.path.toCString(), 1)
        setenv("APPDIR", pybundle.deletingLastPathComponent().path.toCString(), 1)
        setenv("PYZMQ_BACKEND", "cython", 1)
        // matplotlib backend
        setenv("MPLBACKEND", "module://backend_ios", 1);
        
        // pysdl
        setenv("PYSDL2_DLL_PATH", pybundle.deletingLastPathComponent().path.appendingPathComponent(path: "Frameworks"), 1)
        
        
        
        // Kivy environment to prefer some implementation on iOS platform
        putenv("KIVY_BUILD=ios".utf8CString);
        putenv("KIVY_NO_CONFIG=1".utf8CString);
    //    putenv("KIVY_NO_FILELOG=1");
        putenv("KIVY_WINDOW=sdl2".utf8CString);
        putenv("KIVY_IMAGE=imageio,tex,gif".utf8CString);
        putenv("KIVY_AUDIO=sdl2".utf8CString);
        putenv("KIVY_GL_BACKEND=sdl2".utf8CString);
        /// 设为1，避免屏幕放大，可能sdl正确处理了高分屏，不用kivy再次处理
        setenv("KIVY_METRICS_DENSITY", "1", 1);
        setenv("KIVY_DPI", "401", 1)

        // IOS_IS_WINDOWED=True disables fullscreen and then statusbar is shown
        putenv("IOS_IS_WINDOWED=False".utf8CString);

    //    #ifndef DEBUG
    //    putenv("KIVY_NO_CONSOLELOG=1");
    //    #endif
        
        putenv("PYOBJUS_DEBUG=1".utf8CString);
        
        
        
        var isStale = true
        
        guard let data = config["workingDirectoryBookmark"] as? Data else {
            return
        }
        
        let url = try! URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        _ = url.startAccessingSecurityScopedResource()
        FileManager.default.changeCurrentDirectoryPath(url.path)
        

        if let wdata = config["workspace"] as? Data {
            let url = try! URL(resolvingBookmarkData: wdata, bookmarkDataIsStale: &isStale)
            _ = url.startAccessingSecurityScopedResource()
        }
        
        
        ios_setDirectoryURL(url)
        
        var activeTime: Date = Date()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            activeTime = Date()
        }
        let watchQueue = DispatchQueue(label: "watchDog")
        watchQueue.async {
            while true {
                sleep(1)
                if activeTime.timeIntervalSinceNow < -6 {
                    self.extensionContext!.completeRequest(returningItems: nil) {_ in
                        real_exit(vlaue: 0)
                    }
                    sleep(1)
                    real_exit(vlaue: 0)
                }
            }
        }
        
        guard let args = config["args"] as? [String] else {return}
        
        self.termVC = TermViewContrller(root: url)
        self.viewControllers = [self.termVC!]
        self.termVC?.termView.executor?.evaluateCommands([args.joined(separator: " ")])
        
    }
    
    @objc func refreshSDLWindows(_ notify: Notification) {
        var vcs: [UIViewController] = [self.termVC!]
        guard let rvcs = notify.userInfo?["vcs"] as? [UIViewController] else {
            self.viewControllers = [self.termVC!]
            return
        }
        vcs.append(contentsOf: rvcs)
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

class TermViewContrller: UIViewController {
    let termView: TMConsoleView
    
    init(root: URL) {
        self.termView = TMConsoleView(root: root)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = self.termView
    }
}


@_cdecl("python3")
public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let stdin = thread_stdin
    let stdout = thread_stdout
    let stderr = thread_stderr
    var result: Int32 = 0
    DispatchQueue.main.sync {
        thread_stdin = stdin
        thread_stdout = stdout
        thread_stderr = stderr
        result = Py_BytesMain(argc, argv)
    }
    return result
}
