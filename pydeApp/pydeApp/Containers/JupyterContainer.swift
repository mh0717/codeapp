//
//  JupyterContainer.swift
//  pydeApp
//
//  Created by Huima on 2023/11/28.
//

import Foundation
import SwiftUI
import pydeCommon
import python3Objc
import CryptoKit

private var topYChanged: Bool = false

struct JupyterContainer: View {
    
    @EnvironmentObject var App: MainApp
    
    @ObservedObject var jupyterManager: JupyterManager
    
    @State var consoleHeight: Double = 1000
    @State var topY: Double = 80
    
    
    var body: some View {
        GeometryReader {greader in
            List {
                PYExpandedSection(
                    header: 
                        Text("Jupyter Notebook")
                        .background {
                            GeometryReader { proxy -> Color in
                                topY = proxy.frame(in: .global).origin.y
                                topYChanged = true
                                return Color.clear
                            }
                        },
                    content: {
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
                        
    //                    Toggle(localizedString(forKey: "Keep Activation"), isOn: $jupyterManager.play_ws)
                        
                        
                        Toggle(localizedString(forKey: "Public Access"), isOn: $jupyterManager.public_server)
                            .disabled(jupyterManager.running)
                        
                        if jupyterManager.running {
                            let url = jupyterManager.public_server
                                ? "http://\(jupyterManager.ip):\(jupyterManager.port)"
                                : "http://localhost:\(jupyterManager.port)"
                            Menu {
                                Button("Open Url") {
                                    if let url = URL(string: "http://localhost:\(jupyterManager.port)") {
                                        App.appendAndFocusNewEditor(editor: PYSafariEditorInstance(url), alwaysInNewTab: true)
                                    }
                                }
                                Button("Copy to Pasteboard") {
                                    UIPasteboard.general.string = url
                                }
                            } label: {
                                Text(url)
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
                                jupyterManager.firstRuned = true
                                if jupyterManager.running {
                                    jupyterManager.closeNotebook()
                                } else {
                                    jupyterManager.openNotebook(URL(string: App.workSpaceStorage.currentDirectory.url))
                                }
                            },
                            label: {
                                HStack {
                                    Spacer()
                                    Text(jupyterManager.running
                                         ? localizedString(forKey: "Stop Server")
                                         : localizedString(forKey: "Start Server"))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    Spacer()
                                }
                                .foregroundColor(Color.init("T1"))
//                                .padding(4)
                                .padding(EdgeInsets(top: 7, leading: 5, bottom: 7, trailing: 5))
                                .background(
                                    Color.init(id: "button.background")
                                )
                                .cornerRadius(10.0)
                            }
                        )
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if jupyterManager.firstRuned {
                    jupyterManager.runner
                        .frame(height: consoleHeight)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .background {
                            GeometryReader { proxy -> Color in
                                let consoleTop = proxy.frame(in: .global).origin.y
                                
                                if topYChanged {
                                    topYChanged = false
                                    DispatchQueue.main.async {
//
                                        let height = greader.size.height -  (consoleTop - topY) - 40
                                        if abs(height - consoleHeight) > 1 {
                                            consoleHeight = height
                                        }
                                        print(consoleHeight)
                                    }
                                } else {
                                    let height = greader.size.height -  (consoleTop - topY) - 40
                                    if abs(height - consoleHeight) > 70 {
                                        consoleHeight = height
                                    }
                                }
                                return Color.clear
                            }
                        }
                }
                
            }
            .listStyle(SidebarListStyle())
        }
    }
}





#Preview("Jupyter Notebook") {
    JupyterContainer(jupyterManager: JupyterManager())
}


