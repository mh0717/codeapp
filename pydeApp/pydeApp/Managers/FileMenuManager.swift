//
//  FileMenuManager.swift
//  Code
//
//  Created by Huima on 2024/5/6.
//

import Foundation
import SwiftUI


struct FileMenuItem: Identifiable {
    let id = UUID()
    var iconSystemName: String
    var title: LocalizedStringKey
    var positionPrecedence: Int = 0
    var isVisible: ((URL) -> Bool)
    var onClick: ((URL) -> Void)
}

class FileMenuManager: CodeAppContributionPointManager {
    @Published var items: [FileMenuItem] = []

}
