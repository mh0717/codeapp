//
//  PYActivityBar.swift
//  pydeApp
//
//  Created by Huima on 2023/11/21.
//

import SwiftUI
import pydeCommon

var ACTIVITY_BAR_HEIGHT: CGFloat = 40.0

struct PYActivityBar: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var activityBarManager: ActivityBarManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @SceneStorage("sidebar.visible") var isSideBarExpanded: Bool = DefaultUIState.SIDEBAR_VISIBLE
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
//    @Environment private var activityType: ActivityBarType

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
            ForEach(items) {
                PYActivityBarIconView(activityBarItem: $0)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: ACTIVITY_BAR_HEIGHT)
//        .background(Color.init(id: "sideBar.background"))
        .background(Color.init(id: "activityBar.background"))
    }
}

