//
//  TagsModelManager.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import Combine
import pydeCommon
import SwiftUI
import pyde

private let TAGS_VALID_EXT = ["py", "md", "c", "c++", "cpp", "h", "js", "html", "htm", "json", "css", "php", ]

class TagsModelManager: ObservableObject {
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
                
                if let currentEditor, TAGS_VALID_EXT.contains(currentEditor.url.pathExtension.lowercased()),  currentEditor.tags.isEmpty {
                    Task {
                        if let tags = await requestCTagsService(currentEditor.url.path, content: currentEditor.content) {
                            DispatchQueue.main.async { [weak currentEditor] in
                                currentEditor?.tags = tags
                            }
                        }
                    }
                }
            })
            .filter({$0 is TextEditorInstance})
            .map({$0 as! TextEditorInstance})
            .flatMap({$0.$content})
            .removeDuplicates()
            .flatMap({content in
                Future<[CTag], Never> {
                    if let currentEditor, TAGS_VALID_EXT.contains(currentEditor.url.pathExtension.lowercased()) {
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
