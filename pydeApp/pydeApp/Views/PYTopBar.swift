//
//  PYTopBar.swift
//  iPyDE
//
//  Created by Huima on 2024/4/2.
//

import SwiftUI
import pydeCommon
import ios_system

struct PYTopBar: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var toolBarManager: ToolbarManager
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @SceneStorage("sidebar.visible") var isSideBarExpanded: Bool = DefaultUIState.SIDEBAR_VISIBLE
    @SceneStorage("panel.visible") var isPanelVisible: Bool = DefaultUIState.PANEL_IS_VISIBLE

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let openConsolePanel: () -> Void
    
    @State private var showingNewDjangoAlert = false
    @State private var djangoName = ""
    
    func onNewDjango() {
        let newCommand = "django-admin startproject \(djangoName)"
        App.notificationManager.showAsyncNotification(title: "\(newCommand) ...", task: {
            ios_switchSession(newCommand)
            ios_setContext(newCommand)
            
            var pid = ios_fork()
            
            let returnCode = ios_system("remote \(newCommand)")
            ios_waitpid(pid)
            ios_releaseThreadId(pid)
            
            pid = ios_fork()
            ios_system("echo runserver --noreload > \(djangoName)/.manage.py.args")
            ios_waitpid(pid)
            ios_releaseThreadId(pid)
            
            pid = ios_fork()
            ios_system("echo open manage.py and run > \(djangoName)/README.txt")
            ios_waitpid(pid)
            ios_releaseThreadId(pid)
        })
    }

    var body: some View {
        HStack(spacing: 0) {
            #if PYDEAPP
            if !isSideBarExpanded {
                Button(action: {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isSideBarExpanded.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 17))
                        .foregroundColor(Color.init("T1"))
                        .padding(5)
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .hoverEffect(.highlight)
                        .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                        .padding()
                }
            }
            #else
            if !isSideBarExpanded && horizontalSizeClass == .compact {
                Button(action: {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isSideBarExpanded.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 17))
                        .foregroundColor(Color.init("T1"))
                        .padding(5)
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .hoverEffect(.highlight)
                        .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                        .padding()
                }
            }
            #endif
            
            if horizontalSizeClass == .compact {
                CompactEditorTabs()
                    .frame(maxWidth: .infinity)
                
            } else {
                if #available(iOS 16.0, *) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            EditorTabs()
                            Spacer()
                        }
                        HStack {
                            CompactEditorTabs()
                                .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        EditorTabs()
                    }
                    Spacer()
                }
            }

            ForEach(toolBarManager.items) { item in
                if item.shouldDisplay() {
                    ToolbarItemView(item: item)
                }
            }
            
            #if PYDEAPP
//            if App.activeTextEditor != nil {
//                if let editor = App.activeEditor as? PYTextEditorInstance {
//                    if #available(iOS 16, *) {
//                        Image(systemName: "doc.text.magnifyingglass").font(.system(size: 17))
//                            .foregroundColor(Color.init("T1")).padding(5)
//                            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//                            .hoverEffect(.highlight)
//                            .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
//                            .onTapGesture {
//                                editor.editorView.findInteraction?.presentFindNavigator(showingReplace: true)
//                            }
//                    }
//                } else {
//                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 17))
//                        .foregroundColor(Color.init("T1")).padding(5)
//                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//                        .hoverEffect(.highlight)
//                        .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
//                        .onTapGesture {
//                            App.monacoInstance.executeJavascript(command: "editor.focus()")
//                            App.monacoInstance.executeJavascript(
//                                command: "editor.getAction('actions.find').run()")
//                        }
//                }
//
//            }
            
            if App.activeTextEditor is DiffTextEditorInstnace {
                Image(systemName: "doc.text").font(.system(size: 17))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                    .onTapGesture {
                        App.monacoInstance.applyOptions(options: "renderSideBySide: false")
                    }
            }
            
            if App.editors.count > 0 {
                Image(systemName: "xmark").font(.system(size: 17))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                    .onTapGesture {
                        if let editor = App.activeEditor {
                            App.closeEditor(editor: editor)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            App.closeAllEditors()
                        } label: {
                            Label("Close All", systemImage: "xmark")
                        }
                        Button(role: .destructive) {
                            App.loadFolder(url: getRootDirectory())
                            DispatchQueue.main.async {
                                App.showWelcomeMessage()
                            }
                        } label: {
                            Label("Close Workspace", systemImage: "xmark")
                        }
                    }
            }
            
//            if App.editors.count == 0 {
//                Menu {
//                    Button(role: .destructive) {
//                        App.closeAllEditors()
//                    } label: {
//                        Label("Close All", systemImage: "xmark")
//                    }
//                    Button(role: .destructive) {
//                        App.loadFolder(url: getRootDirectory())
//                        DispatchQueue.main.async {
//                            App.showWelcomeMessage()
//                        }
//                    } label: {
//                        Label("Close Workspace", systemImage: "xmark")
//                    }
//                } label: {
//                    Image(systemName: "xmark").font(.system(size: 17))
//                        .foregroundColor(Color.init("T1")).padding(5)
//                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//                        .hoverEffect(.highlight)
//                        .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
//                }
//
//            }
            
            Menu {
                if App.activeTextEditor is DiffTextEditorInstnace {
                    Section {
                        Button(action: {
                            App.monacoInstance.applyOptions(options: "renderSideBySide: false")
                        }) {
                            Label(
                                NSLocalizedString("Toogle Inline View", comment: ""),
                                systemImage: "doc.text")
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        App.closeAllEditors()
                    } label: {
                        Label("Close All", systemImage: "xmark")
                    }
                    Button(role: .destructive) {
                        App.loadFolder(url: getRootDirectory())
                        DispatchQueue.main.async {
                            App.showWelcomeMessage()
                        }
                    } label: {
                        Label("Close Workspace", systemImage: "xmark")
                    }
                }
                Divider()
                Section {
                    Button(action: {
                        App.showWelcomeMessage()
                    }) {
                        Label("Show Welcome Page", systemImage: "newspaper")
                    }
                    
                    Button(action: {
                        App.loadFolder(url: ConstantManager.EXAMPLES)
                    }) {
                        Label("Open Examples", systemImage: "folder")
                    }
                    
                    Button {
                        App.popupManager.showSheet(content: AnyView(PyRuntimesView()))
                    } label: {
                        Label("Python3 Interpreters Manage", systemImage: "server.rack")
                    }


//                    Button(action: {
//                        openConsolePanel()
//                    }) {
//                        Label(
//                            isPanelVisible ? "Hide Panel" : "Show Panel",
//                            systemImage: "chevron.left.slash.chevron.right")
//                    }.keyboardShortcut("j", modifiers: .command)

                    if UIApplication.shared.supportsMultipleScenes {
                        Button(action: {
                            UIApplication.shared.requestSceneSessionActivation(
                                nil, userActivity: nil, options: nil, errorHandler: nil)
                        }) {
                            Label("actions.new_window", systemImage: "square.split.2x1")
                        }
                    }
                    Divider()
                    Button {
                        App.stateManager.showsNewFileSheet.toggle()
                    } label: {
                        Label("New File", systemImage: "doc.badge.plus")
                    }
                    
                    Button {
                        Task {
                            guard let url = URL(string: App.workSpaceStorage.currentDirectory.url) else { return }
                            try await App.createFolder(at: url)
                        }
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    
                    Button {
                        djangoName = ""
                        showingNewDjangoAlert.toggle()
                    } label: {
                        Label("New Django Project", systemImage: "folder.badge.gear")
                    }
                    
                    Button {
                        let editor = PYTerminalEditorInstance(URL(string: App.workSpaceStorage.currentDirectory.url)!)
                        App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                    } label: {
                        Label("New Terminal", systemImage: "apple.terminal")
                    }
                    
                    Divider()

                    Button(action: {
                        stateManager.showsSettingsSheet.toggle()
                    }) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
                #if DEBUG
                    DebugMenu()
                
                Button(action: {
                    App.loadFolder(url: ConstantManager.appGroupContainer)
                }) {
                    Label("Open GropuContainer", systemImage: "folder")
                }
                
                Button(action: {
                    App.loadFolder(url: ConstantManager.appdir)
                }) {
                    Label("Open Bundle", systemImage: "folder")
                }
                #endif

            } label: {
                Image(systemName: "ellipsis").font(.system(size: 17, weight: .light))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .padding()
            }
            .sheet(isPresented: $stateManager.showsSettingsSheet) {
                if #available(iOS 16.4, *) {
                    PYSettingsView()
                        .presentationBackground {
                            Color(id: "sideBar.background")
                        }

                        .scrollContentBackground(.hidden)
                        .environmentObject(themeManager)
                } else {
                    PYSettingsView()
                        .environmentObject(App)
                }
            }
            .alert("", isPresented: $showingNewDjangoAlert){
                TextField("Enter django project name", text: $djangoName)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                Button("common.create", action: onNewDjango)
                Button("common.cancel") {
                    showingNewDjangoAlert.toggle()
                }
            }
            #else
            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 17))
                .foregroundColor(Color.init("T1")).padding(5)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .hoverEffect(.highlight)
                .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                .onTapGesture {
                    App.monacoInstance.executeJavascript(command: "editor.focus()")
                    App.monacoInstance.executeJavascript(
                        command: "editor.getAction('actions.find').run()")
                }

            Menu {
                if App.activeTextEditor is DiffTextEditorInstnace {
                    Section {
                        Button(action: {
                            App.monacoInstance.applyOptions(options: "renderSideBySide: false")
                        }) {
                            Label(
                                NSLocalizedString("Toogle Inline View", comment: ""),
                                systemImage: "doc.text")
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        App.closeAllEditors()
                    } label: {
                        Label("Close All", systemImage: "xmark")
                    }
                    Button(role: .destructive) {
                        App.loadFolder(url: getRootDirectory())
                        DispatchQueue.main.async {
                            App.showWelcomeMessage()
                        }
                    } label: {
                        Label("Close Workspace", systemImage: "xmark")
                    }
                }
                Divider()
                Section {
                    Button(action: {
                        App.showWelcomeMessage()
                    }) {
                        Label("Show Welcome Page", systemImage: "newspaper")
                    }

                    Button(action: {
                        openConsolePanel()
                    }) {
                        Label(
                            isPanelVisible ? "Hide Panel" : "Show Panel",
                            systemImage: "chevron.left.slash.chevron.right")
                    }.keyboardShortcut("j", modifiers: .command)

                    if UIApplication.shared.supportsMultipleScenes {
                        Button(action: {
                            UIApplication.shared.requestSceneSessionActivation(
                                nil, userActivity: nil, options: nil, errorHandler: nil)
                        }) {
                            Label("actions.new_window", systemImage: "square.split.2x1")
                        }
                    }

                    Button(action: {
                        stateManager.showsSettingsSheet.toggle()
                    }) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
                #if DEBUG
                    DebugMenu()
                #endif

            } label: {
                Image(systemName: "ellipsis").font(.system(size: 17, weight: .light))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .padding()
            }
            .sheet(isPresented: $stateManager.showsSettingsSheet) {
                if #available(iOS 16.4, *) {
                    SettingsView()
                        .presentationBackground {
                            Color(id: "sideBar.background")
                        }

                        .scrollContentBackground(.hidden)
                        .environmentObject(themeManager)
                } else {
                    SettingsView()
                        .environmentObject(App)
                }
            }
            #endif
        }
    }
}

private struct StackedImageIconView: View {

    var primaryIcon: String
    var secondaryIcon: String?

    var body: some View {
        Image(systemName: primaryIcon)
            .font(.system(size: 17))
            .overlay(alignment: .bottomTrailing) {
                if let secondaryIcon {
                    Image(systemName: secondaryIcon)
                        .foregroundStyle(.background, Color.init("T1"))
                        .font(.system(size: 9))
                } else {
                    EmptyView()
                }
            }

    }
}

#if PYDEAPP
private var popoverView: AnyView? = nil
#endif

private struct ToolbarItemView: View {

    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @SceneStorage("panel.focusedId") var currentPanel: String = DefaultUIState.PANEL_FOCUSED_ID

    let item: ToolbarItem
    #if PYDEAPP
    @State var showPopover = false
    #endif
    
    var body: some View {
        Button(action: {
            if let panelToFocus = item.panelToFocusOnTap {
                showsPanel = true
                currentPanel = panelToFocus
                if panelHeight < 200 {
                    panelHeight = 200
                }
            }
            if let popover = item.popover {
                let cancelable = {
                    showPopover = false
                }
                if let pview = popover(cancelable) {
                    popoverView = pview
                    showPopover = true
                    return
                }
            }
            item.onClick()
        }) {
            StackedImageIconView(primaryIcon: item.icon, secondaryIcon: item.secondaryIcon)
                .font(.system(size: 17))
                .foregroundColor(Color.init("T1"))
                .padding(5)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .hoverEffect(.highlight)
                .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                .padding()
        }
        .if(item.shortCut != nil) {
            $0.keyboardShortcut(item.shortCut!.key, modifiers: item.shortCut!.modifiers)
        }
        #if PYDEAPP
        .if(item.popover != nil) {
            $0.popover(isPresented: $showPopover, content: {
                popoverView
            })
        }
        #endif
    }
}

