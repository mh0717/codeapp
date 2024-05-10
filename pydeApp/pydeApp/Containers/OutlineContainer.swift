//
//  OutlineContainer.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import Foundation
import SwiftUI
import pydeCommon
import pyde

struct TagsModelTreeView: View {
    @StateObject var tagsModel: TagsModelManager
    
    var body: some View {
        TagsTreeView(tags: tagsModel.tags, expansionStates: $tagsModel.expansionStates, expanded: true, selectedTag: tagsModel.selectedTag) {_ in }
    }
}

struct TagsTreeView: View {
    let tags: [CTag]
    @Binding var expansionStates: [AnyHashable: Bool]
    let expanded: Bool
    let selectedTag: CTag?
    let onTap: (CTag) -> Void
    @EnvironmentObject var App: MainApp
    
    private func onTapTag(_ tag: CTag) {
        if let editor = App.activeTextEditor as? PYTextEditorInstance {
            editor.goToLine(tag.line - 1)
        } else {
            App.monacoInstance.executeJavascript(
                command: "editor.focus()")
            App.monacoInstance.executeJavascript(
                command:
                    "editor.revealPosition({lineNumber: \(tag.line), column: 0})"
            )
            App.monacoInstance.executeJavascript(
                command:
                    "editor.setPosition({lineNumber: \(tag.line), column: 0})"
            )
        }
        
        onTap(tag)
    }
    
    var body: some View {
        PYHierarchyList(
            data: tags,
            children: \.subTags,
            expandStates: $expansionStates,
            defaultExpanded: expanded,
            rowContent: { tag in
                HStack(spacing: 0) {
//                    tag.isGroup
//                    ? Image(systemName: "folder")
//                    : Image(systemName: "\(tag.kind.first?.lowercased() ?? "questionmark").circle")
                    Image(systemName: "\(tag.kind.first?.lowercased() ?? "questionmark").square")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 5))
                    
                    Text(tag.name)
                        .font(.subheadline)
                        .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
                    
                    
//                    Text(": " + tag.kind)
//                        .font(.subheadline)
//                        .foregroundColor(Color.init(id: "list.inactiveSelectionForeground").opacity(0.4))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                        tag == selectedTag
                            ? Color.init(id: "list.inactiveSelectionBackground")
                                .cornerRadius(10.0)
                            : Color.clear.cornerRadius(10.0)
                )
                .listRowBackground(
                        tag == selectedTag
                            ? Color.init(id: "list.inactiveSelectionBackground")
                                .cornerRadius(10.0)
                            : Color.clear.cornerRadius(10.0)
                )
                .listRowSeparator(.hidden)
                .id(tag)
                .onTapGesture {
                    onTapTag(tag)
                }
            }, onDisclose: { _ in
                
            }
        )
    }
}


struct OutlineContainer: View {
    @EnvironmentObject var App: MainApp
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section(
                    header:
                        Text(localizedString(forKey: "Outline"))
                        .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
                ) {
                    TagsModelTreeView(tagsModel: App.pyapp.tagsModelManager)
                }
                
            }
            .listStyle(SidebarListStyle())
            .environment(\.defaultMinListRowHeight, 10)
        }
    }
}
