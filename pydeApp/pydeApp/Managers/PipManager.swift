//
//  runPip.swift
//  Pyto
//
//  Created by Emma on 06-04-22.
//  Copyright © 2022 Emma Labbé. All rights reserved.
//

import Foundation
import pydeCommon
import Combine




func ShortenFilePaths(in str: String) -> String {
    
    var text = str
    
    let docs = ConstantManager.documentURL
    
    text = str.replacingOccurrences(of: docs.path, with: "Documents")
    text = text.replacingOccurrences(of: "/privateDocuments", with: "Documents")
    if let iCloudDrive = ConstantManager.iCloudContainerURL {
        text = text.replacingOccurrences(of: iCloudDrive.path, with: "iCloud Drive")
        text = text.replacingOccurrences(of: iCloudDrive.deletingLastPathComponent().lastPathComponent, with: "iCloud Drive")
    }
    
    text = text.replacingOccurrences(of: Bundle.main.bundlePath, with: "pydeApp.app")
//    text = text.replacingOccurrences(of: "/privatePyto.app", with: "Pyto.app")
        
    text = text.replacingOccurrences(of: (URL(fileURLWithPath: "/private").appendingPathComponent(docs.deletingLastPathComponent().path).path).replacingOccurrences(of: "//", with: "/")+"/", with: "")
    text = text.replacingOccurrences(of: URL(fileURLWithPath: "/private").appendingPathComponent(docs.deletingLastPathComponent().path).path.replacingOccurrences(of: "//", with: "/"), with: "")
    text = text.replacingOccurrences(of: docs.deletingLastPathComponent().path+"/", with: "")
    text = text.replacingOccurrences(of: docs.deletingLastPathComponent().path, with: "")
    
    return text
}


public struct PipPackage: Identifiable, Equatable {
    init(_ name: String, _ version: String) {
        self.name = name
        self.version = version
        self.id = UUID().uuidString
    }
    
    public let id: String
    
    let name: String
    let version: String
}

private func filterQuery(_ list: [String], _ query: String) -> [String] {
    let result = list.filter({$0.lowercased().contains(query)})
        .sorted {
            let lquery = query.lowercased()
            if $0.lowercased() == lquery {
                return true
            }
            if $1.lowercased() == lquery {
                return false
            }
            if $0.hasPrefix(query) {
                return true
            }
            if $1.hasPrefix(query) {
                return false
            }
            if $0.lowercased().hasPrefix(lquery) {
                return true
            }
            if $1.lowercased().hasPrefix(lquery) {
                return false
            }
            
            if $0.contains(query) {
                return true
            }
            
            if $1.contains(query) {
                return false
            }
            
            if $0.lowercased().contains(lquery) {
                return true
            }
            
            if $1.lowercased().contains(lquery) {
                return false
            }
            
            return $0 < $1
        }
        .prefix(200)
        
    return [String](result)
}


class PipModelManager: ObservableObject {
    
    @Published var packages: [String] = []
    @Published var installedPackages: [PipPackage] = []
    @Published var updatablePackages: [PipPackage] = []
    
    @Published var queryString: String = ""
    
    @Published var queryPackages: [String] = []
    
    
    var cancellable: Set<AnyCancellable> = []
    
    var bundledPackage: [PipPackage] {
        pipBundledPackage
    }
    
    
    init() {
        Task {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
//            await self.fetchInstalledPackages()
//            await self.fetchUpdates()
        }
        
//        Task {
//            await self.fetchIndex()
//        }
//        
        $queryString
            .map({$0.trimmingCharacters(in: .whitespaces)})
            .filter({!$0.isEmpty})
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.global())
            .map({
                if self.packages.isEmpty {
                    Task {
                        await self.fetchIndex()
                    }
                }
                return $0
            })
            .flatMap({ [self] query in
                $packages.map({filterQuery($0, query)})
            })
            .map({[String]($0)})
            .receive(on: DispatchQueue.main)
            .assign(to: \.queryPackages, on: self)
            .store(in: &cancellable)
    }
    
    private var shouldFetchIndex = false
    func fetchIndex() async {
        if shouldFetchIndex {
            return
        }
        
        shouldFetchIndex = true
        let packages = await PipService.fetchIndexPackages()
        if !packages.isEmpty {
            await MainActor.run {
                self.packages = packages
            }
        } else {
            shouldFetchIndex = false
        }
    }
    
    func fetchInstalledPackages() async  {
        guard let packages = await PipService.fetchInstalledPackages() else {
            return
        }
        
        await MainActor.run {
            self.installedPackages = packages
        }
    }
    
    func fetchUpdates() async{
        let packages = await PipService.fetchUpdatablePackages()
        await MainActor.run {
            self.updatablePackages = packages
        }
    }
    
    static func isBundlePackage(_ name: String) -> Bool {
        return pipBundledPackage.contains {$0.name == name}
    }
    
    func uninstallPackage(_ name: String) async -> Bool {
        if await PipService.uninstallPackage(name) {
            await MainActor.run {
                self.installedPackages.removeAll(where: {$0.name == name})
            }
            return true
        }
        
        return false
    }
    
    func updatePackages(_ packages: [String]) async -> Bool {
        if await PipService.updatePackages(packages) {
            await MainActor.run {
                self.updatablePackages.removeAll(where: {packages.contains($0.name)})
            }
            return true
        }
        
        return false
    }
    
    func installPackage(_ package: String) async -> Bool {
        if await PipService.installPackage(package) {
            #if DEBUG
            if isXCPreview() {
                installedPackages.append(PipPackage(package, "1.3"))
                return true
            }
            #endif
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 100)
            await fetchInstalledPackages()
            return true
        }
        
        return false
    }
}

let pipModelManager = PipModelManager()

