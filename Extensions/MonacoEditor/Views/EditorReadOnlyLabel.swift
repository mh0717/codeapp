//
//  EditorReadOnlyLabel.swift
//  Code
//
//  Created by Ken Chung on 15/8/2023.
//

import SwiftUI

struct EditorReadOnlyLabel: View {

    @AppStorage("editorReadOnly") var editorReadOnly = false
    @EnvironmentObject var App: MainApp

    var body: some View {
        if editorReadOnly || App.activeTextEditor?.readOnly == true {
            Text("READ-ONLY")
        } else {
            EmptyView()
        }
    }
}
