//
//  NBPreviewExtension.swift
//  pydeApp
//
//  Created by Huima on 2024/2/12.
//

import SwiftUI
import UIKit
import pydeCommon
import pyde






class WithRunnerEditorInstance: TextEditorInstance {
    
    let runner = PYRunnerWidget()
      
    var runnerView: ConsoleView {
        return runner.consoleView
    }
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        editorView: AnyView,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(
            editor: EditorAndRunnerWidget(editor: editorView, runner: runner).id(UUID()),
            url: url,
            content: content,
            encoding: encoding,
            lastSavedDate: lastSavedDate,
            fileDidChange: fileDidChange
        )
        
        runnerView.resetAndSetNewRootDirectory(url: url.deletingLastPathComponent())
    }
    
    override func dispose() {
        super.dispose()
        runnerView.kill()
        runnerView.clear()
        runnerView.removeFromSuperview()
    }
    
    #if DEBUG
    deinit {
        print("withrunnerEditorInstance deinit")
    }
    #endif
}





struct EditorAndRunnerWidget: View {
    
    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @EnvironmentObject var App: MainApp
    @AppStorage("setting.panel.hide.when.editor.focus") var shouldHidePanel: Bool = true
    
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
    
    @State var restoreShowPanel = false
    @State var isEditing = false
    
    let editor: AnyView
    let runner: PYRunnerWidget
    
    let panelManager = PanelManager()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                editor
                PYPanelView(currentPanelId: "RUNNER", windowHeight: geometry.size.height)
                    .environmentObject(panelManager)
            }
        }
//        .onReceive(
//            NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification),
//            perform: { _ in
//                if editor.editorView.textView.isEditing {
//                    editor.editorView.textView.scrollRangeToVisible(editor.editorView.textView.selectedRange)
//                }
//        })
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillShowNotification),
            perform: { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, keyboardFrame.size.height > 150 {
                    restoreShowPanel = false
                    if shouldHidePanel && showsPanel {
                        showsPanel = false
                        restoreShowPanel = true
                    }
                }
            })
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("rseditor.focus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                isEditing = true
            }
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("editor.focus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                isEditing = true
            }
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("rseditor.unfocus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                isEditing = false
                if shouldHidePanel && restoreShowPanel && !showsPanel {
                    showsPanel = true
                }
            }
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("editor.unfocus"),
                object: nil),
            perform: { notification in
                guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                    sceneIdentifier == App.sceneIdentifier
                else { return }
                if shouldHidePanel && restoreShowPanel && !showsPanel {
                    showsPanel = true
                }
            }
        )
        .onAppear {
            if !panelManager.panels.isEmpty {
                return
            }
            let runnerPanel = Panel(
                labelId: "RUNNER",
                mainView: AnyView(
                    runner
                ),
                toolBarView: AnyView(
                    HStack(spacing: 12) {
                    Button(
                        action: {
                            runner.consoleView.kill()
                        },
                        label: {
                            Text("^C")
                        }
                    ).keyboardShortcut("c", modifiers: [.control])

                    Button(
                        action: {
                            runner.consoleView.clear()
                        },
                        label: {
                            Image(systemName: "trash")
                        }
                    ).keyboardShortcut("k", modifiers: [.command])
                        
//                    Button(
//                        action: {
//                            _ = runner.consoleView.terminalView.resignFirstResponder()
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        },
//                        label: {
//                            Image(systemName: "keyboard.chevron.compact.down")
//                        }
//                    )
                })
            )
            panelManager.registerPanel(panel: runnerPanel)
            
            let paramsPanel = Panel(
                labelId: "ARGS",
                mainView: AnyView(
                    ParamsView()
                ),
                toolBarView: AnyView(
                    HStack(spacing: 12) {
                })
            )
            panelManager.registerPanel(panel: paramsPanel)
        }
        .onDisappear() {
            panelManager.panels.removeAll()
        }
    }
}

struct ParamsView: View {
    @EnvironmentObject var App: MainApp
    @ObservedObject var codeThemeManager = rscodeThemeManager
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
    
    @State var lastArgs = ""
    @FocusState private var isFocused: Bool
    
    @State var showPlaceHolder = false
    
    var body: some View {
        TextEditor(text: Binding(get: {
            App.activeTextEditor?.runArgs ?? ""
        }, set: { value in
            App.activeTextEditor?.runArgs = value
            if value.isEmpty {
                showPlaceHolder = true
            } else {
                showPlaceHolder = false
            }
        }))
            .background(Color((colorScheme == .dark ? codeThemeManager.darkTheme : codeThemeManager.lightTheme).backgroundColor)) // To see this
            .focused($isFocused)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .font(.system(size: CGFloat(consoleFontSize)))
            .overlay(alignment: .topLeading, content: {
                Text(showPlaceHolder ? NSLocalizedString("Input run args", comment: "") : "")
                    .font(.system(size: CGFloat(consoleFontSize)))
                    .opacity(0.6)
                    .padding(7)
                    .disabled(true)
                    .allowsHitTesting(false)
            })
            .onAppear {
                if let args = App.activeTextEditor?.runArgs, !args.isEmpty {
                    showPlaceHolder = false
                } else {
                    showPlaceHolder = true
                }
            }
            .onChange(of: isFocused) { isFocused in
                guard let editor = App.activeTextEditor else {return}
                if isFocused {
                    lastArgs = editor.runArgs
                    return
                }
                if lastArgs == editor.runArgs {return}
                
                let fileName = editor.url.lastPathComponent
                let argsName = ".\(fileName).args"
                let argsUrl = editor.url.deletingLastPathComponent().appendingPathComponent(argsName)
                Task {
                    do {
                        guard let argsData = editor.runArgs.data(using: .utf8) else {return}
                        try await App.workSpaceStorage.write(at: argsUrl, content: argsData, atomically: true, overwrite: true)
                    } catch {
                        print(error)
                    }
                    
                }
            }
    }
}


private var nbtemplate: String?

struct NBViewReprestable: UIViewRepresentable {
    
    let webView: WKWebView = WKWebView(frame: .zero)
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}


class NBPreviewEditorInstance: WithRunnerEditorInstance  {
    let webViewRepresent = NBViewReprestable()
    
    init(
        url: URL,
        content: String,
        encoding: String.Encoding = .utf8,
        lastSavedDate: Date? = nil,
        fileDidChange: ((FileState, String?) -> Void)? = nil
    ) {
        super.init(
            url: url,
            content: content,
            encoding: encoding,
            lastSavedDate: lastSavedDate,
            editorView: AnyView(webViewRepresent),
            fileDidChange: fileDidChange
        )
        
        loadNBContent(nbContent: content)
    }

    func loadNBContent(nbContent: String) {
        if nbtemplate == nil {
            nbtemplate = try? String(contentsOf: ConstantManager.NBTEMPLATE_URL)
        }
        let htmlString = nbtemplate?.replacingOccurrences(of: "%nbcontent%", with: nbContent)
        webViewRepresent.webView.loadHTMLString(htmlString ?? "", baseURL: url)
//        webViewRepresent.webView.loadHTMLString("Test", baseURL: url)
    }
}


//class NBViewerExtension: CodeAppExtension {
//
//    private func loadHTML(url: URL, app: MainApp, webView: WKWebView) {
//        if nbtemplate == nil {
//            nbtemplate = try? String(contentsOf: ConstantManager.NBTEMPLATE_URL)
//        }
//        
//        
//        app.workSpaceStorage.contents(at: url) { data, error in
//            guard let data else {
//                return
//            }
//            let nbContent = String(data: data, encoding: .utf8) ?? ""
//            let htmlString = nbtemplate?.replacingOccurrences(of: "%notebook-json%", with: nbContent)
//            webView.loadHTMLString(htmlString ?? "", baseURL: nil)
//        }
//    }
//
//    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
//        
//        
//
//        let provider = EditorProvider(
//            registeredFileExtensions: ["ipynb"],
//            onCreateEditor: { [weak self] url in
//                
//                
//
//                let editorInstance = NBPreviewEditorInstance(url: url, content: "")
//
//                self?.loadHTML(url: url, app: app, webView: editorInstance.webViewRepresent.webView)
////                editorInstance.fileWatch?.folderDidChange = { _ in
////                    self?.loadHTML(url: url, app: app, webView: editorInstance.webViewRepresent.webView)
////                }
////                editorInstance.fileWatch?.startMonitoring()
//
//                return editorInstance
//            }
//        )
//        contribution.editorProvider.register(provider: provider)
//    }
//}
