import MarkdownView
import SwiftUI

// TODO: Localization

private struct VCInTab: UIViewControllerRepresentable {
    
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
        super.init(view: AnyView(VCInTab(vc: vc).id(UUID())), title: title, url: url)
    }
}

class VCInTabExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
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
            
            let instance = VCInTabEditorInstance(url: app.workSpaceStorage.currentDirectory._url!, title: "window", vc: vc)
            DispatchQueue.main.async {
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
    }
    
//    deinit {
////        NotificationCenter.default.removeObserver(self, name: .init(""), object: nil)
//    }

}

