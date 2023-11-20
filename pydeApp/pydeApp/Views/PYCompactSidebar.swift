//
//  PYCompactSidebar.swift
//  pydeApp
//
//  Created by Huima on 2023/11/21.
//

import SwiftUI

struct PYCompactSidebar: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var activityBarManager: ActivityBarManager

    @SceneStorage("activitybar.selected.item") var activeItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("sidebar.visible") var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE

    var items: [ActivityBarItem] {
        activityBarManager.items
            .sorted { $0.positionPrecedence > $1.positionPrecedence }
            .filter { $0.isVisible() }
    }
    
    func openConsolePanel() {
        
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                PYActivityBar(togglePanel: openConsolePanel)
                    .environmentObject(activityBarManager)

                Group {
                    if !stateManager.isSystemExtensionsInitialized {
                        ProgressView()
                    } else if let item = activityBarManager.itemForItemID(itemID: activeItemId) {
                        item.view
                    } else {
                        DescriptionText("sidebar.no_section_selected")
                    }
                }.background(Color.init(id: "sideBar.background"))
            }
//            .fixedSize(horizontal: true, vertical: false)
            .frame(width: 280.0)
            .background(Color.init(id: "sideBar.background"))

            ZStack {
                Color.black.opacity(0.001)
                Spacer()
            }.onTapGesture {
                withAnimation(.easeIn(duration: 0.2)) {
                    isSideBarVisible.toggle()
                }
            }
        }
    }
}

