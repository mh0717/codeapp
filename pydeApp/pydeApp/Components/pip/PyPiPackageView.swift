//
//  PyPiPackageView.swift
//  Pyto
//
//  Created by Emma on 05-04-22.
//  Copyright © 2022 Emma Labbé. All rights reserved.
//

import SwiftUI

struct PyPiPackageView: View {
    
    
    @State var selectedVersion: String?
    @ObservedObject var pipManager: PipModelManager = pipModelManager
    
    let packageName: String
    
    @State var package: PipRemotePackage!
    @State var loaded = false
    
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
        if !self.loaded {
            return AnyView(ActivityIndicator(isAnimating: .constant(true), style: .medium)
                .onAppear {
                    Task {
                        if let package = await PipService.fetchRemotePackageInfo(self.packageName) {
                            await MainActor.run {
                                self.package = package
                                self.loaded = true
                            }
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


