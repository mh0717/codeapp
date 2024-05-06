//
//  SWCompEditor.swift
//  iPyDE
//
//  Created by Huima on 2024/4/28.
//

import Foundation
import ios_system
import SwiftUI

//class SWCompEditorInstance: EditorInstanceWithURL {
//    init(title: String, url: URL) {
//        super.init(view: AnyView(SWCompView(url: url)), title: title, url: url)
//    }
//}


extension URL {
    func withoutSame(_ name: String) -> URL?{
        let url = isDirectory ? self : self.deletingLastPathComponent()
        var seps = name.components(separatedBy: ".")
        var fext = ""
        var fname = name
        if seps.count == 1 {
            fname = name
        } else {
            fext = "." + seps.removeLast()
            fname = seps.joined(separator: ".")
        }
        
        let newUrl = url.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: newUrl.path) {
            return newUrl
        }
        
        for i in 1...100 {
            let newName = "\(fname)(\(i))\(fext)"
            let newUrl = url.appendingPathComponent(newName)
            if !FileManager.default.fileExists(atPath: newUrl.path) {
                return newUrl
            }
        }
        return nil
    }
}

//struct SWCompView :View {
//    let url: URL
//    @EnvironmentObject var App: MainApp
//    
//    @State var showsDirectoryPicker = false
//    
//    func untar(_ toUrl: URL) {
//        App.notificationManager.showAsyncNotification(title: "解压缩: \(url.lastPathComponent)\nswcomp zip \(url.path) -e .", task: {
//            _ = await Task {
//                _ = toUrl.startAccessingSecurityScopedResource()
//                let name = url.deletingPathExtension().lastPathComponent
//    //            let exdir = url.deletingLastPathComponent().withoutSame(name) ?? url.deletingLastPathComponent()
//                let exdir = toUrl.withoutSame(name) ?? toUrl.appendingPathComponent(name)
//                try? FileManager.default.createDirectory(at: exdir, withIntermediateDirectories: true)
//                let newCommand = "swcomp zip \(url.path.replacingOccurrences(of: " ", with: #"\ "#)) -e \(exdir.path.replacingOccurrences(of: " ", with: #"\ "#))"
//                ios_switchSession(newCommand)
//                ios_setContext(newCommand)
//                
//                var pid = ios_fork()
//                
//                let returnCode = ios_system(newCommand)
//                ios_waitpid(pid)
//                ios_releaseThreadId(pid)
//                
//                if returnCode == 0 {
//                    App.notificationManager.showSucessMessage("sucess")
//                } else {
//                    App.notificationManager.showErrorMessage("failed")
//                }
//            }.value
//        })
//    }
//    
//    var body: some View {
//        VStack {
//            Button("unzip", systemImage: "folder") {
//                untar(url.deletingLastPathComponent())
//            }
//            
//            Button("unzip to", systemImage: "folder") {
//                showsDirectoryPicker.toggle()
//            }
//        }.sheet(isPresented: $showsDirectoryPicker) {
//            DirectoryPickerView(onOpen: { toUrl in
//                untar(toUrl)
//            })
//        }
//    }
//}

private let SWCOMP_COMMANDS = [
    "zip": "swcomp zip {input} -e {output}",
    "gz": "swcomp gz {input} {output} -d",
    "xz": "swcomp xz {input} {output}",
    "lz4": "swcomp lz4 {input} {output} -d",
    "lzma": "swcomp lzma {input} {output}",
    "bz2": "swcomp bz2 {input} {output} -d",
    "tar": "swcomp tar {input} -e {output}",
    "7z": "swcomp 7z {input} -e {output}",
]

private func unarchive(_ App: MainApp, _ url: URL, _ toUrl: URL) {
    let ext = url.pathExtension.lowercased()
    guard let command = SWCOMP_COMMANDS[ext] else {
        return
    }
    
    App.notificationManager.showAsyncNotification(title: "Decompress: %@", task: {
        _ = await Task.detached(operation: {
            let name = url.deletingPathExtension().lastPathComponent
//            let exdir = url.deletingLastPathComponent().withoutSame(name) ?? url.deletingLastPathComponent()
            let exdir = toUrl.withoutSame(name) ?? toUrl.appendingPathComponent(name)
            try? FileManager.default.createDirectory(at: exdir, withIntermediateDirectories: true)
            let newCommand = command.replacingFirstOccurrence(of: "{input}", with: url.path.replacingOccurrences(of: " ", with: #"\ "#)).replacingOccurrences(of: "{output}", with: exdir.path.replacingOccurrences(of: " ", with: #"\ "#))
//            let newCommand = "swcomp zip \(url.path.replacingOccurrences(of: " ", with: #"\ "#)) -e \(exdir.path.replacingOccurrences(of: " ", with: #"\ "#))"
            ios_switchSession(newCommand)
            ios_setContext(newCommand)
            
            let pid = ios_fork()
            
            var returnCode = ios_system(newCommand)
            ios_waitpid(pid)
            ios_releaseThreadId(pid)
            if returnCode == 0 {
                returnCode = ios_getCommandStatus();
            }
            
            if returnCode == 0 {
                App.notificationManager.showSucessMessage("Decompress %@ Succed", url.lastPathComponent)
            } else {
                App.notificationManager.showErrorMessage("Decompress %@ Failed", url.lastPathComponent)
            }
        }).value
    }, url.lastPathComponent)
}

class SWCompViewerExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {

//        let provider = EditorProvider(
//            registeredFileExtensions: ["zip", "gzip", "7z"],
//            onCreateEditor: { url in
//                
//                let editorInstance = EditorInstanceWithURL(view: AnyView(SWCompView(url: url).id(UUID())), title: url.lastPathComponent, url: url)
//
//                return editorInstance
//            }
//        )
//        contribution.editorProvider.register(provider: provider)
        
        let untar = ToolbarItem(
            extenionID: "SWCOMP",
            icon: "archivebox",
            onClick: {
//                if let editor = app.activeEditor as? EpubEditorInstance {
//                    editor.readerVC.centerViewController?.presentFontsMenu()
//                }
            },
            shouldDisplay: {
                guard let editor = app.activeEditor as? EditorInstanceWithURL, SWCOMP_COMMANDS.keys.contains(editor.url.pathExtension.lowercased()) else {
                    return false
                }
                return true
            },
            menuItems: [
                ToolbarMenuItem(icon: "archivebox", title: "Decompression", onClick: {
                    guard let editor = app.activeEditor as? EditorInstanceWithURL else {
                        return;
                    }
                    let url = editor.url
                    
                    let toUrl = url.deletingLastPathComponent()
                    
                    unarchive(app, url, toUrl)
                }),
                ToolbarMenuItem(icon: "folder", title: "Decompression to", onClick: {
                    guard let editor = app.activeEditor as? EditorInstanceWithURL else {
                        return;
                    }
                    let url = editor.url
                    
                    app.popupManager.showSheet(content: AnyView(
                        DirectoryPickerView(onOpen: { toUrl in
                            unarchive(app, url, toUrl)
                        })
                    ))
                }),
            ]
        )
        
        
        contribution.toolBar.registerItem(item: untar)
        
        let unarchiveItem = FileMenuItem(iconSystemName: "archivebox", title: "Decompression") { url in
            SWCOMP_COMMANDS.keys.contains(url.pathExtension.lowercased())
        } onClick: { url in
            let toUrl = url.deletingLastPathComponent()
            unarchive(app, url, toUrl)
        }
        
        let unarchiveToItem = FileMenuItem(iconSystemName: "folder", title: "Decompression to") { url in
            SWCOMP_COMMANDS.keys.contains(url.pathExtension.lowercased())
        } onClick: { url in
            app.popupManager.showSheet(content: AnyView(
                DirectoryPickerView(onOpen: { toUrl in
                    unarchive(app, url, toUrl)
                })
            ))
        }
        
        app.extensionManager.fileMenuManager.registerItem(item: unarchiveItem)
        app.extensionManager.fileMenuManager.registerItem(item: unarchiveToItem)

    }
    
    
}
