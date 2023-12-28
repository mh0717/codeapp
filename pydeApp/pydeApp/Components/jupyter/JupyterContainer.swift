//
//  JupyterContainer.swift
//  pydeApp
//
//  Created by Huima on 2023/11/28.
//

import Foundation
import SwiftUI
import pydeCommon
import python3_objc
import CryptoKit

struct JupyterContainer: View {
    
    @EnvironmentObject var App: MainApp
    
    
    
    @ObservedObject var jupyterManager: JupytterManager
    
    
    var body: some View {
        GeometryReader {greader in
            List {
                Section(
                    header:
                        Text("Jupyter Notebook")
                        .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
                ) {
                    Group {
                        Group {
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                
                                TextField("Port", text: $jupyterManager.port)
                                    .keyboardType(.numberPad)
                                    .disabled(jupyterManager.running)
                            }
                            
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                
                                SecureField(
                                    "Password",
                                    text: $jupyterManager.password
                                ).disabled(jupyterManager.running)
                            }
                            
                        }
                    }
                    .padding(7)
                    .background(Color.init(id: "input.background"))
                    .cornerRadius(15)
                    
                    
                    Button(action: {
                        App.safariManager.showSafari(
                            url: URL(
                                string:
                                    "https://code.thebaselab.com/guides/connecting-to-a-remote-server-ssh-ftp#set-up-your-remote-server"
                            )!)
                    }) {
                        Text("remote.setup_remote_server")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    
                    Toggle("保持前台", isOn: $jupyterManager.play_ws)
                    
                    
                    Toggle("公开访问", isOn: $jupyterManager.public_server)
                        .disabled(jupyterManager.running)
                    
                    if jupyterManager.running {
                        Button(action: {
                            
                        }) {
                            Text(
                                jupyterManager.public_server
                                ? "\(jupyterManager.ip):\(jupyterManager.port)"
                                : "localhost:\(jupyterManager.port)")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    
                    Button(
                        action: {
                            #if DEBUG
                            if isXCPreview() {
                                withAnimation(.easeIn) {
                                    jupyterManager.running = !jupyterManager.running
                                }
                                return
                            }
                            #endif
                            if jupyterManager.running {
                                jupyterManager.closeNotebook()
                            } else {
                                jupyterManager.openNotebook()
                            }
                        },
                        label: {
                            HStack {
                                Spacer()
                                Text(jupyterManager.running
                                     ? "停止"
                                     : "启动")
                                .lineLimit(1)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                Spacer()
                            }
                            .foregroundColor(Color.init("T1"))
                            .padding(4)
                            .background(
                                Color.init(id: "button.background")
                            )
                            .cornerRadius(10.0)
                        }
                    )
                    
                    if jupyterManager.running {
                        Button(
                            action: {
                                wmessager.passMessage(message: ["openurl", "http://localhost:\(jupyterManager.port)/tree"], identifier: ConstantManager.PYDE_OPEN_COMMAND_MSG);
                            },
                            label: {
                                HStack {
                                    Spacer()
                                    Text("打开JupyterNotebook")
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    Spacer()
                                }
                                .foregroundColor(Color.init("T1"))
                                .padding(4)
                                .background(
                                    Color.init(id: "button.background")
                                )
                                .cornerRadius(10.0)
                            }
                        )
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if jupyterManager.running {
                    jupyterManager.runner
                        .frame(height: greader.size.height)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                
            }
        }
    }
}

class JupytterManager: ObservableObject {
    @Published var running: Bool = false
    
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
    
    
    func openNotebook() {
        if runnerView.executor?.state != .idle {
            return
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
        
        runnerView.executor?.dispatch(command: command, isInteractive: false, completionHandler: { [self] _ in
            DispatchQueue.main.async { [self] in
                running = false
            }
        })
    }
}

class JupyterExtension: CodeAppExtension {
    
    let jupyterManager = JupytterManager()
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let outline = ActivityBarItem(
            itemID: "JUPYTER",
            iconSystemName: "book.pages",
            title: "JUPYTER",
            shortcutKey: "n",
            modifiers: [.command, .shift],
            view: AnyView(JupyterContainer(jupyterManager: jupyterManager)),
            contextMenuItems: nil,
            bubble: {nil},
            isVisible: { true }
        )
        jupyterManager.runner.consoleView.resetAndSetNewRootDirectory(url: URL(fileURLWithPath: app.workSpaceStorage.currentDirectory.url))
        contribution.activityBar.registerItem(item: outline)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        jupyterManager.runner.consoleView.executor?.setNewWorkingDirectory(url: newUrl)
    }
}




#Preview("Jupyter Notebook") {
    JupyterContainer(jupyterManager: JupytterManager())
}


