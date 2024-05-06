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

    @SceneStorage("activitybar.selected.item") var activeItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM

    var body: some View {
        ZStack(alignment: .center) {
            if !stateManager.isSystemExtensionsInitialized {
                ProgressView()
            } else if let item = activityBarManager.itemForItemID(itemID: activeItemId),
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
