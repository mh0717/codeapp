//
//  PyPiView.swift
//  SwiftUI Views
//
//  Created by Emma Labbé on 13-06-20.
//  Copyright © 2018-2021 Emma Labbé. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import pydeCommon
import pyde

let DidRunPipNotificationName = Notification.Name("DidRunPipNotification")

let DidPressInstallWheelButtonNotificationName = Notification.Name(rawValue: "DidPressInstallWheelButtonNotification")



@available(iOS 13.0, *)
struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct PipOpButton: View {
    enum Operation {
        case install
        case uninstall
        case update
        case updateAll
    }
    
    @EnvironmentObject var App: MainApp
    
    let package: String
    let op: Operation
    let version: String?
    
    @State var running = false
    
    @State var showTerminal = false
    
    var body: some View {
        Button() {
            Task {
                if running {return}
                running = true
                #if DEBUG
                if isXCPreview() {
                    switch op {
                    case .install:
                        let _ = await pipModelManager.installPackage(package)
                    case .uninstall:
                        let _ = await pipModelManager.uninstallPackage(package)
                    case .update:
                        let _ = await pipModelManager.updatePackages([package])
                    case .updateAll:
                        let _ = await pipModelManager.updatePackages(package.components(separatedBy: ","))
                    }
                    running = false
                    return
                }
                #endif
                switch op {
                case .install:
                    let runnerWidget = PYRunnerWidget()
                    App.popupManager.showSheet(content: AnyView(
                        NavigationView(content: {
                            runnerWidget.navigationTitle(Text("pip install \(package)")).padding().toolbar(content: {
                                SwiftUI.ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        App.popupManager.showSheet = false
                                    }
                                }
                            })
                        })
                        
                    ))
                    
                    App.notificationManager.showAsyncNotification(title: "Installing %@", task: {
                        _ = await withCheckedContinuation { continuation in
                            let cmd = version == nil ? "pip3 install \(package)" : "pip3 install \(package)==\(version!)"
                            runnerWidget.consoleView.feed(text: "\(cmd)\r\n")
                            runnerWidget.consoleView.executor?.dispatch(command: "remote \(cmd) --user", completionHandler: { rlt in
                                continuation.resume(returning: true)
                            })
                            
                        }
                        await pipModelManager.fetchInstalledPackages()
                        let result = pipModelManager.installedPackages.contains(where: {$0.name == package})
//                        let result = await pipModelManager.installPackage(package)
                        if result {
                            App.notificationManager.showErrorMessage("Successfully installed %@", package)
                        } else {
                            App.notificationManager.showErrorMessage("Failed to install %@", package)
                        }
                        running = false
                    }, package)
                case .uninstall:
                    App.notificationManager.showAsyncNotification(title: "Uninstall \(package)", task: {
                        let result = await pipModelManager.uninstallPackage(package)
                        if result {
                            App.notificationManager.showErrorMessage("Successfully uninstalled %@", package)
                        } else {
                            App.notificationManager.showErrorMessage("Failed to uninstall %@", package)
                        }
                        running = false
                    })
                case .update:
                    App.notificationManager.showAsyncNotification(title: "Updating %@", task: {
                        let result = await pipModelManager.updatePackages([package])
                        if result {
                            App.notificationManager.showErrorMessage("Successfully Updated %@", package)
                        } else {
                            App.notificationManager.showErrorMessage("Failed to update %@", package)
                        }
                        running = false
                    }, package)
                case .updateAll:
                    App.notificationManager.showAsyncNotification(title: "Updating %@", task: {
                        let result = await pipModelManager.updatePackages(package.components(separatedBy: ","))
                        if result {
                            App.notificationManager.showErrorMessage("Successfully Updated %@", package)
                        } else {
                            App.notificationManager.showErrorMessage("Failed to update %@", package)
                        }
                        running = false
                    })
                }
                
            }
        } label: {
            Label {
                switch op {
                case .install:
                    running
                    ? Text("Installing", comment: "删除中")
                    : Text("Install", comment: "删除")
                case .uninstall:
                    running
                    ? Text("Uninstalling", comment: "删除中")
                    : Text("Uninstall", comment: "删除")
                case .update:
                    running
                    ? Text("Updating", comment: "更新中")
                    : Text("Update", comment: "更新")
                case .updateAll:
                    running
                    ? Text("Updating", comment: "更新中")
                    : Text("Update", comment: "更新")
                }
            } icon: {
                Group {
                    if running {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        switch op {
                        case .install:
                            Image(systemName: "square.and.arrow.down.fill").foregroundColor(PipModelManager.isBundlePackage(package) ? .secondary : .red)
                        case .uninstall:
                            Image(systemName: "trash").foregroundColor(PipModelManager.isBundlePackage(package) ? .secondary : .red)
                        case .update:
                            Image(systemName: "arrow.counterclockwise").foregroundColor(.secondary)
                        case .updateAll:
                            Image(systemName: "arrow.counterclockwise").foregroundColor(.secondary)
                        }
                    }
                    
                }
            }.frame(maxWidth: .infinity, minHeight: 30)
        }
        .disabled(PipModelManager.isBundlePackage(package))
        .buttonStyle(.bordered)
    }
}

struct PipShow: View {
    
    @EnvironmentObject var App: MainApp
    
    let package: String
    let op: PipOpButton.Operation
    
    @State var info: String?
    @State var running = false
    
    var body: some View {
        Group {
            if info == nil {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else {
                VStack(alignment: .leading) {
                    PipOpButton(package: package, op: op, version: nil)
                    
                    Text(info!).font(.custom("Menlo", size: UIFont.systemFontSize)).textSelection(.enabled)
                }
            }
        }.onAppear {
            if info != nil && !info!.isEmpty {return}
            Task {
                let output = await PipService.fetchLocalPackageInfo(package)
                let shorten = ShortenFilePaths(in: output)
                await MainActor.run {
                    info = shorten
                }
            }
        }
    }
}

@available(iOS 13.0.0, *)
public struct PyPiView: View {
    @State var updating = [String]()
    @ObservedObject var pipManager = pipModelManager
    
    public var body: some View {
        VStack {
            PYSearchBar(text: $pipManager.queryString)
            if !pipManager.queryString.isEmpty {
                List(pipManager.queryPackages, id: \.self, rowContent: { item in
                    DisclosureGroup {
                        PyPiPackageView(packageName: item)
                    } label: {
                        HStack{
                            Image(systemName: "shippingbox")
                            if item.lowercased() == pipManager.queryString.lowercased() {
                                Text(item).fontWeight(.bold).foregroundColor(.primary)
                            } else {
                                Text(item).foregroundColor(.primary)
                            }
                        }
                    }.listRowBackground(Color.clear).listRowSeparator(.hidden)
                }).listStyle(.sidebar)
            } else {
                List {
                    if !pipManager.updatablePackages.isEmpty {
                        
                        Section {
                            PipOpButton(package: pipManager.updatablePackages.map({$0.name}).joined(separator: ","), op: .updateAll, version: nil)
                            
                            ForEach(pipManager.updatablePackages) { pkg in
                                DisclosureGroup {
                                    PipShow(package: pkg.name, op: .update)
                                } label: {
                                    VStack {
                                        HStack {
                                            Image(systemName: "shippingbox")
                                            Text(pkg.name).foregroundColor(.primary)
                                            Spacer()
                                            Text(pkg.version).foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text("Update", comment: "Updatable packages")
                                ZStack {
                                    Circle().fill(.red).frame(width: 25, height: 25)
                                    Text("\(pipManager.updatablePackages.count)").foregroundColor(.white).font(.system(size: 15))
                                }
                            }
                        }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                    }
                    
                    Section {
                        ForEach(pipManager.installedPackages) { pkg in
                            DisclosureGroup {
                                PipShow(package: pkg.name, op: .uninstall)
                            } label: {
                                VStack {
                                    HStack {
                                        Image(systemName: "shippingbox")
                                        Text(pkg.name).foregroundColor(.primary)
                                        Spacer()
                                        Text(pkg.version).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Installed packages", comment: "已经安装的库")
                    }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                    
                    Section {
                        ForEach(pipManager.bundledPackage) { pkg in
                            DisclosureGroup {
                                PipShow(package: pkg.name, op: .uninstall)
                            } label: {
                                VStack {
                                    HStack {
                                        //                                            if Python.shared.fullVersionExclusives.contains(pkg.name) {
                                        //                                                Image(systemName: "lock\(isLiteVersion.boolValue ? "" : ".open").fill").foregroundColor(isLiteVersion.boolValue ? .red : .green)
                                        //                                            }
                                        Image(systemName: "shippingbox")
                                        Text(pkg.name).foregroundColor(.primary)
                                        Spacer()
                                        Text(pkg.version).foregroundColor(.secondary)
                                    }
                                    //                                        if Python.shared.fullVersionExclusives.contains(pkg.name) {
                                    //                                            HStack {
                                    //                                                Text("pypi.fullversion", comment: "The subtitle of a package that is full version exclusive").foregroundColor(.secondary)
                                    //                                                Spacer()
                                    //                                            }
                                    //                                        }
                                }
                            }
                        }
                    } header: {
                        Text("Bunded packages", comment: "内置的库")
                    }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                }
                .listRowSeparator(.hidden)
                .listStyle(.sidebar)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .onAppear {
            Task {
                await pipManager.fetchInstalledPackages()
            }
        }.listStyle(SidebarListStyle())
    }
}



@available(iOS 13.0, *)
struct PYSearchBar: View {
    
    @Binding var text: String
        
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
            .padding(.horizontal, -20)
            
            TextField(NSLocalizedString("search", comment: "搜索占位符"), text: $text)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            Button {
                text = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .opacity(text.isEmpty ? 0 : 1)
            }
            
        }
            .padding(7)
            .padding(EdgeInsets(top: 0, leading: 25, bottom: 0, trailing: 5))
            .background(Color(.secondarySystemFill))
            .cornerRadius(8)
            .padding(.horizontal, 10)
    }
}



#Preview("PipContainer") {
    PyPiView()
}



func isXCPreview() -> Bool {
//    return true
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
