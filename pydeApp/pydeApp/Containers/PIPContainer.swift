//
//  PIPManager.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import SwiftUI
import Combine
import pydeCommon
import pyde
import UniformTypeIdentifiers





private var pypiFirstFetched = false

@available(iOS 13.0.0, *)
public struct PIPContainer: View {
    @State var updating = [String]()
    @ObservedObject var pipManager = pipModelManager
    @EnvironmentObject var App: MainApp
    
    public var body: some View {
        List {
            Section {
                PYSearchBar(text: $pipManager.queryString)
            } header: {
                HStack{
                    Text("pypi")
                    Spacer()
                    Menu {
                        Button("Install Wheel", systemImage: "arrow.down.to.line.compact") {
                            let types = [UTType(filenameExtension: "whl")!]
                            let picker = FilePickerView(onOpen: { url in
                                let newUrl = ConstantManager.TMP.appendingPathComponent(url.lastPathComponent)
                                try? FileManager.default.removeItem(at: newUrl)
                                try? FileManager.default.copyItem(at: url, to: newUrl)
                                WheelExtensionManager.install(newUrl, app: App)
                            }, allowedTypes: types)
                            App.popupManager.showSheet(content: AnyView(picker))
                        }
                        
                        Button("Open pypi", systemImage: "globe") {
                            App.openFile(url: URL(string: "https://pypi.org")!, alwaysInNewTab: true)
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 17))
                            .foregroundColor(Color.init("T1"))
                            .padding(5)
                            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .hoverEffect(.highlight)
                    }
                }
            }.listRowSeparator(.hidden).listRowBackground(Color.clear)
            
            if !pipManager.queryString.isEmpty {
                Section {
                    ForEach(pipManager.queryPackages, id: \.self, content: { item in
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
                } header: {
                    Text(localizedString(forKey: "Search Result"))
                }
            } else {
                
                
//                if !pipManager.updatablePackages.isEmpty {
//
//                    Section {
//                        PipOpButton(package: pipManager.updatablePackages.map({$0.name}).joined(separator: ","), op: .updateAll, version: nil)
//
//                        ForEach(pipManager.updatablePackages) { pkg in
//                            DisclosureGroup {
//                                PipShow(package: pkg.name, op: .update)
//                            } label: {
//                                VStack {
//                                    HStack {
//                                        Image(systemName: "shippingbox")
//                                        Text(pkg.name).foregroundColor(.primary)
//                                        Spacer()
//                                        Text(pkg.version).foregroundColor(.secondary)
//                                    }
//                                }
//                            }
//                        }
//                    } header: {
//                        HStack {
//                            Text(localizedString(forKey:"Update"))
//                            ZStack {
//                                Circle().fill(.red).frame(width: 25, height: 25)
//                                Text("\(pipManager.updatablePackages.count)").foregroundColor(.white).font(.system(size: 15))
//                            }
//                        }
//                    }.listRowSeparator(.hidden).listRowBackground(Color.clear)
//                }
                
                ExpandedSection(
                    header: Text(localizedString(forKey:"Installed packages"))
                        .foregroundColor(Color(id: "sideBarSectionHeader.foreground")),
                    content: ForEach(pipManager.installedPackages) { pkg in
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
                ).listRowSeparator(.hidden).listRowBackground(Color.clear)
                
                ExpandedSection(
                    header: Text(localizedString(forKey: "Bunded packages"))
                        .foregroundColor(Color(id: "sideBarSectionHeader.foreground")),
                    content: ForEach(pipManager.bundledPackage) { pkg in
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
                ).listRowSeparator(.hidden).listRowBackground(Color.clear)
                
//                Section {
//                    ForEach(pipManager.installedPackages) { pkg in
//                        DisclosureGroup {
//                            PipShow(package: pkg.name, op: .uninstall)
//                        } label: {
//                            VStack {
//                                HStack {
//                                    Image(systemName: "shippingbox")
//                                    Text(pkg.name).foregroundColor(.primary)
//                                    Spacer()
//                                    Text(pkg.version).foregroundColor(.secondary)
//                                }
//                            }
//                        }
//                    }
//                } header: {
//                    Text(localizedString(forKey:"Installed packages"))
//                }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                
//                Section {
//                    ForEach(pipManager.bundledPackage) { pkg in
//                        DisclosureGroup {
//                            PipShow(package: pkg.name, op: .uninstall)
//                        } label: {
//                            VStack {
//                                HStack {
//                                    //                                            if Python.shared.fullVersionExclusives.contains(pkg.name) {
//                                    //                                                Image(systemName: "lock\(isLiteVersion.boolValue ? "" : ".open").fill").foregroundColor(isLiteVersion.boolValue ? .red : .green)
//                                    //                                            }
//                                    Image(systemName: "shippingbox")
//                                    Text(pkg.name).foregroundColor(.primary)
//                                    Spacer()
//                                    Text(pkg.version).foregroundColor(.secondary)
//                                }
//                                //                                        if Python.shared.fullVersionExclusives.contains(pkg.name) {
//                                //                                            HStack {
//                                //                                                Text("pypi.fullversion", comment: "The subtitle of a package that is full version exclusive").foregroundColor(.secondary)
//                                //                                                Spacer()
//                                //                                            }
//                                //                                        }
//                            }
//                        }
//                    }
//                } header: {
//                    Text(localizedString(forKey: "Bunded packages"))
//                }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                
            }
        }
        .listRowSeparator(.hidden)
        .listStyle(.sidebar)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .onAppear {
            if pypiFirstFetched {
                return
            }
            pypiFirstFetched = true
            Task {
                PipService.updatePyPiCache()
                await pipManager.fetchInstalledPackages()
                await pipManager.fetchIndex()
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
            
            TextField(localizedString(forKey: "Search"), text: $text)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            Button {
                text = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .opacity(text.isEmpty ? 0 : 1)
            }
            
        }
            .padding(.vertical, 7)
            .padding(EdgeInsets(top: 0, leading: 25, bottom: 0, trailing: 5))
            .background(Color(.secondarySystemFill))
            .cornerRadius(8)
//            .padding(.horizontal, 10)
    }
}


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
                    
                    App.notificationManager.showAsyncNotification(title: localizedString(forKey: "Installing %@"), task: {
                        let result = await withCheckedContinuation { continuation in
                            let cmd = version == nil ? "pythonA -m pip install \(package)" : "pythonA -m pip install \(package)==\(version!)"
                            runnerWidget.consoleView.feed(text: "\(cmd)\r\n")
                            runnerWidget.consoleView.executor?.dispatch(command: "remote \(cmd) --user", completionHandler: { rlt in
                                continuation.resume(returning: rlt)
                            })
                            
                        }
                        
                        if result == 0 {
                            let msg = String(format: localizedString(forKey: "Successfully installed %@"), package)
                            runnerWidget.consoleView.feed(text: msg)
                        } else {
                            let msg = String(format: localizedString(forKey: "Failed to install %@"), package)
                            runnerWidget.consoleView.feed(text: msg)
                        }
                            
                        runnerWidget.consoleView.feed(text: "\r\n")
                        runnerWidget.consoleView.feed(text: runnerWidget.consoleView.executor.prompt)
                        
                        
                        if result == 0 {
                            App.notificationManager.showSucessMessage(localizedString(forKey: "Successfully installed %@"), package)
                        } else {
                            App.notificationManager.showErrorMessage(localizedString(forKey: "Failed to install %@"), package)
                        }
                        
                        await pipModelManager.fetchInstalledPackages()
                        
                        running = false
                    }, package)
                case .uninstall:
                    App.notificationManager.showAsyncNotification(title: localizedString(forKey: "Uninstalling %@"), task: {
                        let result = await pipModelManager.uninstallPackage(package)
                        if result {
                            App.notificationManager.showSucessMessage(localizedString(forKey: "Successfully uninstalled %@"), package)
                        } else {
                            App.notificationManager.showErrorMessage(localizedString(forKey: "Failed to uninstall %@"), package)
                        }
                        running = false
                    }, package)
                case .update:
                    App.notificationManager.showAsyncNotification(title: localizedString(forKey: "Updating %@"), task: {
                        let result = await pipModelManager.updatePackages([package])
                        if result {
                            App.notificationManager.showSucessMessage(localizedString(forKey: "Successfully Updated %@"), package)
                        } else {
                            App.notificationManager.showErrorMessage(localizedString(forKey: "Failed to update %@"), package)
                        }
                        running = false
                    }, package)
                case .updateAll:
                    App.notificationManager.showAsyncNotification(title: localizedString(forKey: "Updating all %@"), task: {
                        let result = await pipModelManager.updatePackages(package.components(separatedBy: ","))
                        if result {
                            App.notificationManager.showSucessMessage(localizedString(forKey: "Successfully updated %@"), package)
                        } else {
                            App.notificationManager.showErrorMessage(localizedString(forKey: "Failed to update %@"), package)
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
                    ? Text(localizedString("Installing...", comment: "删除中"))
                    : Text(localizedString("Install", comment: "删除"))
                case .uninstall:
                    running
                    ? Text(localizedString("Uninstalling...", comment: "删除中"))
                    : Text(localizedString("Uninstall", comment: "删除"))
                case .update:
                    running
                    ? Text(localizedString("Updating...", comment: "更新中"))
                    : Text(localizedString("Update", comment: "更新"))
                case .updateAll:
                    running
                    ? Text(localizedString("Updating all ...", comment: "更新中"))
                    : Text(localizedString("Update all", comment: "更新"))
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

struct PyPiPackageView: View {
    
    
    @State var selectedVersion: String?
    @ObservedObject var pipManager: PipModelManager = pipModelManager
    
    let packageName: String
    
    @State var package: PipRemotePackage!
    @State var loaded = false
    @State var loadFailed = false
    
    var isFullVersion: Bool {
        true
    }
    
    var isBundled: Bool {
        return PipModelManager.isBundlePackage(packageName)
    }
    
    var isInstalled: Bool {
        return pipModelManager.installedPackages.map({$0.name}).contains(packageName)
    }
    
    var links: [(title: String, url: URL)] {
        [(
            title: "PyPI",
            url: URL(string: "https://pypi.org/project/\(package.name ?? "")")!
        )]+package.links
    }
    
    var body: some View {
        if loadFailed {
            return AnyView(Button(action: {
                loadFailed = false
                Task {
                    if let package = await PipService.fetchRemotePackageInfo(self.packageName) {
                        await MainActor.run {
                            self.package = package
                            self.loaded = true
                        }
                    } else {
                        loadFailed = true
                    }
                }
            }, label: {
                Label {
                    Text("Retry")
                } icon: {
                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                        .foregroundColor(.secondary)
                }

            }))
        }
        if !self.loaded {
            return AnyView(ActivityIndicator(isAnimating: .constant(true), style: .medium)
                .onAppear {
                    Task {
                        if let package = await PipService.fetchRemotePackageInfo(self.packageName) {
                            await MainActor.run {
                                self.package = package
                                self.loaded = true
                            }
                        } else {
                            loadFailed = true
                        }
                    }
                })
        }
        return AnyView(VStack(alignment: .leading, spacing: 10) {
            
            if !isBundled && !isInstalled || true {
                Menu {
                    ForEach(package.versions, id: \.self) { version in
                        Button {
                            selectedVersion = version
                        } label: {
                            if version == selectedVersion {
                                Label {
                                    Text(version)
                                } icon: {
                                    Image(systemName: "checkmark")
                                }
                            } else {
                                Text(version)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedVersion ?? package.stableVersion ?? "").font(.title3)
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }.onAppear {
                    selectedVersion = package.versions.first
                }
            }
            
            isBundled || isInstalled
            ? PipOpButton(package: packageName, op: .uninstall, version: nil)
            : PipOpButton(package: packageName, op: .install, version: selectedVersion)
            
            
            
            if let desc = package.description {
                Text(desc)
            }
            
            Label {
                Text(package.author ?? "").bold()
            } icon: {
                Image(systemName: "person")
            }
            
            if let maintainer = package.maintainer, maintainer != package.author && !maintainer.isEmpty {
                Label {
                    Text(maintainer).bold()
                } icon: {
                    Image(systemName: "hammer")
                }
            }
            
            ForEach(links, id: \.url) { link in
                Link(destination: link.url) {
                    HStack {
                        Label {
                            Text(link.title).foregroundColor(.accentColor)
                        } icon: {
                            Image(systemName: "safari")
                        }
                        Spacer()
                        Image(systemName: "arrow.up.forward").foregroundColor(.accentColor)
                        EmptyView().frame(width: 20)
                    }
                }
            }
        })
    }
}





#Preview("PipContainer") {
    PIPContainer()
}



func isXCPreview() -> Bool {
//    return true
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
