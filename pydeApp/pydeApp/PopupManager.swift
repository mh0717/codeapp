//
//  PopupManager.swift
//  pydeApp
//
//  Created by Huima on 2023/11/1.
//


import Foundation
import SwiftUI

class PopupManager: ObservableObject {
    @Published var showCover: Bool = false
    
    var coverContent: AnyView = AnyView(EmptyView())

    func showCover(content: AnyView) {
        self.coverContent = content
        showCover = true
    }
    
    
    @Published var showSheet: Bool = false
    
    var sheetContent: AnyView = AnyView(EmptyView())

    func showSheet(content: AnyView) {
        self.sheetContent = content
        showSheet = true
    }
    
    @Published var showOutside: Bool = false
    
    var outsideContent: AnyView = AnyView(EmptyView())

    func showOutside(content: AnyView) {
        self.outsideContent = content
        showOutside = true
    }
    
    @Published var showIap: Bool = false

    
    @Environment(\.dismiss) public var dismiss
    
    
}


