//
//  PYApp.swift
//  Code
//
//  Created by Huima on 2024/5/7.
//

import Foundation
import SwiftUI
import pydeCommon
import ios_system

class PYApp: ObservableObject {
    
    weak var App: MainApp?
    
    @Published var showAddressbar = false
    @Published var addressUrl = ""
    
    init() {
        NotificationCenter.default.addObserver(forName: .init("UI_OPEN_FILE_IN_TAB"), object: nil, queue: nil) { [weak self] notify in
            guard let url = notify.userInfo?["url"] as? URL else { return }
            
            self?.openUrl(url)
        }
    }
    
    
    func openUrl(_ url: URL) {
        guard let App else {return}
        
        if FileManager.default.fileExists(atPath: url.path) {
            if url.isFileURL, url.path.contains("Jupyter/runtime/nbserver") {
                var localUrl = "http://localhost:\(JupyterExtension.jupyterManager.port)/tree"
                do {
                    let content = try String(contentsOf: url)
                    let lines = content.components(separatedBy: "\n")
                    for line in lines {
                        if line.contains("\"http://"), let name = line.slice(from: "\"http://", to: "\"") {
                            localUrl = "http://\(name)"
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
                localUrl = localUrl.replacingOccurrences(of: "0.0.0.0", with: "localhost")
                DispatchQueue.main.async {
                    if let url = URL(string: localUrl) {
                        App.appendAndFocusNewEditor(editor: PYSafariEditorInstance(url), alwaysInNewTab: true)
                    }
                    
                }
                return
            }
            
            if ["html", "htm", "shtml"].contains(url.pathExtension.lowercased()) {
                DispatchQueue.main.async {
                    App.appendAndFocusNewEditor(editor: PYWebEditorInstance(url), alwaysInNewTab: true)
                }
                return
            }
            
            if ["md", "markdown", "shtml"].contains(url.pathExtension.lowercased()) {
                Task {
                    let contentData: Data? = try await App.workSpaceStorage.contents(
                        at: url
                    )

                    if let contentData, let (content, _) = try? App.decodeStringData(data: contentData) {
                        let editor = MarkdownEditorInstance(url: url , content: content, title: url.lastPathComponent)
                        await App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                App.openFile(url: url, alwaysInNewTab: true)
            }
            return
        }
        
        
        if url.scheme == "file" {
            App.openFile(url: url, alwaysInNewTab: true)
            return
        }
        
        if url.scheme == "jupyter-notebook" {
            JupyterExtension.jupyterManager.openNotebook(URL(string: App.workSpaceStorage.currentDirectory.url))
            return
        }
        
        if url.scheme == "dlhttp" || url.scheme == "dlhttps" {
            let str = url.absoluteString.replacingFirstOccurrence(of: "dlhttp", with: "http")
            let ext = url.pathExtension.lowercased()
            if let url = URL(string: str) {
                if let path = DownloadManager.instance.downloadedFilePath(url) {
                    DispatchQueue.main.async {
                        let pathUrl = URL(fileURLWithPath: path)
                        self.openUrl(pathUrl)
                    }
                } else {
                    let task = DownloadManager.instance.download(url)
                    task?.completion(handler: { task in
                        if task.status == .succeeded {
                            DispatchQueue.main.async {
                                let url = URL(fileURLWithPath: task.filePath)
                                self.openUrl(url)
                            }
                        }
                    })
                    App.notificationManager.showInformationMessage("Downloading %@", url.absoluteString)
                }
            }
            return
        }
        
        
        if url.scheme == "http" || url.scheme == "https" {
            let editor = PYWebEditorInstance(url)
            DispatchQueue.main.async {
                App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
            }
            return
        }
        
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        
        
    }
    
    
    static func onAppInitialized() {
        wmessager.listenForMessage(withIdentifier: ConstantManager.PYDE_OPEN_COMMAND_MSG) { args in
            guard let args = args as? [String], !args.isEmpty else {return}
            if args[1] == "-a" {
                let command = args[2...].joined(separator: " ")
                ios_system(command)
                return
            }
            let path = args.last!
            guard let url = path.contains(":") ? URL(string: path) : URL(fileURLWithPath: path) else {return}
            NotificationCenter.default.post(name: .init("UI_OPEN_FILE_IN_TAB"), object: nil, userInfo: ["url": url])
        }
    }
}
