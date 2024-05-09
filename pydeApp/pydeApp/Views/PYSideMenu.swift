//
//  PYSideMenu.swift
//  Code
//
//  Created by Huima on 2024/5/9.
//

import Foundation
import SwiftUI

private var EDITOR_MIN_WIDTH: CGFloat = 200.0
private var REGULAR_SIDEBAR_MIN_WIDTH: CGFloat = DefaultUIState.SIDEBAR_WIDTH


struct PYSideMenu: View {
    @EnvironmentObject private var App: MainApp
    let activeType: ActivityBarType
    let openConsolePanel: () -> Void
    let isRegular: Bool
    
    @SceneStorage("sidebar.width") private var sideBarWidth: Double = DefaultUIState.SIDEBAR_WIDTH

//    @GestureState var sideBarWidthTranslation: CGFloat = 0
    @State var sideBarWidthTranslation: CGFloat = 0

    var maxWidth: CGFloat {
        windowWidth
            - UIApplication.shared.getSafeArea(edge: .left)
            - UIApplication.shared.getSafeArea(edge: .right)
            - ACTIVITY_BAR_WIDTH
            - EDITOR_MIN_WIDTH
    }
    var windowWidth: CGFloat

    func evaluateProposedWidth(proposal: CGFloat) {
        if proposal < REGULAR_SIDEBAR_MIN_WIDTH {
            sideBarWidth = DefaultUIState.SIDEBAR_WIDTH
        } else if proposal > maxWidth {
            sideBarWidth = maxWidth
        } else {
            sideBarWidth = proposal
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            PYActivityBar(togglePanel: openConsolePanel)
                .environmentObject(App.extensionManager.activityBarManager)
                .environment(\.activeType, activeType)
            
            PYSidebar()
                .environment(\.activeType, activeType)
                .frame(maxHeight: .infinity)
            
        }.background(Color.init(id: "sideBar.background").edgesIgnoringSafeArea(.all))
            .accentColor(Color.init(id: "activityBar.inactiveForeground"))
            .hiddenScrollableContentBackground()
            .if(isRegular, transform: { view in
                view.gesture(
                    DragGesture()
//                        .updating($sideBarWidthTranslation) { value, state, transaction in
//                            state = value.translation.width
//                        }
                        .onChanged({ value in
                            sideBarWidthTranslation = value.translation.width
                        })
                        .onEnded { value in
                            let proposedNewHeight = sideBarWidth + value.translation.width
                            evaluateProposedWidth(proposal: proposedNewHeight)
                            sideBarWidthTranslation = 0
                        }
                )
                .frame(
                    width: min(
                        max(sideBarWidth + sideBarWidthTranslation, REGULAR_SIDEBAR_MIN_WIDTH),
                        maxWidth
                    )
                )
            })
            
            .background(Color.init(id: "sideBar.background"))
    }
}
