//
//  PYActivityBar.swift
//  pydeApp
//
//  Created by Huima on 2023/11/21.
//

import SwiftUI

var ACTIVITY_BAR_HEIGHT: CGFloat = 40.0

struct PYActivityBar: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var activityBarManager: ActivityBarManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @SceneStorage("sidebar.visible") var isSideBarExpanded: Bool = DefaultUIState.SIDEBAR_VISIBLE
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let togglePanel: () -> Void

    var items: [ActivityBarItem] {
        activityBarManager.items
            .sorted { $0.positionPrecedence > $1.positionPrecedence }
            .filter { $0.isVisible() }
    }

    func removeFocus() {
        App.monacoInstance.executeJavascript(
            command: "document.getElementById('overlay').focus()")
        App.terminalInstance.executeScript(
            "document.getElementById('overlay').focus()")
    }

    var body: some View {
//        if #available(iOS 16, *) {
//            ViewThatFits(in: .horizontal) {
//                if items.count > 4 {
//                    ForEach(items[..<3]) {
//                        ActivityBarIconView(activityBarItem: $0)
//                    }
//            }
//        } else {
//            ForEach(items) {
//                ActivityBarIconView(activityBarItem: $0)
//            }
//        }
        HStack(spacing: 0) {
            ForEach(items) {
                ActivityBarIconView(activityBarItem: $0)
            }
            Menu {
//                if App.activeTextEditor is DiffTextEditorInstnace {
//                    Section {
//                        Button(action: {
//                            App.monacoInstance.applyOptions(options: "renderSideBySide: false")
//                        }) {
//                            Label(
//                                NSLocalizedString("Toogle Inline View", comment: ""),
//                                systemImage: "doc.text")
//                        }
//                    }
//                }
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
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: ACTIVITY_BAR_HEIGHT)
        .background(Color.init(id: "sideBar.background"))
//        .background(Color.init(id: "activityBar.background"))
    }
}

