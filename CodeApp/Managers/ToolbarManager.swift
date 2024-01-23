//
//  ToolbarManager.swift
//  Code
//
//  Created by Ken Chung on 14/11/2022.
//

import SwiftUI

struct ToolbarItem: Identifiable {
    let id = UUID()
    var extenionID: String
    var icon: String
    var secondaryIcon: String?
    var onClick: () -> Void
    var shortCut: KeyboardShortcut?
    var panelToFocusOnTap: String?
    var shouldDisplay: () -> Bool
    var popover: ((_ dismiss:@escaping () -> Void) -> AnyView?)?
}

class ToolbarManager: CodeAppContributionPointManager {
    @Published var items: [ToolbarItem] = []
}
