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
    
    @State var running = false
    
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
                    App.notificationManager.showAsyncNotification(title: "正在安装: \(package)", task: {
                        let result = await pipModelManager.installPackage(package)
                        if result {
                            App.notificationManager.showErrorMessage("%@ 安装成功", package)
                        } else {
                            App.notificationManager.showErrorMessage("%@ 安装失败", package)
                        }
                        running = false
                    })
                case .uninstall:
                    App.notificationManager.showAsyncNotification(title: "正在删除: \(package)", task: {
                        let result = await pipModelManager.uninstallPackage(package)
                        if result {
                            App.notificationManager.showErrorMessage("%@ 删除成功", package)
                        } else {
                            App.notificationManager.showErrorMessage("%@ 删除失败", package)
                        }
                        running = false
                    })
                case .update:
                    App.notificationManager.showAsyncNotification(title: "正在更新: \(package)", task: {
                        let result = await pipModelManager.updatePackages([package])
                        if result {
                            App.notificationManager.showErrorMessage("%@ 更新成功", package)
                        } else {
                            App.notificationManager.showErrorMessage("%@ 更新失败", package)
                        }
                        running = false
                    })
                case .updateAll:
                    App.notificationManager.showAsyncNotification(title: "正在更新: \(package)", task: {
                        let result = await pipModelManager.updatePackages(package.components(separatedBy: ","))
                        if result {
                            App.notificationManager.showErrorMessage("%@ 更新成功", package)
                        } else {
                            App.notificationManager.showErrorMessage("%@ 更新失败", package)
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
                    ? Text("安装中", comment: "删除中")
                    : Text("安装", comment: "删除")
                case .uninstall:
                    running
                    ? Text("删除中", comment: "删除中")
                    : Text("删除", comment: "删除")
                case .update:
                    running
                    ? Text("更新中", comment: "更新中")
                    : Text("更新", comment: "更新")
                case .updateAll:
                    running
                    ? Text("更新中", comment: "更新中")
                    : Text("更新", comment: "更新")
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
                    PipOpButton(package: package, op: op)
                    
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
                            PipOpButton(package: pipManager.updatablePackages.map({$0.name}).joined(separator: ","), op: .updateAll)
                            
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
                                Text("pypi.updates", comment: "Updatable packages")
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
                        Text("pypi.installed", comment: "Installed packages")
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
                        Text("pypi.bundled", comment: "Bundled packages")
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
            
            TextField(NSLocalizedString("search", comment: "Placeholder of the search bar"), text: $text)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
        }
            .padding(7)
            .padding(.horizontal, 25)
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
