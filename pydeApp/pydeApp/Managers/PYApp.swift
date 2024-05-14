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
import Combine
import ZipArchive
import pyde

class PYApp: ObservableObject {
    
    weak var App: MainApp?
    
    @Published var leftSideShow = false
    @Published var rightSideShow = false
    
    
    @Published var showAddressbar = false
    @Published var addressUrl = ""
    
    @Published var showCloneAlert = false
    @Published var showingNewDjangoAlert = false
    @Published var showFilePicker = false
    @Published var showMediaPicker = false
//    @Published private var showingNewSafariAlert = false
    
    let docStorage = WorkSpaceStorage(url: ConstantManager.EXAMPLES)
    
    let jupyterManager = JupyterExtension.jupyterManager
    let downloadManager = DownloadManager.instance
    let pipManager = pipModelManager
    @Published var tagsModelManager = TagsModelManager()
    
    var consoleInstance: ConsoleView {
        activeConsole.consoleView
    }
    let defaultConsole = PYRunnerWidget()
    @Published var activeConsole: PYRunnerWidget
    @Published var consoles: [PYRunnerWidget] = []
    
    private var jupyterCancellable: AnyCancellable? = nil
    
    init() {
        activeConsole = defaultConsole
        
        NotificationCenter.default.addObserver(forName: .init("UI_OPEN_FILE_IN_TAB"), object: nil, queue: nil) { [weak self] notify in
            guard let url = notify.userInfo?["url"] as? URL else { return }
            
            self?.openUrl(url)
        }
        
        jupyterCancellable = jupyterManager.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        
        downloadManager.onTaskCompletion = {[weak self] in
            self?.App?.notificationManager.showSucessMessage("Download task completed")
        }
    }
    
    func onClone(urlString: String) async throws {
        guard let App else {return}
        guard let serviceProvider = App.workSpaceStorage.gitServiceProvider else {
            throw SourceControlError.gitServiceProviderUnavailable
        }
        guard let gitURL = URL(string: urlString) else {
            App.notificationManager.showErrorMessage("errors.source_control.invalid_url")
            throw SourceControlError.invalidURL
        }

        let repo = gitURL.deletingPathExtension().lastPathComponent
        guard
            let dirURL = URL(
                string: App.workSpaceStorage.currentDirectory.url)?
                .appendingPathComponent(repo, isDirectory: true)
        else {
            throw SourceControlError.gitServiceProviderUnavailable
        }

        try FileManager.default.createDirectory(
            atPath: dirURL.path, withIntermediateDirectories: true,
            attributes: nil)

        let progress = Progress(totalUnitCount: 100)
        App.notificationManager.postProgressNotification(
            title: "source_control.cloning_into",
            progress: progress,
            gitURL.absoluteString)

        do {
            try await serviceProvider.clone(from: gitURL, to: dirURL, progress: progress)
            App.notificationManager.postActionNotification(
                title: "source_control.clone_succeeded", level: .success,
                primary: {
                    App.loadFolder(url: dirURL)
                }, primaryTitle: "common.open_folder", source: repo)
        } catch {
            let error = error as NSError
            if error.code == LibGit2ErrorClass._GIT_ERROR_HTTP {
                App.notificationManager.postActionNotification(
                    title:
                        "errors.source_control.clone_authentication_failed",
                    level: .error,
                    primary: {
                        DispatchQueue.main.async {
                            App.popupManager.showSheet(content: AnyView(NavigationView {
                                SourceControlAuthenticationConfiguration()
                            }))
                        }
                    }, primaryTitle: "common.configure",
                    source: "source_control.title")
            } else {
                App.notificationManager.showErrorMessage(
                    "source_control.error", error.localizedDescription)
            }
            throw error
        }
    }
    
    
    func openUrl(_ url: URL) {
        guard let App else {return}
        let url = url.standardizedFileURL
        
        if let editor = App.editors.first(where: {($0 as? EditorInstanceWithURL)?.url == url}) {
            App.activeEditor = editor
            return
        }
        
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
                    App.appendAndFocusNewEditor(editor: PYWebViewEditorInstance(url), alwaysInNewTab: true)
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
        
        if url.scheme == "clhttp" || url.scheme == "clhttps" || url.scheme == "clssh" {
            
        }
        
        
        if url.scheme == "http" || url.scheme == "https" {
            let editor = PYWebViewEditorInstance(url)
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
        let fileManager = FileManager.default
        
        
        if !fileManager.fileExists(atPath: ConstantManager.SYSROOT.path) {
            Thread.detachNewThread {
                SSZipArchive.unzipFile(atPath: ConstantManager.CUSRZIP.path, toDestination: ConstantManager.SYSROOT.path + "/../")
            }
        }
        
        
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
