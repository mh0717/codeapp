//
//  FullScreenCoverManager.swift
//  Code
//
//  Created by Huima on 2023/5/31.
//

import Foundation
import SwiftUI

class FullScreenCoverManager: ObservableObject {
    @Published var showCover: Bool = false
    
    var coverContent: AnyView = AnyView(EmptyView())

    func showCover(content: AnyView) {
        self.coverContent = content
        showCover = true
    }
}
