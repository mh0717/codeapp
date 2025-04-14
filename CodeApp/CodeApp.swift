//
//  CodeApp.swift
//  Code App
//
//  Created by Ken Chung on 17/11/2020.
//

import SwiftGit2
import SwiftUI
import UIKit
import WebKit
import ios_system
import pydeCommon

@main
struct CodeApp: App {
    @StateObject var themeManager = ThemeManager()

    #if PYDEAPP
        #if PYTHON3IDE
            @StateObject var subIapManager = SubIapManager.instance
        #else
            @StateObject var iapManager = IapManager.instance
        #endif
    #endif

    func versionNumberIncreased() -> Bool {
        if let lastReadVersion = UserDefaults.standard.string(forKey: "changelog.lastread") {
            let currentVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
            if lastReadVersion != currentVersion {
                return true
            }
        } else {
            return true
        }
        print("Version Number not increased")
        return false
    }

    // From a-shell: https://github.com/holzschu/a-shell/blob/9eb0f4c94a9bdc3b24460c3ed82a156f5b33bb2f/a-Shell/AppDelegate.swift

    func executeCommandAndWait(command: String) {
        let pid = ios_fork()
        _ = ios_system(command)
        fflush(thread_stdout)
        ios_waitpid(pid)
        ios_releaseThreadId(pid)
    }

    func needToUpdateCFiles() -> Bool {
        // Check that the C SDK files are present:
        let libraryURL = try! FileManager().url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        // NSLog("Library file exists: \(FileManager().fileExists(atPath: libraryURL.appendingPathComponent("usr/lib/wasm32-wasi/libwasi-emulated-mman.a").path))")
        // NSLog("Header file exists: \(FileManager().fileExists(atPath: libraryURL.appendingPathComponent("usr/include/stdio.h").path))")
        return
            !(FileManager().fileExists(
                atPath: libraryURL.appendingPathComponent(
                    "usr/lib/wasm32-wasi/libwasi-emulated-mman.a"
                ).path)
            && FileManager().fileExists(
                atPath: libraryURL.appendingPathComponent("usr/include/stdio.h").path))
    }

    func createCSDK() {
        let installQueue = DispatchQueue(label: "installFiles", qos: .userInteractive)

        // This operation copies the C SDK from $APPDIR to $HOME/Library and creates the *.a libraries
        // (we can't ship with .a libraries because of the AppStore rules, but we can ship with *.o
        // object files, provided they are in WASM format.
        installQueue.async {
            // Use a queue so it does not take time at startup:
            NSLog("Starting creating C SDK")
            let libraryURL = try! FileManager().url(
                for: .libraryDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
            // usr/lib/wasm32-wasi
            var localURL = libraryURL.appendingPathComponent("usr/lib/wasm32-wasi")
            do {
                if FileManager().fileExists(atPath: localURL.path) && !localURL.isDirectory {
                    try FileManager().removeItem(at: localURL)
                }
                if !FileManager().fileExists(atPath: localURL.path) {
                    try FileManager().createDirectory(
                        atPath: localURL.path, withIntermediateDirectories: true)
                }
            } catch {
                NSLog("Error in creating C SDK directory \(localURL): \(error)")
                return
            }
            // usr/lib/clang/14.0.0/lib/wasi/
            localURL = libraryURL.appendingPathComponent("usr/lib/clang/14.0.0/lib/wasi/")
            do {
                if FileManager().fileExists(atPath: localURL.path) && !localURL.isDirectory {
                    try FileManager().removeItem(at: localURL)
                }
                if !FileManager().fileExists(atPath: localURL.path) {
                    try FileManager().createDirectory(
                        atPath: localURL.path, withIntermediateDirectories: true)
                }
            } catch {
                NSLog("Error in creating C SDK directory \(localURL): \(error)")
                return
            }
            let linkedCDirectories = [
                "usr/include",
                "usr/share",
                "usr/lib/wasm32-wasi/crt1.o",
                "usr/lib/wasm32-wasi/libc.imports",
                "usr/lib/clang/14.0.0/include",
            ]

            for linkedObject in linkedCDirectories {
                let bundleFile = Resources.clangLib.appendingPathComponent(linkedObject)
                if !FileManager().fileExists(atPath: bundleFile.path) {
                    NSLog("createCSDK: requested file \(bundleFile.path) does not exist")
                    continue
                }
                // Symbolic links are both faster to create and use less disk space.
                // We just have to make sure the destination exists
                let homeFile = libraryURL.appendingPathComponent(linkedObject)
                do {
                    let firstFileAttribute = try FileManager().attributesOfItem(
                        atPath: homeFile.path)
                    if firstFileAttribute[FileAttributeKey.type] as? String
                        == FileAttributeType.typeSymbolicLink.rawValue
                    {
                        // It's a symbolic link, does the destination exist?
                        let destination = try! FileManager().destinationOfSymbolicLink(
                            atPath: homeFile.path)
                        if !FileManager().fileExists(atPath: destination) {
                            try! FileManager().removeItem(at: homeFile)
                            try! FileManager().createSymbolicLink(
                                at: homeFile, withDestinationURL: bundleFile)
                        }
                    } else {
                        // Not a symbolic link, replace:
                        try! FileManager().removeItem(at: homeFile)
                        try! FileManager().createSymbolicLink(
                            at: homeFile, withDestinationURL: bundleFile)
                    }
                } catch {
                    // The file does not exist, and maybe the directory doesn't either:
                    let localDirectory = homeFile.deletingLastPathComponent()
                    if !FileManager().fileExists(atPath: localDirectory.path) {
                        try! FileManager().createDirectory(
                            atPath: localDirectory.path, withIntermediateDirectories: true)
                    }
                    do {
                        try FileManager().createSymbolicLink(
                            at: homeFile, withDestinationURL: bundleFile)
                    } catch {
                        NSLog("Can't create file: \(homeFile.path): \(error)")
                    }
                }
            }
            // Now create the empty libraries:
            let emptyLibraries = [
                // m rt pthread crypt util xnet resolv dl
                "lib/wasm32-wasi/libcrypt.a",
                "lib/wasm32-wasi/libdl.a",
                "lib/wasm32-wasi/libm.a",
                "lib/wasm32-wasi/libpthread.a",
                "lib/wasm32-wasi/libresolv.a",
                "lib/wasm32-wasi/librt.a",
                "lib/wasm32-wasi/libutil.a",
                "lib/wasm32-wasi/libxnet.a",
            ]
            ios_switchSession("wasiSDKLibrariesCreation")
            for library in emptyLibraries {
                let libraryFileURL = libraryURL.appendingPathComponent("/usr/" + library)
                if !FileManager().fileExists(atPath: libraryFileURL.path) {
                    executeCommandAndWait(command: "ar crs " + libraryURL.path + "/usr/" + library)
                }
            }
            // One of the libraries is in a different folder:
            let libraryFileURL = libraryURL.appendingPathComponent(
                "/usr/lib/clang/14.0.0/lib/wasi/libclang_rt.builtins-wasm32.a")
            if FileManager().fileExists(atPath: libraryFileURL.path) {
                try! FileManager().removeItem(at: libraryFileURL)
            }
            let rootDir = Bundle.main.resourcePath! + "/ClangLib"
            executeCommandAndWait(
                command: "ar cq " + libraryFileURL.path + " " + rootDir
                    + "/usr/src/libclang_rt.builtins-wasm32/*")
            executeCommandAndWait(command: "ranlib " + libraryFileURL.path)
            let libraries = [
                "libc", "libc++", "libc++abi", "libc-printscan-long-double",
                "libc-printscan-no-floating-point", "libwasi-emulated-mman",
                "libwasi-emulated-signal", "libwasi-emulated-process-clocks",
            ]
            for library in libraries {
                let libraryFileURL = libraryURL.appendingPathComponent(
                    "usr/lib/wasm32-wasi/" + library + ".a")
                if FileManager().fileExists(atPath: libraryFileURL.path) {
                    do { try FileManager().removeItem(at: libraryFileURL) } catch {
                        NSLog("Can't remove \(libraryFileURL.path)")
                    }
                }
                executeCommandAndWait(
                    command: "ar cq " + libraryFileURL.path + " " + rootDir + "/usr/src/" + library
                        + "/*")
                executeCommandAndWait(command: "ranlib " + libraryFileURL.path)
            }
            NSLog("Finished creating C SDK")  // Approx 2 seconds
        }
    }

    #if PYDEAPP
        init() {
            if !(CommandLine.arguments.count >= 2
                && CommandLine.arguments[1].hasSuffix(".pyremote"))
            {
                UITableView.appearance().backgroundColor = UIColor.clear
                UITableViewCell.appearance().backgroundColor = UIColor.clear
                UITableView.appearance().separatorStyle = .none
                UITextView.appearance().backgroundColor = .clear

                // Disable mini map and line number for iPhones
                if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                    if UserDefaults.standard.object(forKey: "editorLineNumberEnabled") == nil {
                        UserDefaults.standard.setValue(false, forKey: "editorLineNumberEnabled")
                        UserDefaults.standard.setValue(false, forKey: "editorMiniMapEnabled")
                    }
                    if UserDefaults.standard.object(forKey: "compilerShowPath") == nil {
                        UserDefaults.standard.setValue(false, forKey: "compilerShowPath")
                    }
                }

                Repository.initialize_libgit2()

                DispatchQueue.main.async {
                    initPyDE()
                }

                PYApp.onAppInitialized()

                DownloadManager.instance.setup()
            }

            signal(SIGPIPE, SIG_IGN)
        }
    #else
        init() {
            UITableView.appearance().backgroundColor = UIColor.clear
            UITableViewCell.appearance().backgroundColor = UIColor.clear
            UITableView.appearance().separatorStyle = .none
            UITextView.appearance().backgroundColor = .clear

            replaceCommand("node", "node", true)
            replaceCommand("npm", "npm", true)
            replaceCommand("npx", "npx", true)
            replaceCommand("wasm", "wasm", true)

            refreshNodeCommands()

            let libraryURL = try! FileManager().url(
                for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            // Main Python install: $APPDIR/Library/lib/python3.x
            let bundleUrl = Resources.pythonLibrary
            setenv("PYTHONHOME", bundleUrl.path.toCString(), 1)
            // Compiled files: ~/Library/__pycache__
            setenv(
                "PYTHONPYCACHEPREFIX",
                (libraryURL.appendingPathComponent("__pycache__")).path.toCString(), 1)
            setenv("PYTHONUSERBASE", libraryURL.path.toCString(), 1)
            setenv("SSL_CERT_FILE", Resources.carcert.path.toCString(), 1)

            // Help aiohttp install itself:
            setenv("YARL_NO_EXTENSIONS", "1", 1)
            setenv("MULTIDICT_NO_EXTENSIONS", "1", 1)

            // clang options:
            setenv("SYSROOT", libraryURL.path + "/usr", 1)
            setenv(
                "CCC_OVERRIDE_OPTIONS",
                "#^--target=wasm32-wasi +-fno-exceptions +-lc-printscan-long-double", 1)
            setenv("MAKESYSPATH", Bundle.main.resourcePath! + "ClangLib/usr/share/mk", 1)

            // PHP config
            setenv("PHPRC", bundleUrl.path.toCString(), 1)
            // Git config
            //        setenv("HOME", libraryURL.path, 1)
            setenv("GIT_EXEC_PATH", bundleUrl.appendingPathComponent("bin").path.toCString(), 1)
            // Magic file
            //        setenv("MAGIC", Bundle.main.resourcePath! + "/usr/share/magic.mgc", 1)
            joinMainThread = false
            numPythonInterpreters = 2

            let notificationName = "com.thebaselab.code.node.stdout" as CFString
            let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

            CFNotificationCenterAddObserver(
                notificationCenter, nil,
                {
                    (
                        center: CFNotificationCenter?,
                        observer: UnsafeMutableRawPointer?,
                        name: CFNotificationName?,
                        object: UnsafeRawPointer?,
                        userInfo: CFDictionary?
                    ) in

                    let sharedURL = FileManager.default.containerURL(
                        forSecurityApplicationGroupIdentifier: "group.com.thebaselab.code")!
                    let stdoutURL = sharedURL.appendingPathComponent("stdout")

                    guard let data = try? Data(contentsOf: stdoutURL),
                        let str = String(data: data, encoding: .utf8)
                    else {
                        return
                    }

                    let nc = NotificationCenter.default
                    nc.post(
                        name: Notification.Name("node.stdout"), object: nil,
                        userInfo: ["content": str])

                },
                notificationName,
                nil,
                CFNotificationSuspensionBehavior.deliverImmediately)

            // Disable mini map and line number for iPhones
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                if UserDefaults.standard.object(forKey: "editorLineNumberEnabled") == nil {
                    UserDefaults.standard.setValue(false, forKey: "editorLineNumberEnabled")
                    UserDefaults.standard.setValue(false, forKey: "editorMiniMapEnabled")
                }
                if UserDefaults.standard.object(forKey: "compilerShowPath") == nil {
                    UserDefaults.standard.setValue(false, forKey: "compilerShowPath")
                }
            }

            if versionNumberIncreased() || needToUpdateCFiles() {
                createCSDK()
            }

            DispatchQueue.main.async {
                wasmWebView.loadFileURL(
                    Resources.wasmHTML,
                    allowingReadAccessTo: Resources.wasmHTML)
            }
            initializeEnvironment()
            Repository.initialize_libgit2()
        }
    #endif

    var window: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
            let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
            let window = windowSceneDelegate.window
        else {
            return nil
        }
        return window
    }

    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.count >= 2 && CommandLine.arguments[1].hasSuffix(".pyremote") {
                IDERemoteUI()
            } else {
                SceneReader {
                    MainScene()
                        .ignoresSafeArea(.container, edges: .bottom)
                        .preferredColorScheme(themeManager.colorSchemePreference)
                        .environmentObject(themeManager)
                        #if PYDEAPP
                            #if PYTHON3IDE
                                .environmentObject(subIapManager)
                            #else
                                .environmentObject(iapManager)
                            #endif
                        #endif
                }
            }
        }
    }
}

func refreshNodeCommands() {
    let nodeBinPath = Resources.appGroupSharedLibrary?.appendingPathComponent("lib/bin").path

    if let nodeBinPath = nodeBinPath,
        let paths = try? FileManager.default.contentsOfDirectory(atPath: nodeBinPath)
    {
        paths.forEach { path in
            let cmd = path.replacingOccurrences(of: nodeBinPath, with: "")
            replaceCommand(cmd, "nodeg", true)
        }
    }
}

struct IDERemoteUI: UIViewControllerRepresentable {

    let tabvc = UITabBarController(nibName: nil, bundle: nil)

    func makeUIViewController(context: Context) -> some UIViewController {
        //        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)

        return tabvc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    func makeCoordinator() -> TabCoordinator {
        return TabCoordinator(tabvc)
    }

    class TabCoordinator {
        private weak var tabvc: UITabBarController?
        private var vcs: [UIViewController] = []
        private var activityView: UIActivityIndicatorView?

        var ntidentifier: String?

        init(_ tabvc: UITabBarController) {
            self.tabvc = tabvc

            setupNotify()

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.run()
            }
        }

        func run() {
            //            setenv("SDL_VIDEODRIVER", "metal", 1)
            guard let path = CommandLine.arguments.safeObject(at: 1) else { return }
            let url = URL(fileURLWithPath: path)
            print(url)
            guard let data = try? Data(contentsOf: url),
                let requestInfo = try? PropertyListSerialization.propertyList(
                    from: data, format: nil) as? [String: Any]
            else {
                print("requestInfo nil!!!!!")
                real_exit(vlaue: 1)
                exit(1)
            }
            ConstantManager.pydeEnv = .remoteUI

            if let env = requestInfo["env"] as? [String], !env.isEmpty {
                env.forEach { item in
                    //                        ios_putenv(item.utf8CString)
                    putenv(item.utf8CString)
                }
            }

            /// 如果有这个环境变量，jupyter kernel会检测父进程，ios应该检测不了，kernel就直接退出
            unsetenv("JPY_PARENT_PID")

            guard let commands = requestInfo["commands"] as? [String] else {
                return
            }
            print(commands)
            initPydeUI()

            Thread.detachNewThread {
                let result = remoteExe(requestInfo: requestInfo, exit: false)
            }
        }

        func setupNotify() {
            NotificationCenter.default.addObserver(
                forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil
            ) { notify in
                guard let vc = notify.userInfo?["vc"] as? UIViewController else { return }
                if self.vcs.contains(vc) {
                    DispatchQueue.main.async {
                        self.tabvc?.selectedViewController = vc
                        self.tabvc?.preferredContentSize = vc.preferredContentSize
                    }
                    return
                }

                DispatchQueue.main.async {
                    if let activityView = self.activityView {
                        activityView.removeFromSuperview()
                        self.activityView = nil
                    }
                    if vc.title == nil || vc.title!.isEmpty {
                        vc.title = "Window"
                    }
                    self.vcs.append(vc)
                    self.tabvc?.viewControllers = self.vcs
                    self.tabvc?.selectedViewController = vc
                    self.tabvc?.tabBar.isHidden = self.vcs.count <= 1
                    self.tabvc?.preferredContentSize = vc.preferredContentSize

                    //                    self.selectedViewController?.addObserver(self, forKeyPath: "preferredContentSize", context: nil)

                    if NSStringFromClass(type(of: vc)) == "FlutterViewController" {
                        NotificationCenter.default.post(
                            name: UIApplication.willEnterForegroundNotification, object: nil,
                            userInfo: nil)
                        vc.perform(Selector("surfaceUpdated:"), with: true)
                    }
                }
            }

            NotificationCenter.default.addObserver(
                forName: .init("UI_HIDE_VC_IN_TAB"), object: nil, queue: nil
            ) { notify in
                guard let tabvc = self.tabvc else {
                    return
                }
                guard let vc = notify.userInfo?["vc"] as? UIViewController else { return }
                DispatchQueue.main.async {
                    //                    vc.removeObserver(self, forKeyPath: "preferredContentSize")
                    self.vcs.removeAll(where: { $0 == vc })
                    tabvc.viewControllers = self.vcs
                    if tabvc.selectedIndex >= tabvc.viewControllers!.count {
                        tabvc.selectedIndex = tabvc.viewControllers!.count - 1
                    }
                    tabvc.tabBar.isHidden = self.vcs.count <= 1
                }
            }
        }
    }

}
