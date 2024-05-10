//
//  ExplorerTagSection.swift
//  pydeApp
//
//  Created by Huima on 2023/11/6.
//

import SwiftUI
import pydeCommon

//struct ExplorerTagTreeSection: View {
//
//    @EnvironmentObject var App: MainApp
//    
//    var body: some View {
//        Section(
//            header:
//                Text( "大纲")
//                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
//        ) {
//            TagsModelTreeView(tagsModel: App.pyapp.tagsModelManager)
//        }
//    }
//}
//
//
//struct NodeOutlineGroup<Node, Content>: View where Node: Identifiable, Content: View {
//    let node: Node
//    let childKeyPath: KeyPath<Node, [Node]?>
//    @State var rowInsets: EdgeInsets? = nil
//    @State var isExpanded: Bool = true
//    let content: (Node) -> Content
//    
//    
//    var body: some View {
//        if node[keyPath: childKeyPath] != nil {
//            DisclosureGroup(
//                isExpanded: $isExpanded,
//                content: {
//                    if isExpanded {
//                        ForEach(node[keyPath: childKeyPath]!) { childNode in
//                            let group = NodeOutlineGroup(node: childNode, childKeyPath: childKeyPath, isExpanded: isExpanded, content: content)
//                            rowInsets == nil
//                            ? AnyView(group)
//                            : AnyView(group.listRowInsets(rowInsets))
//                        }
//                    }
//                },
//                label: { content(node) })
//        } else {
//            content(node)
//        }
//    }
//}
//
//
//
//struct TagItemRepresentable: Identifiable {
//    var id: String {
//        "\(name):\(line)"
//    }
//    var type: String
//    var name: String
//    var line: Int
//    var subItems: [TagItemRepresentable]?
//    var isGroup: Bool {
//        subItems != nil
//    }
//
////    init(name: String, type: String, line: Int, subItems: [TagItemRepresentable]? = nil) {
////        
////    }
//}
//
//
//struct TagExplorerCell: View {
//    @EnvironmentObject var App: MainApp
//
//    let item: TagItemRepresentable
//
//    var body: some View {
//        if item.isGroup {
//            GroupCell(item: item)
//                .frame(height: 16)
//        } else {
//            TagCell(item: item)
//                .frame(height: 16)
//        }
//    }
//}
//
//private struct TagCell: View {
//
//    @EnvironmentObject var App: MainApp
//    @EnvironmentObject var themeManager: ThemeManager
//    @State var item:TagItemRepresentable
//
//    init(item: TagItemRepresentable) {
//        self.item = item
//    }
//
//
//    var body: some View {
//        HStack {
//            Divider()
//            FileIcon(url: "test.py", iconSize: 14)
//                .frame(width: 14, height: 14)
//
//            Text(item.name)
//                .font(.subheadline)
//                .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
//            
//            Spacer()
//
//        }
//        .padding(5)
//    }
//}
//
//private struct GroupCell: View {
//
//    @EnvironmentObject var App: MainApp
//    @EnvironmentObject var themeManager: ThemeManager
//    @State var item: TagItemRepresentable
//
//    init(item: TagItemRepresentable) {
//        self._item = State.init(initialValue: item)
//    }
//
//    var body: some View {
//        HStack {
//            Divider()
//                .background(Color.red)
//            Image(systemName: "folder")
//                .foregroundColor(.gray)
//                .font(.system(size: 14))
//                .frame(width: 14, height: 14)
//            Spacer().frame(width: 10)
//            Divider()
//
//            
//            Text(item.name)
//                .font(.subheadline)
//                .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
//            Spacer()
//        }
//        .padding(5)
//    }
//}


//        DisclosureGroup(
//            isExpanded: $expanded,
//            content: {
////                OutlineGroup(editor?.tags ?? [], children: \.subTags) { tag in
////                    HStack() {
////                        tag.isGroup
////                        ? Image(systemName: "folder")
////                        : Image(systemName: "42.circle")
////                        Text("\(tag.name): \(tag.kind)")
////                            .font(.subheadline)
////                            .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
////                    }
////                    .frame(minHeight: 16)
////                    .id(tag.id)
////                }
////                .listRowInsets(.init(top: 5, leading: -8, bottom: 5, trailing: 16))
//                NodeOutlineGroup(node: CTag(name: "大纲", subTags: editor?.tags), childKeyPath: \.subTags) { tag in
//                    HStack() {
//                        tag.isGroup
//                        ? Image(systemName: "folder")
//                        : Image(systemName: "42.circle")
//                        Text("\(tag.name): \(tag.kind)")
//                            .font(.subheadline)
//                            .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
//                    }
//                    .frame(minHeight: 16)
//                    .id(tag.id)
//                }
//            },
//            label: {
//                Text("大纲")
//            }
//        )
//        NodeOutlineGroup(
//            node: CTag(name: "大纲", line: -1, subTags: App.tagsModel.tags),
//            childKeyPath: \.subTags, rowInsets: .init(top: 5, leading: -4, bottom: 5, trailing: 12)) { tag in
//            HStack() {
//                tag.line < 0
//                ? nil
//                : tag.isGroup
//                ? Image(systemName: "folder")
//                : Image(systemName: "42.circle")
//                Text("\(tag.name): \(tag.kind)")
//                    .font(.subheadline)
//                    .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
//            }
//            .frame(minHeight: 16)
//            .id(tag.id)
//        }
//        .listRowBackground(
//            Color.clear
//        )
//        .listRowSeparator(.hidden)
//        .listRowInsets(.init(top: 5, leading: -8, bottom: 5, trailing: 16))
