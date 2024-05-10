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
    
//    @State private var showingNewDjangoAlert = false
    @State private var safariUrl = ""
    @State private var showingNewSafariAlert = false
    @State private var djangoName = ""
    @State private var cloneUrl = ""
    
    @FocusState private var editingUrlFocus: Bool
    
    func onClone() {
        if cloneUrl.isEmpty {
            return
        }
        
        let newUrl = cloneUrl
        cloneUrl = ""
        Task {
            try? await App.pyapp.onClone(urlString: newUrl)
        }
    }
    
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
    
    func onNewSafari() {
        if safariUrl.isEmpty {
            return
        }
        
        if !safariUrl.hasPrefix("http://") && !safariUrl.hasPrefix("https://") {
            safariUrl = "http://\(safariUrl)"
        }
        
        if let url = URL(string: safariUrl) {
            let editor = PYSafariEditorInstance(url)
            App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
        }
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
                        .padding(EdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10))
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
            
            if let editor = App.activeEditor as? EditorInstanceWithURL, editor.canEditUrl, App.pyapp.showAddressbar {
                TextField("URL (http | https)", text: $App.pyapp.addressUrl, onEditingChanged: { result in
                    if !result {
                        App.pyapp.showAddressbar = false
                    }
                }, onCommit: {
                    App.pyapp.showAddressbar = false
                    var str = App.pyapp.addressUrl
                    if !str.contains("://") {
                        str = "https://\(str)"
                    }
                    if let url = URL(string: str) {
                        editor.updateUrl(url)
                    }
                }).textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .focused($editingUrlFocus)
                    .padding(7)
                    .background(Color.init(id: "input.background"))
                    .cornerRadius(15)
                    .onAppear {
                        editingUrlFocus = true
                    }
                
                Image(systemName: "arrow.right").font(.system(size: 17))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                    .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
                    .onTapGesture {
                        App.pyapp.showAddressbar = false
                        if let url = URL(string: App.pyapp.addressUrl) {
                            editor.updateUrl(url)
                        }
                    }
            } else {
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
                
            }
            
            if let editor = App.activeEditor as? EditorInstanceWithURL, editor.canEditUrl, App.pyapp.showAddressbar {
                
            } else {
                ForEach(toolBarManager.items) { item in
                    if item.shouldDisplay() {
                        ToolbarItemView(item: item)
                    }
                }
            }

            
            
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
            
            if !App.pyapp.showAddressbar, App.editors.count > 0 {
                Image(systemName: "xmark").font(.system(size: 17))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                    .padding(EdgeInsets.init(top: 10, leading: 8, bottom: 10, trailing: 8))
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
                    } label: {
                        Label("Close Workspace", systemImage: "xmark")
                    }
                    Button() {
                        App.stateManager.showsDirectoryPicker.toggle()
                    } label: {
                        Label("Open workspace folder", systemImage: "folder.badge.gear")
                    }
                }
                Divider()
                Section {
                    Button(action: {
                        App.showWelcomeMessage()
                    }) {
                        Label("Show Welcome Page", systemImage: "newspaper")
                    }
                    
                    if !IapManager.instance.isPurchased {
                        Button {
                            #if PYTHON3IDE
                            App.popupManager.showSheet(content: AnyView(SubIAPView()))
                            #else
                            App.popupManager.showSheet(content: AnyView(IAPView()))
                            #endif
                        } label: {
                            Label("Premium", systemImage: "person")
                        }
                    }
                    
                    Button {
                        App.popupManager.showSheet(content: AnyView(PyRuntimesView()))
                    } label: {
                        Label("Python3 Interpreters Manage", systemImage: "server.rack")
                    }


                    Button(action: {
                        stateManager.showsSettingsSheet.toggle()
                    }) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }

//                    Button(action: {
//                        openConsolePanel()
//                    }) {
//                        Label(
//                            isPanelVisible ? "Hide Panel" : "Show Panel",
//                            systemImage: "chevron.left.slash.chevron.right")
//                    }.keyboardShortcut("j", modifiers: .command)

                    Divider()
                    
                    if UIApplication.shared.supportsMultipleScenes {
                        Button(action: {
                            UIApplication.shared.requestSceneSessionActivation(
                                nil, userActivity: nil, options: nil, errorHandler: nil)
                        }) {
                            Label("actions.new_window", systemImage: "square.split.2x1")
                        }
                    }
                    
                    Menu("New", systemImage: "doc.badge.plus") {
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
                        
                        Divider()
                        
                        Button{
                            App.pyapp.showCloneAlert.toggle()
                        } label: {
                            Label("Clone Store", systemImage: "arrow.triangle.branch")
                        }
                        
                        Button {
                            djangoName = ""
                            App.pyapp.showingNewDjangoAlert.toggle()
                        } label: {
                            Label("New Django Project", systemImage: "folder.badge.gear")
                        }
                        
                        Button {
    //                            showingNewSafariAlert.toggle()
                            if let url = URL(string: "https://www.baidu.cn") {
                                let editor = PYWebViewEditorInstance(url)
                                App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    App.pyapp.showAddressbar = true
                                    App.pyapp.addressUrl = ""
                                }
                            }
                            
                        } label: {
                            Label("New Safari Browser", systemImage: "safari")
                        }
                        
                        
                        Button {
                            guard let url = URL(string: App.workSpaceStorage.currentDirectory.url) else {
                                return
                            }
                            let editor = PYTerminalEditorInstance(url)
                            App.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
                        } label: {
                            Label("New Terminal", systemImage: "apple.terminal")
                        }
                        
                        Divider()
                        
                        Button {
                            App.pyapp.showFilePicker.toggle()
                        } label: {
                            Label("Import File", systemImage: "file")
                        }
                        
                        Button {
                            App.pyapp.showMediaPicker.toggle()
                        } label: {
                            Label("Import Media", systemImage: "image")
                        }
                    }
                    
                    Divider()
                    
                    Menu("Open", systemImage: "") {
                        
                        
                        Button(action: {
//                            App.loadFolder(url: ConstantManager.EXAMPLES)
                            App.pyapp.rightSideShow.toggle()
                        }) {
                            Label("Open Examples", systemImage: "folder")
                        }
                        
                        Button(action: {
                            App.loadFolder(url: ConstantManager.pyhome)
                        }) {
                            Label("Open PythonHome", systemImage: "folder")
                        }
                        
                        Button(action: {
                            App.loadFolder(url: ConstantManager.pysite)
                        }) {
                            Label("Open site-packages", systemImage: "folder")
                        }
                        
                        Button(action: {
                            App.loadFolder(url: ConstantManager.user_site)
                        }) {
                            Label("Open User site-packages", systemImage: "folder")
                        }
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
                    .padding(EdgeInsets.init(top: 10, leading: 8, bottom: 10, trailing: 10))
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
            .alert("Clone Project", isPresented: $App.pyapp.showCloneAlert, actions: {
                TextField("Enter URL (HTTPS/SSH)", text: $cloneUrl)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                Button("common.clone", action: onClone)
                Button("common.cancel") {
                    App.pyapp.showCloneAlert.toggle()
                }
            })
            .alert("New Django Project", isPresented: $App.pyapp.showingNewDjangoAlert){
                TextField("Enter django project name", text: $djangoName)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                Button("common.create", action: onNewDjango)
                Button("common.cancel") {
                    App.pyapp.showingNewDjangoAlert.toggle()
                }
            }
            .alert("New Safari Browser", isPresented: $showingNewSafariAlert){
                TextField("Enter website url", text: $safariUrl)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                Button("common.create", action: onNewSafari)
                Button("common.cancel") {
                    showingNewSafariAlert.toggle()
                }
            }
            .sheet(isPresented: $App.pyapp.showFilePicker, content: {
                FilePickerView(onOpen: { url in
                    guard let localUrl = URL(string: App.workSpaceStorage.currentDirectory.url) else {return}
                    Task {
                        do {
                            let toUrl = localUrl.withoutSame(url.lastPathComponent) ?? localUrl.appendingPathComponent(url.lastPathComponent)
                            try await App.workSpaceStorage.copyItem(at: url, to: toUrl)
                        } catch {
                            App.notificationManager.showErrorMessage(error.localizedDescription)
                        }
                    }
                }, allowedTypes: [.item])
            })
            .mediaImporter(isPresented: $App.pyapp.showMediaPicker,
                            allowedMediaTypes: .all,
                            allowsMultipleSelection: true) { result in
                 switch result {
                 case .success(let urls):
                     guard let localUrl = URL(string: App.workSpaceStorage.currentDirectory.url) else {return}
                     Task {
                         do {
                             for url in urls {
                                 let toUrl = localUrl.withoutSame(url.lastPathComponent) ?? localUrl.appendingPathComponent(url.lastPathComponent)
                                 try await App.workSpaceStorage.copyItem(at: url, to: toUrl)
                             }
                         } catch {
                             App.notificationManager.showErrorMessage(error.localizedDescription)
                         }
                     }
                 case .failure(let error):
                     App.notificationManager.showErrorMessage(error.localizedDescription)
                 }
             }
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
                .padding(EdgeInsets.init(top: 10, leading: 8, bottom: 10, trailing: 8))
//                .padding()
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
        .if (item.menuItems != nil && item.menuItems!.count > 0) { icon in
            Menu(content:  {
                ForEach(item.menuItems!, content: { menuItem in
                    Button(menuItem.title, systemImage: menuItem.icon, action: menuItem.onClick)
                })
            }, label: {
                icon
            })
        }
        #endif
    }
}

