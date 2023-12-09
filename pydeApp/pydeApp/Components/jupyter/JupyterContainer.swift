//
//  JupyterContainer.swift
//  pydeApp
//
//  Created by Huima on 2023/11/28.
//

import Foundation
import SwiftUI
import pydeCommon


struct JupyterContainer: View {
    
    @EnvironmentObject var App: MainApp
    
    @AppStorage("jupyter_server_password") var password: String = ""
    @AppStorage("jupyter_server_port") var port: String = "8888"
    @AppStorage("jupyter_server_public") var public_server: Bool = false
    
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
                                
                                TextField("Port", text: $port)
                                    .keyboardType(.numberPad)
                            }
                            
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                
                                SecureField(
                                    "Password",
                                    text: $password
                                )
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
                    
                    
                    Toggle("公开访问", isOn: $public_server)
                    
                    
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
    
    let runner = PYRunnerWidget()
    
    lazy var runnerWidget: AnyView = AnyView(runner.id(UUID()))
    
    var runnerView: ConsoleView {
        return runner.consoleView
    }
}

class JupyterExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let outline = ActivityBarItem(
            itemID: "JUPYTER",
            iconSystemName: "book.pages",
            title: "JUPYTER",
            shortcutKey: "n",
            modifiers: [.command, .shift],
            view: AnyView(JupyterContainer(jupyterManager: JupytterManager())),
            contextMenuItems: nil,
            bubble: {nil},
            isVisible: { true }
        )
        
        contribution.activityBar.registerItem(item: outline)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        
    }
}




#Preview("Jupyter Notebook") {
    JupyterContainer(jupyterManager: JupytterManager())
}


