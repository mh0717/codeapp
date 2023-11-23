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
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: ACTIVITY_BAR_HEIGHT)
        .background(Color.init(id: "sideBar.background"))
//        .background(Color.init(id: "activityBar.background"))
    }
}

