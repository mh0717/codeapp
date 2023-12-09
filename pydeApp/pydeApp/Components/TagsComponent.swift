//
//  TagsComponent.swift
//  pydeApp
//
//  Created by Huima on 2023/11/17.
//

import Foundation
import Combine
import pydeCommon
import SwiftUI
import pyde

class TagsModel: ObservableObject {
    @Published var tags: [CTag] = []
    @Published var selectedTag: CTag?
    @Published var expansionStates: [AnyHashable: Bool] = [:]
    
    private var cancellables: Set<AnyCancellable> = []
    
    func listen(_ app: MainApp) {
//        objectWillChange.sink {[weak app] _ in
//            DispatchQueue.main.async {
//                app?.objectWillChange.send()
//            }
//        }.store(in: &cancellables)
        
        weak var currentEditor: TextEditorInstance?
        
        app.$activeEditor
            .handleEvents(receiveOutput: {[weak self] editor in
                guard let self else {return}
                currentEditor = editor as? TextEditorInstance
                self.expansionStates = [:]
                self.tags = currentEditor?.tags ?? []
            })
            .filter({$0 is TextEditorInstance})
            .map({$0 as! TextEditorInstance})
            .flatMap({$0.$content})
            .removeDuplicates()
            .flatMap({content in
                Future<[CTag], Never> {
                    if let currentEditor {
                        return await requestCTagsService(currentEditor.url.path, content: currentEditor.content) ?? []
                    } else {
                        return [CTag]()
                    }
                }
                
            })
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: {tags in
                currentEditor?.tags = tags
            })
            .assign(to: \.tags, on: self)
            .store(in: &cancellables)

    }
}


extension Future where Failure == Never {
    convenience init(operation: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                let output = try await operation()
                promise(.success(output))
            }
        }
    }
}

struct TagsModelTreeView: View {
    @StateObject var tagsModel: TagsModel
    
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
                HStack() {
                    tag.isGroup
                    ? Image(systemName: "folder")
                    : Image(systemName: "42.circle")
                    
                    Text("\(tag.name): \(tag.kind)")
                        .font(.subheadline)
                        .foregroundColor(Color.init(id: "list.inactiveSelectionForeground"))
                }
                .frame(height: 16)
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
                        Text( "大纲")
                        .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
                ) {
                    TagsModelTreeView(tagsModel: App.tagsModel)
                }
                
            }
            .listStyle(SidebarListStyle())
            .environment(\.defaultMinListRowHeight, 10)
        }
    }
}


class OutlineExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let outline = ActivityBarItem(
            itemID: "OUTLINE",
            iconSystemName: "text.justify",
            title: "Outline",
            shortcutKey: "o",
            modifiers: [.command, .shift],
//            view: AnyView(OutlineContainer()),
            view: AnyView(PyPiView()),
            contextMenuItems: nil,
            bubble: {nil},
            isVisible: { true }
        )
        
        contribution.activityBar.registerItem(item: outline)
//        
//        let outline1 = ActivityBarItem(
//            itemID: "OUTLINE1",
//            iconSystemName: "text.alignleft",
//            title: "Outline1",
//            shortcutKey: "o",
//            modifiers: [.command, .shift],
//            view: AnyView(OutlineContainer()),
//            contextMenuItems: nil,
//            bubble: {nil},
//            isVisible: { true }
//        )
//        
//        contribution.activityBar.registerItem(item: outline1)
//        
//        let outline2 = ActivityBarItem(
//            itemID: "OUTLINE2",
//            iconSystemName: "text.alignright",
//            title: "Outline2",
//            shortcutKey: "o",
//            modifiers: [.command, .shift],
//            view: AnyView(OutlineContainer()),
//            contextMenuItems: nil,
//            bubble: {nil},
//            isVisible: { true }
//        )
//        
//        contribution.activityBar.registerItem(item: outline2)
//        
//        let outline3 = ActivityBarItem(
//            itemID: "OUTLINE3",
//            iconSystemName: "text.aligncenter",
//            title: "Outline3",
//            shortcutKey: "o",
//            modifiers: [.command, .shift],
//            view: AnyView(OutlineContainer()),
//            contextMenuItems: nil,
//            bubble: {nil},
//            isVisible: { true }
//        )
//        
//        contribution.activityBar.registerItem(item: outline3)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        
    }
}
