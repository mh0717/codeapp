//
//  PYSideBar.swift
//  Code
//
//  Created by Huima on 2024/5/6.
//

import SwiftUI

struct PYSidebar: View {
    @EnvironmentObject var activityBarManager: ActivityBarManager
    @EnvironmentObject var stateManager: MainStateManager
    
    @SceneStorage("activitybar.selected.item") private var mainActiveItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("side.activitybar.selected.item") private var sideActiveItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM

    @Environment(\.activeType) var activityType: ActivityBarType
    
    func activeItemId() -> String {
        if activityType == .main {
            return mainActiveItemId
        }
        
        return sideActiveItemId
    }

    var body: some View {
        ZStack(alignment: .center) {
            if !stateManager.isSystemExtensionsInitialized {
                ProgressView()
            } else if let item = activityBarManager.itemForItemID(itemID: activeItemId()),
                item.isVisible()
            {
                item.view
            } else {
                DescriptionText("sidebar.no_section_selected")
            }
        }
        .background(Color.init(id: "sideBar.background"))
    }
}
