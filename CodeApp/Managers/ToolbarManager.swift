//
//  ToolbarManager.swift
//  Code
//
//  Created by Ken Chung on 14/11/2022.
//

import SwiftUI

#if PYDEAPP
struct ToolbarMenuItem: Identifiable {
    let id = UUID()
    
    let icon: String
    let title: String
    let onClick: () -> Void
}
#endif

struct ToolbarItem: Identifiable {
    let id = UUID()
    var extenionID: String
    var icon: String
    var secondaryIcon: String?
    var onClick: () -> Void
    var shortCut: KeyboardShortcut?
    var panelToFocusOnTap: String?
    var shouldDisplay: () -> Bool
    #if PYDEAPP
    var menuItems: [ToolbarMenuItem]?
    var popover: ((_ dismiss:@escaping () -> Void) -> AnyView?)?
    #endif
}

class ToolbarManager: CodeAppContributionPointManager {
    @Published var items: [ToolbarItem] = []
}
