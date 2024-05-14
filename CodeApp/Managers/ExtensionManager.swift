//
//  ExtensionManager.swift
//  Code
//
//  Created by Ken Chung on 14/11/2022.
//

import Foundation

class ExtensionManager: ObservableObject {
    @Published var panelManager = PanelManager()
    @Published var toolbarManager = ToolbarManager()
    @Published var editorProviderManager = EditorProviderManager()
    @Published var statusBarManager = StatusBarManager()
    @Published var activityBarManager = ActivityBarManager()
    var fileMenuManager = FileMenuManager()
    
    #if PYDEAPP
    private var extensions: [CodeAppExtension] = [
        MonacoEditorAuxiliaryExtension(),
//        MonacoIntellisenseExtension(),
//        RemoteExecutionExtension(),
//        TerminalExtension(),
        ImageViewerExtension(),
        VideoViewerExtension(),
        PDFViewerExtension(),
        MarkdownViewerExtension(),
        SourceControlAuxiliaryExtension(),
//        SimpleWebPreviewExtension(),
//        RemoteAuxiliaryExtension(),
        
        VCInTabExtension(),
        MonacoCompletionExtension(),
        PYLocalExecutionExtension(),
        
        JupyterExtension(),
        PYRunnerExtension(),
//        TMConsoleExtension(),
        IAPExtension(),
        QuickLookExtension(),
        SWCompViewerExtension(),
        EpubExtension(),
        WebExtension(),
        WheelExtensionManager(),
        RunParamsExtension(),
    ]
    #else
    private var extensions: [CodeAppExtension] = [
        MonacoEditorAuxiliaryExtension(),
        MonacoIntellisenseExtension(),
        RemoteExecutionExtension(),
        LocalExecutionExtension(),
        TerminalExtension(),
        ImageViewerExtension(),
        VideoViewerExtension(),
        PDFViewerExtension(),
        MarkdownViewerExtension(),
        SourceControlAuxiliaryExtension(),
        SimpleWebPreviewExtension(),
        RemoteAuxiliaryExtension(),
    ]
    #endif
    

    func registerExtension(ex: CodeAppExtension) {
        extensions.append(ex)
    }

    func initializeExtensions(app: MainApp) {
        let contribution = CodeAppExtension.Contribution(
            panel: self.panelManager,
            toolbarItem: self.toolbarManager,
            editorProvider: self.editorProviderManager,
            statusBarManager: self.statusBarManager,
            activityBarManager: self.activityBarManager
        )

        extensions.forEach { ex in
            ex.onInitialize(
                app: app,
                contribution: contribution
            )
        }
    }

    func onWorkSpaceStorageChanged(newUrl: URL) {
        extensions.forEach { ex in
            ex.onWorkSpaceStorageChanged(newUrl: newUrl)
        }
    }
}
