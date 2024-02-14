//
//  LocalExecutionExtension.swift
//  Code
//
//  Created by Ken Chung on 19/11/2022.
//

import Foundation
import pydeCommon
import SwiftUI
import UIKit
import python3_objc
import ios_system
import QuickLook
import Dynamic

fileprivate var isPythonUIRunning = false

private let EXTENSION_ID = "PYLOCAL_EXECUTION"

private let LOCAL_EXECUTION_COMMANDS = [
    "py": ["python3 -u {url}"],
    "ui.py": ["python3 -u {url}"],
    "ipynb": ["jupyter-nbconvert --execute --allow-errors --stdout --to markdown {url}"],// --allow-errors
//    "js": ["node {url}"],
//    "c": ["clang {url}", "wasm a.out"],
//    "cpp": ["clang++ {url}", "wasm a.out"],
//    "php": ["php {url}"],
]

class PYLocalExecutionExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let toolbarItem = ToolbarItem(
            extenionID: EXTENSION_ID,
            icon: "play",
            onClick: {
                self.runCodeLocally(app: app)
            },
            shortCut: .init("r", modifiers: [.command]),
            panelToFocusOnTap: "RUNNER",
            shouldDisplay: {
                guard let activeTextEditor = app.activeTextEditor else { return false }
                return activeTextEditor.url.isFileURL
                    && LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] != nil
            }
//            popover: {dismiss in
//                return self.runUICode(app: app, dismiss: dismiss)
//            }
        )
        contribution.toolBar.registerItem(item: toolbarItem)
        
        wmessager.listenForMessage(withIdentifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT) { _ in
            isPythonUIRunning = false
        }
        
        wmessager.listenForMessage(withIdentifier: ConstantManager.PYDE_ASK_RUN_IN_UI) { cmds in
            guard var path = (cmds as? [String])?.first(where: {$0.hasPrefix("python3 -u")}) else {
                return
            }
            path = path.replacingOccurrences(of: "python3 -u ", with: "")
            path = path.replacingFirstOccurrence(of: "\"", with: "")
            let url = URL(fileURLWithPath: path)
            guard let editor = app.textEditors.first(where: {$0.url == url}) else {
                return
            }
            guard let rseidtor = editor as? PYTextEditorInstance else{
                return
            }
            DispatchQueue.main.async {
                rseidtor.runnerView.kill()
                DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(500))) {
                    rseidtor.runnerView.feed(text: "\r\n脚本运行需要显示UI\r\n将终止当前脚本\r\n并在UI模式下重新运行\r\n通过以下任一方法可以强制运行在UI模式下: \r\n* 后缀名改为.ui.py\r\n* __ui__ = True\r\n")
                    self.runUICode(app: app, editor: rseidtor, dismiss: {})
                }
            }
//            app.alertManager.showAlert(
//                title: "UI Mode?",
//                content: AnyView(
//                    Group {
//                        Button("common.ok", role: .destructive) {
//                            rseidtor.runnerView.kill()
//                            self.runUICode(app: app, editor: rseidtor, dismiss: {})
//                        }
//                        Button("common.cancel", role: .cancel) {}
//                    }
//                )
//            )
        }
    }
    
    private func getRemoteConfig(editor: WithRunnerEditorInstance, commands: [String], app: MainApp) -> [String: Any]? {
        guard let executor = editor.runnerView.executor else {return nil}
        let ntidentifier = executor.persistentIdentifier
        guard let bookmark = try? executor.currentWorkingDirectory.bookmarkData() else  {return nil}
        guard let wbookmark = try? URL(string: app.workSpaceStorage.currentDirectory.url ?? FileManager.default.currentDirectoryPath)!.bookmarkData() else {return nil}
        guard let libbookmark = try? ConstantManager.libraryURL.bookmarkData() else {return nil}
        let columns = executor.winsize.0
        let lines = executor.winsize.1
        let env = environmentAsArray()
        
        let config: [String: Any] = [
            "workingDirectoryBookmark": bookmark,
            "libraryBookmark": libbookmark,
            "commands": commands,
            "identifier": ntidentifier,
            "workspace": wbookmark,
            "COLUMNS": "\(columns)",
            "LINES": "\(lines)",
            "env": env,
        ]
        return config
    }
    
    private func runUICode(app: MainApp, editor:WithRunnerEditorInstance, dismiss:@escaping () -> Void) -> AnyView? {
//        guard let editor = app.activeTextEditor as? PYTextEditorInstance else {
//            return nil
//        }
        
//        if !editor.url.path.hasSuffix(".ui.py") {
//            return nil
//        }
        
        guard editor.runnerView.executor?.state == .idle else {
            app.notificationManager.showErrorMessage("当前正在运行中，请等待运行结束或者中止")
            return nil
        }
        
        app.saveCurrentFile()
        
        let sanitizedUrl = editor.url.path.replacingOccurrences(of: " ", with: #"\ "#)
        let commands = LOCAL_EXECUTION_COMMANDS["ui.py"]!.map {
            $0.replacingOccurrences(of: "{url}", with: sanitizedUrl)
        }
        
        guard let config = getRemoteConfig(editor: editor, commands: commands, app: app) else {
            return nil
        }
        
        let provider = NSItemProvider(item: "provider" as NSSecureCoding, typeIdentifier: "mh.pydeApp.pydeUI")
        let item = NSExtensionItem()
        item.attributedTitle = NSAttributedString(string: "This is title")
        item.accessibilityLabel = "run pyde ui"
        item.userInfo = config
        item.attachments = [provider]
        
        
        let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
//        let popoverView = AnyView(VCRepresentable(vc))
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                app.popupManager.showSheet(content: AnyView(VCRepresentable(vc).presentationDetents([.fraction(0)])))
            } else {
                app.popupManager.showSheet(content: AnyView(VCRepresentable(vc)))
            }
        } else {
            let popoverView = AnyView(VCRepresentable(vc))
            app.popupManager.showOutside(content: popoverView)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(50))) {
            
            do {
                try ObjC.catchException {
                    let presenter = vc.value(forKey: "_mainPresenter") as? NSObject
                    let interactor = presenter?.value(forKey: "_interactor") as? NSObject
                    let manager = interactor?.value(forKey: "_serviceManager") as? NSObject
                    manager?.perform(Selector("performExtensionActivityInHostWithBundleID:request:"), with: "mh.pydeApp.pydeUI", with: nil)
                    
                }
            } catch {
                print(error)
                app.popupManager.showSheet = false
                app.popupManager.showOutside = false
                
                DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(350))) {
                    let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                    app.popupManager.showSheet(content: AnyView(VCRepresentable(vc)))
                }
            }
        }
        
        let compilerShowPath = UserDefaults.standard.bool(forKey: "compilerShowPath")
        if compilerShowPath {
            editor.runnerView.feed(text: commands.joined(separator: " && "))
        } else {
            let commandName = commands.first?.components(separatedBy: " ").first ?? editor.languageIdentifier
            editor.runnerView.feed(text: commandName)
        }
        editor.runnerView.feed(text: "\r\n")
        editor.runnerView.executor?.evaluateCommands(["readremote"])
        
//        return popoverView
        return nil
    }
    

    private func runCodeLocally(app: MainApp) {
        guard let editor = app.activeTextEditor as? WithRunnerEditorInstance else {
            return
        }
        
        guard editor.runnerView.executor?.state == .idle else {
            app.notificationManager.showErrorMessage("当前正在运行中，请等待运行结束或者中止")
            return
        }
        
        if editor.url.path.hasSuffix(".ui.py") {
            runUICode(app: app, editor: editor, dismiss: {})
            return
        }
        
        if !editor.content.contains("__thread__") && ([
            "__ui__",
            "import sdl2",
            "import kivy",
            "import pygame",
            "import flet",
            "from sdl2 ",
            "from sdl2.",
            "from pygame ",
            "from pygame.",
            "from kivy ",
            "from kivy.",
            "from flet ",
            "from flet."].contains(where: {editor.content.contains($0)})) {
            runUICode(app: app, editor: editor, dismiss: {})
            return
        }

        guard let commands = LOCAL_EXECUTION_COMMANDS[editor.languageIdentifier] else {
            return
        }
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", ".*print +[^(].*")
        let isPy2 = predicate.evaluate(with: editor.content)

        app.saveCurrentFile()

        let sanitizedUrl = editor.url.path.replacingOccurrences(of: " ", with: #"\ "#)
        let parsedCommands = (isPy2 ? commands.map({$0.replacingFirstOccurrence(of: "python3", with: "python2")}) : commands)
        .map {
            $0.replacingOccurrences(of: "{url}", with: sanitizedUrl)
        }

        let compilerShowPath = UserDefaults.standard.bool(forKey: "compilerShowPath")
        if compilerShowPath {
            editor.runnerView.feed(text: parsedCommands.joined(separator: " && "))
        } else {
            let commandName = parsedCommands.first?.components(separatedBy: " ").first ?? editor.languageIdentifier
            editor.runnerView.feed(text: commandName)
        }
        editor.runnerView.feed(text: "\r\n")
        
        if editor.content.contains("__thread__") {
            editor.runnerView.executor?.evaluateCommands(parsedCommands)
        } else {
            editor.runnerView.executor?.dispatchBlock(command: {clientReqCommands(commands: parsedCommands)}, name: parsedCommands.joined(separator: " "))
        }
        
        
        
//        if isPythonUIRunning {
//            await activeTextEditor.runnerView.executor?.evaluateCommands(["echo 请关闭其它解释器！"])
//            return
//        }
        
//        isPythonUIRunning = true
//        
//        
////        let name = activeTextEditor.url.lastPathComponent.replacingFirstOccurrence(of: ".ui.py", with: "")
//////        let dir = ConstantManager.appGroupContainer.appendingPathComponent(uid)
//////        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
////        
////        let dir = URL(string: app.workSpaceStorage.currentDirectory.url)!
////        let linkDir = ConstantManager.appGroupContainer.appendingPathComponent("\(UUID().uuidString).pyui")
////        try? FileManager.default.linkItem(at: dir, to: linkDir)
//////        let fileUrl = sceneUrl.appendingPathComponent("\(name).pyui")
//////        NSKeyedArchiver.archiveRootObject(config, toFile: fileUrl.path)
////        
////        let vc = await PYQLUIPreviewController(linkDir, ntidentifier)
////        NotificationCenter.default.post(name: Notification.Name("UI_SHOW_VC_IN_TAB"), object: nil, userInfo: ["vc": vc])
////        
//////        DispatchQueue.main.async {
//////            if #available(iOS 16.0, *) {
//////                app.popupManager.showCover(
//////                    content: AnyView(VCRepresentable(
//////                        vc
//////                    ))/*.presentationDetents([.height(400)]))*/
//////                )
//////            } else {
//////                // Fallback on earlier versions
//////            }
//////        }
////        executor.evaluateCommands(["readremote"])
////        return
//        
//        
//        
//        
//        
////        DispatchQueue.main.async {
////            let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
////            vc.view.alpha = 0
////            vc.view.isHidden = true
//////            let instance = VCInTabEditorInstance(url: url, title: "ui: window", vc: vc)
//////            app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
////            
//////            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(100))) {
////                let presenter = vc.value(forKey: "_mainPresenter") as? NSObject
////                let interactor = presenter?.value(forKey: "_interactor") as? NSObject
////                let manager = interactor?.value(forKey: "_serviceManager") as? NSObject
////                
////                let myreq = Dynamic("UISUIActivityExtensionItemDataRequest").new() as? NSObject
////                myreq?.setValue(NSUUID(), forKey: "activityUUID")
////                myreq?.setValue("mh.pydeApp.pydeUI", forKey: "activityType")
////                myreq?.setValue(NSClassFromString("UIApplicationExtensionActivity"), forKey: "classForPreparingExtensionItemData")
////                myreq?.setValue(5, forKey: "maxPreviews")
////                print(manager)
////                print(myreq)
////                manager?.perform(Selector("performExtensionActivityInHostWithBundleID:request:"), with: "mh.pydeApp.pydeUI", with: nil)
//////            }
////        }
////        return
//        
//        DispatchQueue.main.async {
//            let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
////            app.popupManager.showSheet(
////                content: AnyView(VCRepresentable(vc))
////            )
//            
////            if UIDevice.current.userInterfaceIdiom == .pad {
//////                let instance = VCInTabEditorInstance(url: url, title: "ui: window", vc: vc)
//////                app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
////                
////                app.popupManager.showPopup(content: AnyView(VCRepresentable(vc)))
////                var observation: Any? = nil
////                observation = NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notificatin in
////                    NotificationCenter.default.removeObserver(observation)
//////                    app.closeEditor(editor: instance)
////                    app.popupManager.showPopup = false
////                }
////                return
////                
////            } else {
////                if #available(iOS 16.0, *) {
////                    app.popupManager.showSheet(
////                        content: AnyView(VCRepresentable(vc).presentationDetents([.fraction(0.5)]))
////                    )
////                } else {
////                    app.popupManager.showSheet(
////                        content: AnyView(VCRepresentable(vc))
////                    )
////                }
////                
////                var observation: Any? = nil
////                observation = NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notificatin in
////                    NotificationCenter.default.removeObserver(observation)
////                    app.popupManager.showSheet = false
////                }
////                return
////            }
//            
//
//            
//            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(100))) {
//                do {
//                    try ObjC.catchException {
//                        let presenter = vc.value(forKey: "_mainPresenter") as? NSObject
//                        let interactor = presenter?.value(forKey: "_interactor") as? NSObject
//                        let manager = interactor?.value(forKey: "_serviceManager") as? NSObject
//                        manager?.perform(Selector("performExtensionActivityInHostWithBundleID:request:"), with: "mh.pydeApp.pydeUI", with: nil)
//                    }
//                } catch {
//                    print(error)
//                    return
//                }
//                
//                
////                let myreq = Dynamic("UISUIActivityExtensionItemDataRequest").new() as? NSObject
////                myreq?.setValue(NSUUID(), forKey: "activityUUID")
////                myreq?.setValue("mh.pydeApp.pydeUI", forKey: "activityType")
////                myreq?.setValue(NSClassFromString("UIApplicationExtensionActivity"), forKey: "classForPreparingExtensionItemData")
//                
//                
//                
//                
//            }
//        }
//        
//        
    }
}

class ConsoleInstance {
    let consoleView: ConsoleView
    
    var executor: pydeCommon.Executor? {
        return consoleView.executor
    }
    
    init(root: URL) {
        self.consoleView = ConsoleView(root: root)
    }
}


struct VCRepresentable: UIViewControllerRepresentable {

    private var vc: UIViewController

    init(_ vc: UIViewController) {
        self.vc = vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return vc
    }
}




class PYQLUIPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    let fileUrl: URL
    let identifier: String
    init(_ fileUrl: URL, _ identifier: String) {
        self.fileUrl = fileUrl
        self.identifier = identifier
        super.init(nibName: nil, bundle: nil)
        
        self.dataSource = self
        self.reloadData()
        
        self.preferredContentSize = CGSize(width: 800, height: 600)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func handleExit() {
        isPythonUIRunning = false
        let id = self.identifier
        wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_FORCE_EXIT)
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(200))) {
            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(id))
            
            try? FileManager.default.removeItem(at: self.fileUrl)
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }

    func previewController(
      _ controller: QLPreviewController,
      previewItemAt index: Int
    ) -> QLPreviewItem {
      return fileUrl as QLPreviewItem
    }
    
    
}
