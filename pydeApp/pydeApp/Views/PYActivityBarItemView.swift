//
//  PYActivityBarItemView.swift
//  Code
//
//  Created by Huima on 2024/5/9.
//

import SwiftUI

enum ActivityBarType: String{
    case main
    case side
}

private struct ActivityBarTypeKey: EnvironmentKey {
    static let defaultValue: ActivityBarType = .main
}

extension EnvironmentValues {
    var activeType: ActivityBarType {
        get { self[ActivityBarTypeKey.self] }
        set { self[ActivityBarTypeKey.self] = newValue }
    }
}

struct PYActivityBarIconView: View {

    @EnvironmentObject private var activityBarManager: ActivityBarManager
    let activityBarItem: ActivityBarItem

    @SceneStorage("activitybar.selected.item") private var mainActiveItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("side.activitybar.selected.item") private var sideActiveItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM
    
    @SceneStorage("sidebar.visible") private var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE
    
    
    @Environment(\.activeType) var activityType: ActivityBarType
    
    func activeItemId() -> String {
        if activityType == .main {
            return mainActiveItemId
        }
        
        return sideActiveItemId
    }
    
    func setActiveItemId(_ value: String) {
        if activityType == .main {
            mainActiveItemId = value
        } else {
            sideActiveItemId = value
        }
    }
    
    var body: some View {
        ZStack {
            Button(action: {
                if isSideBarVisible && activeItemId() == activityBarItem.itemID {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isSideBarVisible = false
                    }
                } else {
                    setActiveItemId(activityBarItem.itemID)
//                    withAnimation(.easeIn(duration: 0.2)) {
//                        isSideBarVisible = true
//                    }
                }
            }) {
                ZStack {
                    Text(activityBarItem.title)
                        .foregroundColor(.clear)
                        .font(.system(size: 1))

                    Image(systemName: activityBarItem.iconSystemName)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(
                            Color.init(
                                id: (activeItemId() == activityBarItem.itemID && isSideBarVisible)
                                    ? "activityBar.foreground"
                                    : "activityBar.inactiveForeground")
                        )
                        .padding(5)
                }.frame(maxWidth: .infinity, minHeight: 60.0)
            }
            .if(activityBarItem.shortcutKey != nil && activityBarItem.modifiers != nil) { view in
                view
                    .keyboardShortcut(
                        activityBarItem.shortcutKey!, modifiers: activityBarItem.modifiers!)
            }
            .if(activityBarItem.contextMenuItems != nil) { view in
                view
                    .contextMenu {
                        ForEach(activityBarItem.contextMenuItems!(), id: \.id) { item in
                            Button(action: {
                                item.action()
                            }) {
                                Text(item.text)
                                Image(systemName: item.imageSystemName)
                            }
                        }
                    }
            }
            if let bubble = activityBarItem.bubble() {
                switch bubble {
                case let .text(bubbleText):
                    if bubbleText.isEmpty {
                        Circle()
                            .fill(Color.init(id: "statusBar.background"))
                            .frame(width: 10, height: 10)
                            .offset(x: 10, y: -10)
                    } else {
                        ZStack {
                            Text(bubbleText)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 3)
                        .foregroundColor(
                            Color.init(id: "statusBar.foreground")
                        )
                        .background(
                            Color.init(id: "statusBar.background")
                        )
                        .cornerRadius(5)
                        .offset(x: 10, y: -10)
                    }
                case let .systemImage(systemImage):
                    Image(systemName: systemImage)
                        .font(.system(size: 12))
                        .padding(.horizontal, 3)
                        .foregroundColor(
                            Color.init(id: "statusBar.foreground")
                        )
                        .background(
                            Color.init(id: "statusBar.background")
                        )
                        .cornerRadius(5)
                        .offset(x: 10, y: -10)
                }
            }
        }
    }
}

