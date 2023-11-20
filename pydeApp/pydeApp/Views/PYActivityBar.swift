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
        HStack(spacing: 0) {
            if horizontalSizeClass == .regular {
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
            
            
            ForEach(items) {
                ActivityBarIconView(activityBarItem: $0)
            }
//            PanelToggleButton(togglePanel: togglePanel)
//            ZStack {
//                Color.black.opacity(0.001)
//                Spacer()
//            }.onTapGesture { removeFocus() }
//            Spacer()
//            ConfigurationToggleButton()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: ACTIVITY_BAR_HEIGHT)
        .background(Color.init(id: "sideBar.background"))
//        .background(Color.init(id: "activityBar.background"))
    }
}

