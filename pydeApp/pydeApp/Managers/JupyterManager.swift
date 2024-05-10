//
//  JupyterManager.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import SwiftUI
import pydeCommon
import python3Objc
import CryptoKit

class JupyterManager: ObservableObject {
    @Published var running: Bool = false
    @Published var firstRuned: Bool = false
    
    @AppStorage("jupyter_server_password") var password: String = ""
    @AppStorage("jupyter_server_port") var port: String = "8888"
    @AppStorage("jupyter_server_public") var public_server: Bool = false
    @AppStorage("jupyter_play_whitespace") var play_ws: Bool = true
    
    @Published var ip: String = ""
    
    let runner = PYRunnerWidget()
    
    lazy var runnerWidget: AnyView = AnyView(runner.id(UUID()))
    
    var runnerView: ConsoleView {
        return runner.consoleView
    }
    
    func closeNotebook() {
        running = false
        
        runnerView.executor?.kill()
    }
    
    let passwdSalt = "bfa0495a0305"
    
    
    func openNotebook(_ wkurl: URL? = nil) {
        if runnerView.executor?.state != .idle {
            return
        }
        
        if let url = wkurl {
            runnerView.resetAndSetNewRootDirectory(url: url)
        }
        
        ip = getIPAddress()
        
        let sha1 = Insecure.SHA1.hash(data: (password + passwdSalt).data(using: .utf8)!).hexString().lowercased()
        
        let configText = """
        c.KernelManager.autorestart = False
        c.NotebookApp.ip = '\(public_server ? "0.0.0.0" : "127.0.0.1")'
        c.NotebookApp.password = 'sha1:\(passwdSalt):\(sha1)'
        c.NotebookApp.port = \(port)
        c.NotebookApp.disable_check_xsrf = True
        c.NotebookApp.allow_remote_access = True
        c.NotebookApp.local_hostnames = ['localhost', '127.0.0.1']

        """
        
        let configDir = ConstantManager.appGroupContainer.appendingPathComponent(".jupyter")
        if !FileManager.default.fileExists(atPath: configDir.path) {
            try? FileManager.default.createDirectory(atPath: configDir.path, withIntermediateDirectories: true)
        }
        let configUrl = configDir.appendingPathComponent("/jupyter_notebook_config.py")
        try? configText.write(to: configUrl, atomically: true, encoding: .utf8)
        let command = "remote jupyter-notebook"
        
        running = true
        runnerView.clear()
//        runnerView.terminalView.isUserInteractionEnabled = false
        runnerView.executor?.dispatch(command: command, isInteractive: false, completionHandler: { [self] _ in
            DispatchQueue.main.async { [self] in
                running = false
            }
        })
    }
}

class JupyterExtension: CodeAppExtension {
    
    public static let jupyterManager = JupyterManager()
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
//        let outline = ActivityBarItem(
//            itemID: "JUPYTER",
//            iconSystemName: "note",
//            title: "JUPYTER",
//            shortcutKey: "n",
//            modifiers: [.command, .shift],
//            view: AnyView(JupyterContainer(jupyterManager: jupyterManager)),
//            contextMenuItems: nil,
//            bubble: {nil},
//            isVisible: { true }
//        )
//        jupyterManager.runner.consoleView.resetAndSetNewRootDirectory(url: URL(fileURLWithPath: app.workSpaceStorage.currentDirectory.url))
//        contribution.activityBar.registerItem(item: outline)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        JupyterExtension.jupyterManager.runner.consoleView.executor?.setNewWorkingDirectory(url: newUrl)
    }
}
