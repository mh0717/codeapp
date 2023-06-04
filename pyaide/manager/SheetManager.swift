//
//  SheetManager.swift
//  Code
//
//  Created by Huima on 2023/6/1.
//

import Foundation
import SwiftUI

class SheetManager: ObservableObject {
    @Published var showSheet: Bool = false
    
    var sheetContent: AnyView = AnyView(EmptyView())

    func showSheet(content: AnyView) {
        self.sheetContent = content
        showSheet = true
    }
}
