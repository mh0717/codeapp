
import SwiftUI
import SafariServices
import ios_system
import pydeCommon

private let EXTENSION_ID = "VCInTabExtension"

struct VCInTab: UIViewControllerRepresentable {
    
    @EnvironmentObject var App: MainApp
    
    weak var vc: UIViewController?
    
    func makeUIViewController(context: Context) -> UIViewController {
        return vc ?? UIViewController(nibName: nil, bundle: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(control: self, app: App)
    }
    
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if !coordinator.App.editors.contains(where: {ins in
            if let tabIns = ins as? VCInTabEditorInstance, tabIns.vc == uiViewController {
                return true
            }
            return false
        }) {
            uiViewController.view.isUserInteractionEnabled = false
            if uiViewController.responds(to: Selector(("handleExit"))) {
                uiViewController.performSelector(onMainThread: Selector(("handleExit")), with: nil, waitUntilDone: false)
            }
        }
    }
    
    class Coordinator {
        
        
        var control: VCInTab
        var App: MainApp
        
        init(control: VCInTab, app: MainApp) {
            self.control = control
            self.App = app
        }
    }
}

class VCInTabEditorInstance: EditorInstanceWithURL {

    let vc: UIViewController

    init(url: URL, title: String, vc: UIViewController) {
        self.vc = vc
        let stitle = (vc.title != nil && !vc.title!.isEmpty) ? vc.title! : title
        super.init(view: AnyView(VCInTab(vc: vc).id(UUID())), title: stitle, url: url)
        
        _ = self.vc.observe(\UIViewController.title) { [weak self] vc, _ in
            if let self {
                self.title = (vc.title != nil && !vc.title!.isEmpty) ? vc.title! : title
            }
        }
    }
}

class VCInTabExtension: CodeAppExtension {
    
    static var _showCount = 0
    

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
//        let toolbarItem = ToolbarItem(
//            extenionID: EXTENSION_ID,
//            icon: "xmark",
//            onClick: {
//                Task {
//                    if let editor = app.activeEditor {
//                        await app.closeEditor(editor: editor)
//                    }
//                }
//            },
//            shortCut: .init("w", modifiers: [.command]),
//            panelToFocusOnTap: nil,
//            shouldDisplay: {
//                return true
////                guard let editor = app.activeEditor else { return false }
////                
////                if editor is VCInTabEditorInstance ||
////                    editor is CVInTabEditorInstance {
////                    return true
////                }
////                return false
//            }
//        )
//        contribution.toolBar.registerItem(item: toolbarItem)
        
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
        
        NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
            let keepAlive = notify.userInfo?["keepAlive"] as? Bool ?? false
            if let editor = app.editors.first(where: { ins in
                if let tabIns = ins as? VCInTabEditorInstance, tabIns.vc == vc {
                    return true
                }
                return false
            }) {
                DispatchQueue.main.async {
                    app.setActiveEditor(editor: editor)
                }
                return
            }
            VCInTabExtension._showCount += 1
            let url = URL(string: "showvc://vc\(VCInTabExtension._showCount)")!
            let instance = VCInTabEditorInstance(url: url, title: "#win\(VCInTabExtension._showCount)", vc: vc)
            instance.keepAlive = keepAlive
            DispatchQueue.main.async {
                app.popupManager.showSheet = false
                app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .init("UI_HIDE_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
            if let editor = app.editors.first(where: { ins in
                if let tabIns = ins as? VCInTabEditorInstance, tabIns.vc == vc {
                    return true
                }
                return false
            }) {
                DispatchQueue.main.async {
                    app.closeEditor(editor: editor, force: true)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: .init("UI_OPEN_FILE_IN_TAB"), object: nil, queue: nil) { notify in
            guard let url = notify.userInfo?["url"] as? URL else { return }
            
            if url.scheme == "http" || url.scheme == "https" {
                VCInTabExtension._showCount += 1
                let title = url.lastPathComponent.isEmpty ? "#web\(VCInTabExtension._showCount)" : url.lastPathComponent
                DispatchQueue.main.async {
                    let vc = SFSafariViewController(url: url)
                    let instance = VCInTabEditorInstance(url: url, title: title, vc: vc)
                    app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
                }
                return
            }
            
            if url.path.contains("Jupyter/runtime/nbserver") {
                VCInTabExtension._showCount += 1
                let title = url.lastPathComponent.isEmpty ? "#web\(VCInTabExtension._showCount)" : url.lastPathComponent
                DispatchQueue.main.async {
                    let vc = SFSafariViewController(url: URL(string: "http://localhost:8888/")!)
                    let instance = VCInTabEditorInstance(url: url, title: title, vc: vc)
                    app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
                }
                return
            }
            
            if FileManager.default.fileExists(atPath: url.path) {
                DispatchQueue.main.async {
                    app.openFile(url: url, alwaysInNewTab: true)
                }
                return
            }
        }
        
        
        
        NotificationCenter.default.addObserver(forName: .init("PYDE_UI_SHOW_IMAGE"), object: nil, queue: nil) { notify in
//            print(notify)
//            print(notify.userInfo as Any)
            
            VCInTabExtension._showCount += 1
            guard let image = notify.userInfo?["image"] as? UIImage else {return}
            var title = notify.userInfo?["title"] as? String
            if title == nil || title!.isEmpty {
                title = "#image\(VCInTabExtension._showCount)"
            }
            let iscv = notify.userInfo?["iscv"] as? Bool ?? false
            if iscv {
                var pid: UInt64 = 0
                pthread_threadid_np(nil, &pid);
                if _iscvClosing && _cvThreadId == pid && !Thread.isMainThread {
                    pthread_exit(nil)
                    return
                }
                
                _cvThreadId = pid
                _iscvClosing = false
                DispatchQueue.main.async {
//                    let isClosing = getenv("PYDE_UI_CV_CLOSING")
//                    if isClosing != nil && String(utf8String: isClosing!) == "1" {
//                        return
//                    }
                    if _iscvClosing {return}
                    self.cvEditor.vc.title = title
                    self.cvEditor.vc.view.layer.contents = image.cgImage
                    if !app.editors.contains(self.cvEditor) {
                        app.appendAndFocusNewEditor(editor: self.cvEditor, alwaysInNewTab: true)
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                let vc = UIViewController.init(nibName: nil, bundle: nil)
                vc.view.contentMode = .center
                vc.view.layer.contents = image.cgImage
                vc.title = title
                let url = URL(string: "showvc://vc\(VCInTabExtension._showCount)")!
                let instance = VCInTabEditorInstance(url: url, title: title!, vc: vc)
                app.appendAndFocusNewEditor(editor: instance, alwaysInNewTab: true)
            }
        }
    }
    
//    deinit {
////        NotificationCenter.default.removeObserver(self, name: .init(""), object: nil)
//    }
    
    
    lazy var cvEditor: CVInTabEditorInstance = {
        let vc = UIViewController(nibName: nil, bundle: nil)
        vc.view.contentMode = .center
        let url = URL(string: "showvc://cvvc")!
        let instance = CVInTabEditorInstance(url: url, title: "OpenCV", vc: vc)
        return instance
    }()

}

fileprivate var _iscvClosing = false
fileprivate var _cvThreadId: UInt64 = 0


private struct CVInTab: UIViewControllerRepresentable {
    
    @EnvironmentObject var App: MainApp
    
    weak var vc: UIViewController?
    
    func makeUIViewController(context: Context) -> UIViewController {
        return vc ?? UIViewController(nibName: nil, bundle: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(control: self, app: App)
    }
    
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if !coordinator.App.editors.contains(where: {ins in
            if let tabIns = ins as? CVInTabEditorInstance, tabIns.vc == uiViewController {
                return true
            }
            return false
        }) {
            setenv("PYDE_UI_CV_CLOSING", "1", 1)
//            print(getenv("PYDE_UI_CV_CLOSING"))
            _iscvClosing = true
            
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(500))) {
                setenv("PYDE_UI_CV_CLOSING", "0", 1)
            }
        }
    }
    
    class Coordinator {
        
        
        var control: CVInTab
        var App: MainApp
        
        init(control: CVInTab, app: MainApp) {
            self.control = control
            self.App = app
        }
    }
}

class CVInTabEditorInstance: EditorInstanceWithURL {

    let vc: UIViewController

    init(url: URL, title: String, vc: UIViewController) {
        self.vc = vc
        super.init(view: AnyView(CVInTab(vc: vc).id(UUID())), title: title, url: url)
    }
}





