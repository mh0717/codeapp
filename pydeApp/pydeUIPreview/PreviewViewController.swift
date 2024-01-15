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

var watcher: FolderMonitor?

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
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
    }
    
    @objc func handleExit() {
        if let id = self.requestInfo?["identifier"] as? String{
            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(id))
        }
        
        
        Thread.detachNewThread {
            sleep(1)
            real_exit(vlaue: 0)
        }
        self.extensionContext?.completeRequest(returningItems: nil) {_ in
            real_exit(vlaue: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            real_exit(vlaue: 0)
        }
        
        self.removeFromParent()
        self.dismiss(animated: true)
    }
    
    

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        url.startAccessingSecurityScopedResource()
        FileManager.default.changeCurrentDirectoryPath(url.path)
        initRemotePython3Sub()
        
        let path = url.path + "/main.py"
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        print(data)
        let dirArr = try? FileManager.default.contentsOfDirectory(atPath: url.path)
        print(dirArr)
        
        
        var requestInfo: [String: Any]? = [
            "identifier": "uuuu-uuuu",
            "commands": ["python3 -u \(url.path)/main.py"],
            "workingDirectoryBookmark": Data(),
            "workspace": Data()
        ]
        Thread.detachNewThread {
            remoteExe(requestInfo: requestInfo!)
            sleep(1)
            real_exit(vlaue: 0)
        }
        handler(nil)
        if true {
            return
        }
        
//        if let watcher {
//            handler(MultipleWindowError.MultipleWindow)
//            return
//        }
//        
//        watcher = FolderMonitor(url: url)
//        watcher?.folderDidChange = {_ in
//            if !FileManager.default.fileExists(atPath: url.path) {
//                self.handleExit()
//            }
//        }
//        watcher?.startMonitoring()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !FileManager.default.fileExists(atPath: url.path) {
                self.handleExit()
            }
        }
        
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

enum MultipleWindowError: Error {
    case MultipleWindow
}


class FolderMonitor {
    // MARK: Properties

    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(
        label: "FolderMonitorQueue", attributes: .concurrent)
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    /// URL for the directory being monitored.
    var url: Foundation.URL

    var folderDidChange: ((Date) -> Void)?
    // MARK: Initializers
    init(url: Foundation.URL) {
        self.url = url
    }

    deinit {
        self.stopMonitoring()
    }

    // MARK: Monitoring
    /// Listen for changes to the directory (if we are not already).
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        // Open the directory referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)

        guard monitoredFolderFileDescriptor != -1 else { return }

        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write,
            queue: folderMonitorQueue)
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            guard let strongSelf = self else { return }
            guard
                let attributes = try? FileManager.default.attributesOfItem(
                    atPath: strongSelf.url.path)
            else { return }
            if let lastModified = attributes[.modificationDate] as? Date {
                strongSelf.folderDidChange?(lastModified)
            }
        }
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }
    /// Stop listening for changes to the directory, if the source has been created.
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
