//
//  TagsIndicator.swift
//  pydeApp
//
//  Created by Huima on 2023/11/19.
//

import Foundation
import SwiftUI
import pydeCommon

struct TagsIndicator: View {
    @EnvironmentObject var App: MainApp
    
    @ObservedObject var editor: TextEditorInstance
    
    @State private var popupedState: [AnyHashable: Bool] = [:]
    
    @State private var expandedStates: [AnyHashable: Bool] = [:]
        
    private func binding(for key: AnyHashable) -> Binding<Bool> {
        return .init(
            get: { self.popupedState[key, default: false] },
            set: {
                self.popupedState[key] = $0
            })
    }
    
    var body: some View {
        let content = editor.content
        let position = min(editor.selectedRange.upperBound, content.count)
        var row: Int = 0
        var col: Int = 0
        let end = content.index(content.startIndex, offsetBy: position)
        let lines = content[..<end].components(separatedBy: "\n")
        row = lines.count
        col = lines.last?.count ?? 0
        
        var _ctag: CTag?
        var _tmpTags: [CTag] = []
        _tmpTags.append(contentsOf: editor.tags.reversed())
        while (!_tmpTags.isEmpty) {
            let tag = _tmpTags.removeLast()
            if row < tag.line || row > tag.end {
                continue
            }
            _ctag = tag
            if tag.subTags != nil {
                _tmpTags.append(contentsOf: tag.subTags!.reversed())
            } else {
                break
            }
        }
        
        let rootTag = CTag(name: "...", line: 1, subTags: editor.tags)
        
        var indicators = [CTag]()
        if let _ctag {
            indicators.append(_ctag)
            var tempTag = _ctag
            while let p = tempTag.parent {
                indicators.append(p)
                tempTag = p
            }
            indicators = indicators.reversed()
        } else {
            indicators.append(rootTag)
        }
        let contors = indicators
        
        var path = editor.url.path
        path = path.replacingOccurrences(of: App.workSpaceStorage.currentDirectory.url, with: "")
        path = path.replacingOccurrences(of: ConstantManager.documentURL.path, with: "Documents")
        path = path.replacingOccurrences(of: ConstantManager.appdir.path, with: "pyde.app")
        path = path.replacingOccurrences(of: ConstantManager.appGroupContainer.path, with: "Container")
        path = path.replacingOccurrences(of: ConstantManager.iCloudContainerURL?.path ?? "", with: "iCloud")
        if path.starts(with: "/") {
            path.removeFirst()
        }
        let paths = path.split(separator: "/")
        
        return 
//        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                ForEach(paths, id: \.self) {path in
                    Text(path)
                        .foregroundColor(
                            Color.init(id: "panelTitle.activeForeground")
                        )
                        .font(.system(size: 12, weight: .light))
                        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                }.separator(showLast: true) { tag in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .light))
                }
                
                ForEach(contors) { tag in
                    HStack(alignment: .center, spacing: 0) {
                        Text(tag.name)
                            .foregroundColor(
                                Color.init(id: "panelTitle.activeForeground")
                            )
                            .font(.system(size: 12, weight: .light))
                            
                            
                    }
                    .frame(height: 28)
                        .background(Color.init(id: "editor.background"))
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
//                            .background(Color.red)
                        .onTapGesture {
                        expandedStates = [:]
                        if let p = tag.parent {
                            expandedStates[p] = true
                        }
                        popupedState[tag] = true
                    }
                    .popover(isPresented: binding(for: tag), content: {
                        ScrollViewReader { proxy in
                            List {
                                TagsTreeView(tags: tag.parent?.subTags ?? rootTag.subTags ?? [tag],
                                             expansionStates: $expandedStates, expanded: false,
                                             selectedTag: _ctag, onTap: {tag in
                                    indicators.forEach({item in popupedState[item] = false})
                                })
                            }.listStyle(.sidebar)
                                .frame(minWidth: 300, minHeight: 300)
                                .onAppear {
                                    proxy.scrollTo(_ctag)
                                }
                        }.presentationCompactAdaptation()
                    })
                }.separator(showLast: false) { tag in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .light))
                }
//            }
//            .padding(EdgeInsets(top: 0, leading: 10, bottom: 30, trailing: 10))
//            .background(Color.init(id: "editor.background"))
        }
    }
}

struct ForEachWithSeparator<Data: RandomAccessCollection, Content: View, Separator: View>: View
where Data.Element: Hashable {
  let data: Data // data to render
  let content: (Data.Element) -> Content // data item render
  let separator: (Data.Element) -> Separator // separator renderer
  let showLast: Bool // if true, shows the separator at the end of the list

  var body: some View {
    let size = data.count * 2 - (showLast ? 0 : 1)
    let firstIndex = data.indices.startIndex
      return ForEach(0..<size, id: \.self) { i in
      let element = data[data.index(firstIndex, offsetBy: i / 2)]
      if i % 2 == 0 {
        content(element)
      } else {
        separator(element)
      }
    }
  }
}

extension ForEach where Data.Element: Hashable, Content: View {
  func separator<Separator: View>(showLast: Bool = true,
                                  @ViewBuilder separator: @escaping (Data.Element) -> Separator) -> some View {
    ForEachWithSeparator(data: data,
                         content: content,
                         separator: separator,
                         showLast: showLast)
  }
}



struct TagsMenuTree: View {
    let tag: CTag
    
    func toMenu(_ tag: CTag) -> AnyView {
        if tag.subTags == nil {
            return AnyView(Text(tag.name))
        }
        return AnyView(Menu(tag.name) {
            ForEach(tag.subTags ?? []) { tag in
                toMenu(tag)
            }
        })
    }
    
    var body: some View {
        Menu(tag.name) {
            Text("test")
            ForEach(tag.parent?.subTags ?? tag.subTags ?? []) {item in
                toMenu(item)
            }
        }
    }
}


extension View {
    @ViewBuilder
    func presentationCompactAdaptation() -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationCompactAdaptation(.none)
        } else {
            self
        }
    }
}


//extension String {
//    
//    subscript (i: Int) -> Character {
//        return self[self.index(self.startIndex, offsetBy: i)]
//    }
//    
//    subscript (i: Int) -> String {
//        return String(self[i] as Character)
//    }
//    
//    subscript (r: Range<Int>) -> String {
//        let start = index(startIndex, offsetBy: r.lowerBound)
//        let end = index(startIndex, offsetBy: r.upperBound)
//        return String(self[start..<end])
//    }
//    
//    subscript (r: ClosedRange<Int>) -> String {
//        let start = index(startIndex, offsetBy: r.lowerBound)
//        let end = index(startIndex, offsetBy: r.upperBound)
//        return String(self[start...end])
//    }
//}
