//
//  main.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import CoreSpotlight
import SwiftUI
import UIKit
import ios_system

struct MainScene: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var App = MainApp()

    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    @SceneStorage("root.bookmark") var rootDirectoryBookmark: Data?
    @SceneStorage("openEditors.bookmarks") var openEditorsBookmarksData: Data?
    @SceneStorage("activeEditor.bookmark") var activeEditorBookmark: Data?
    @SceneStorage("activeEditor.monaco.state") var activeEditorMonacoState: String?

    func getOpenEditorsBookmarks() -> [Data] {
        guard let openEditorsBookmarksData else { return [] }
        return (try? PropertyListDecoder().decode([Data].self, from: openEditorsBookmarksData))
            ?? []
    }

    func setOpenEditorsBookmarks(_ v: [Data]) {
        openEditorsBookmarksData = try? PropertyListEncoder().encode(v)
    }

    func saveSceneState() {
        guard stateRestorationEnabled else { return }
        guard let rootDir = App.workSpaceStorage.currentDirectory._url,
            rootDir.isFileURL,
            let rootDirBookmarkData = try? rootDir.bookmarkData()
        else {
            return
        }
        rootDirectoryBookmark = rootDirBookmarkData
        setOpenEditorsBookmarks(App.editorsWithURL.compactMap { try? $0.url.bookmarkData() })

        if let activeEditor = App.activeTextEditor,
            let activeEditorBookmarkData = try? activeEditor.url.bookmarkData()
        {
            activeEditorBookmark = activeEditorBookmarkData
            App.monacoInstance.monacoWebView.evaluateJavaScript(
                "JSON.stringify(editor.saveViewState())"
            ) {
                res, err in
                if let res = res as? String {
                    activeEditorMonacoState = res
                }
            }
        } else {
            activeEditorBookmark = nil
            activeEditorMonacoState = nil
        }
    }

    func restoreSceneState() {

        var isStale = false

        guard stateRestorationEnabled else { return }
        guard let rootDirBookmark = rootDirectoryBookmark,
            let rootDir = try? URL(
                resolvingBookmarkData: rootDirBookmark, bookmarkDataIsStale: &isStale)
        else {
            return
        }
        App.loadFolder(url: rootDir)

        let editors = getOpenEditorsBookmarks().compactMap {
            try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale: &isStale)
        }
        for editor in editors {
            App.openFile(url: editor, alwaysInNewTab: true)
        }

        if let activeEditorBookmark = activeEditorBookmark,
            let activeEditor = try? URL(
                resolvingBookmarkData: activeEditorBookmark, bookmarkDataIsStale: &isStale)
        {
            App.openFile(url: activeEditor)
        }

    }

    var body: some View {
        MainView()
            .environmentObject(App)
            .environmentObject(App.extensionManager)
            .environmentObject(App.stateManager)
            .environmentObject(App.alertManager)
            .environmentObject(App.safariManager)
            #if PYDEAPP
            .environmentObject(App.popupManager)
            #endif
            .onAppear {
                restoreSceneState()
                App.extensionManager.initializeExtensions(app: App)
            }
            .onOpenURL { url in
                _ = url.startAccessingSecurityScopedResource()
                App.openFile(url: url)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willResignActiveNotification)
            ) { _ in
                saveSceneState()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("theme.updated"),
                    object: nil
                ),
                perform: { notification in
                    guard var theme = themeManager.currentTheme else {
                        if let isDark = notification.userInfo?["isDark"] as? Bool {
                            App.monacoInstance.executeJavascript(command: "resetTheme(\(isDark))")
                            App.terminalInstance.executeScript("applyTheme(null, \(isDark))")
                        }
                        return
                    }
                    App.monacoInstance.setTheme(
                        themeName: theme.name.replacingOccurrences(of: " ", with: ""),
                        data: theme.jsonString,
                        isDark: theme.isDark)
                    App.terminalInstance.applyTheme(rawTheme: theme.dictionary)
                }
            )
            .hiddenSystemOverlays()
    }
}

enum SideBarSection: Int {
    case explorer
    case search
    case sourceControl
    case remote
}

private struct MainView: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var extensionManager: ExtensionManager
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var alertManager: AlertManager
    @EnvironmentObject var safariManager: SafariManager
    @EnvironmentObject var themeManager: ThemeManager
    
    #if PYDEAPP
    @EnvironmentObject var popupManager: PopupManager
    #endif

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @AppStorage("editorFontSize") var editorTextSize: Int = 14
    @AppStorage("editorReadOnly") var editorReadOnly = false
    @AppStorage("compilerShowPath") var compilerShowPath = false
    @AppStorage("changelog.lastread") var changeLogLastReadVersion = "0.0"

    @SceneStorage("sidebar.visible") var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @SceneStorage("panel.visible") var isPanelVisible: Bool = DefaultUIState.PANEL_IS_VISIBLE

    func openConsolePanel() {
        if panelHeight < 70 {
            panelHeight = 200
        }
        isPanelVisible.toggle()
        App.terminalInstance.webView?.becomeFirstResponder()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        if horizontalSizeClass == .regular {
                            #if PYDEAPP
                            if isSideBarVisible {
                                VStack(spacing: 0) {
                                
                                    PYActivityBar(togglePanel: openConsolePanel)
                                        .environmentObject(extensionManager.activityBarManager)
                                    
                                    RegularSidebar(windowWidth: geometry.size.width)
                                        .environmentObject(extensionManager.activityBarManager)
                                }.fixedSize(horizontal: true, vertical: false)
                            }
                            #else
                            ActivityBar(togglePanel: openConsolePanel)
                                .environmentObject(extensionManager.activityBarManager)
                            
                            if isSideBarVisible {
                                RegularSidebar(windowWidth: geometry.size.width)
                                    .environmentObject(extensionManager.activityBarManager)
                            }
                            #endif
                        }
                        

                        ZStack {
                            VStack(spacing: 0) {
                                TopBar(openConsolePanel: openConsolePanel)
                                    .environmentObject(extensionManager.toolbarManager)
                                    .frame(height: 40)
                                
                                GeometryReader {geometry -> AnyView in
                                    setenv("SDL_SCREEN_SIZE", "\(Int(geometry.size.width)):\(Int(geometry.size.height))", 1)
                                    return AnyView(EditorView()
                                        .disabled(horizontalSizeClass == .compact && isSideBarVisible)
                                        .sheet(isPresented: $stateManager.showsNewFileSheet) {
                                            NewFileView(
                                                targetUrl: App.workSpaceStorage.currentDirectory.url
                                            ).environmentObject(App)
                                        }
                                        .environmentObject(extensionManager.editorProviderManager))
                                }
                                
                                
                                
                                #if PYDEAPP
                                #else
                                if isPanelVisible {
                                    PanelView(
                                        windowHeight: geometry.size.height
                                    )
                                    .environmentObject(extensionManager.panelManager)
                                }
                                #endif
                            }
                            .blur(
                                radius: (horizontalSizeClass == .compact && isSideBarVisible)
                                    ? 10 : 0)

                            if isSideBarVisible && horizontalSizeClass == .compact {
                                #if PYDEAPP
                                PYCompactSidebar()
                                    .environmentObject(extensionManager.activityBarManager)
                                #else
                                CompactSidebar()
                                    .environmentObject(extensionManager.activityBarManager)
                                #endif
                            }
                        }
                    }
                    StatusBar()
                        .environmentObject(extensionManager.statusBarManager)
                        .frame(width: geometry.size.width, height: 20)
                }

                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        NotificationCentreView().padding(
                            .trailing, (self.horizontalSizeClass == .compact ? 40 : 10))
                    }
                }.padding(.bottom, 30).frame(width: geometry.size.width)

            }
        }
        .background(Color.init(id: "sideBar.background").edgesIgnoringSafeArea(.all))
        .accentColor(Color.init(id: "activityBar.inactiveForeground"))
        .navigationTitle(
            URL(string: App.workSpaceStorage.currentDirectory.url)?.lastPathComponent ?? ""
        )
        .onChange(of: colorScheme) { newValue in
            App.updateView()
        }
        .hiddenScrollableContentBackground()
        .onAppear {
            let appVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"

            if changeLogLastReadVersion != appVersion {
                stateManager.showsChangeLog.toggle()
            }

            changeLogLastReadVersion = appVersion
        }

        .alert(
            alertManager.title, isPresented: $alertManager.isShowingAlert,
            actions: {
                alertManager.alertContent
            },
            message: {
                if let message = alertManager.message {
                    Text(message)
                } else {
                    EmptyView()
                }
            }
        )
        .fullScreenCover(isPresented: $safariManager.showsSafari) {
            if let url = safariManager.urlToVisit {
                SafariView(url: url)
            } else {
                EmptyView()
            }
        }
        #if PYDEAPP
        .fullScreenCover(isPresented: $popupManager.showCover) {
            popupManager.coverContent
        }
        .sheet(isPresented: $popupManager.showSheet, onDismiss: {
        }) {
            if #available(iOS 16.0, *) {
                popupManager.sheetContent.presentationDetents([.medium])
            } else {
                // Fallback on earlier versions
            }
        }
        #endif
    }
}
