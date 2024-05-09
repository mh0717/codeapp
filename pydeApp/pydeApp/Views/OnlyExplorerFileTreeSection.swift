//
//  OnlyExplorerFileTreeSection.swift
//  Code
//
//  Created by Huima on 2024/5/8.
//

import SwiftUI
import QuickLook

struct OnlyExplorerCell: View {
    @EnvironmentObject var App: MainApp

    let item: WorkSpaceStorage.FileItemRepresentable

    var body: some View {
        if item.subFolderItems != nil {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(width: 14, height: 14)
                Spacer().frame(width: 10)
                
                FileDisplayName(gitStatus: nil, name: item.name.removingPercentEncoding!)
                Spacer()
                
            }.frame(height: 16)
        } else {
            Button {
                guard let url = item._url else {return}
                App.openFile(url: url, alwaysInNewTab: true)
            } label: {
                HStack {
                    FileIcon(url: item.name.removingPercentEncoding!, iconSize: 14)
                        .frame(width: 14, height: 14)
                    FileDisplayName(gitStatus: nil, name: item.name.removingPercentEncoding!)
                    Spacer()
                }
                .frame(height: 16)
            }
        }
    }
}

struct OnlyExplorerFileTreeSection: View {

    @EnvironmentObject var App: MainApp
    var showHiddenFiles: Bool = false
    @ObservedObject var storage: WorkSpaceStorage
    @EnvironmentObject var themeManager: ThemeManager

    let searchString: String = ""
    

    func foldersWithFilter(folder: [WorkSpaceStorage.FileItemRepresentable]?) -> [WorkSpaceStorage
        .FileItemRepresentable]
    {

        var result = [WorkSpaceStorage.FileItemRepresentable]()

        for item in folder ?? [WorkSpaceStorage.FileItemRepresentable]() {
            if searchString == "" {
                result.append(item)
                continue
            }
            if item.subFolderItems == nil
                && item.name.lowercased().contains(searchString.lowercased())
            {
                result.append(item)
                continue
            }
            if item.subFolderItems != nil {
                var temp = item
                temp.subFolderItems = foldersWithFilter(folder: item.subFolderItems)
                if temp.subFolderItems?.count != 0 {
                    result.append(temp)
                }
            }
        }

        if !showHiddenFiles {
            var finalResult = [WorkSpaceStorage.FileItemRepresentable]()
            for item in result {
                if item.name.hasPrefix(".") && !item.name.hasSuffix("icloud") {
                    continue
                }
                if item.subFolderItems != nil {
                    var temp = item
                    temp.subFolderItems = temp.subFolderItems?.filter { a in
                        return !a.name.hasPrefix(".")
                    }
                    finalResult.append(temp)
                    continue
                }
                finalResult.append(item)
            }
            return finalResult
        }

        return result
    }

    var body: some View {
        ExpandedSection(
            header: Text(
            storage.currentDirectory.name.replacingOccurrences(
                of: "{default}", with: " "
            ).removingPercentEncoding!
        ).foregroundColor(Color(id: "sideBarSectionHeader.foreground")),
            content: HierarchyList(
                data: foldersWithFilter(
                    folder: storage.currentDirectory.subFolderItems),
                children: \.subFolderItems,
                expandStates: $storage.expansionStates,
                rowContent: { item in
                    OnlyExplorerCell(
                        item: item
                    ).contextMenu{
                        ContextMenu(item: item)
                    }
                    .frame(height: 16)
                    .listRowBackground(
                        item.url == (App.activeEditor as? EditorInstanceWithURL)?.url.absoluteString
                            ? Color.init(id: "list.inactiveSelectionBackground")
                                .cornerRadius(10.0)
                            : Color.clear.cornerRadius(10.0)
                    )
                    .listRowSeparator(.hidden)
                    .id(item.url)
                },
                onDisclose: { id in
                    if let id = id as? String {
                        storage.requestDirectoryUpdateAt(id: id)
                    }
                }
            )
        )
    }
}

struct OnlyExplorerFileContainer: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    @ObservedObject var storage: WorkSpaceStorage
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                OnlyExplorerFileTreeSection(storage: storage)
            }
            .listStyle(SidebarListStyle())
            .environment(\.defaultMinListRowHeight, 10)
            .background(Color.init(id: "editor.background"))
            Spacer()
        }.background(Color.init(id: "editor.background"))
    }
}


class OnlyExplorerFileEditorInstance: EditorInstanceWithURL {
    let storage: WorkSpaceStorage
    
    init(_ url: URL) {
        let storage = WorkSpaceStorage(url: url)
        self.storage = storage

        super.init(
            view: AnyView(OnlyExplorerFileContainer(storage: storage)),
            title: url.lastPathComponent,
            url: url
        )
    }
}

fileprivate struct ContextMenu: View {

    @EnvironmentObject var App: MainApp

    let item: WorkSpaceStorage.FileItemRepresentable
    
    func onCopyItemToFolder(url: URL) {
        guard let itemURL = URL(string: item.url) else {
            return
        }
        App.workSpaceStorage.copyItem(
            at: itemURL, to: url.appendingPathComponent(itemURL.lastPathComponent),
            completionHandler: { error in
                if let error = error {
                    App.notificationManager.showErrorMessage(error.localizedDescription)
                }
            })
    }

    var body: some View {
        Group {

//            if item.subFolderItems == nil {
                ForEach(App.extensionManager.fileMenuManager.items) { fitem in
                    if let url = item._url, fitem.isVisible(url) {
                        Button(fitem.title, systemImage: fitem.iconSystemName) {
                            fitem.onClick(url)
                        }
                    }
                }
                
                Divider()
//            }

            Button(action: {
                openSharedFilesApp(
                    urlString: URL(string: item.url)!.deletingLastPathComponent()
                        .absoluteString
                )
            }) {
                Text("Show in Files App")
                Image(systemName: "folder")
            }

            Group {

                Button(action: {
                    Task {
                        guard let url = item._url else { return }
                        try await App.duplicateItem(at: url)
                    }
                }) {
                    Text("Duplicate")
                    Image(systemName: "plus.square.on.square")
                }

                Button(
                    role: .destructive,
                    action: {
                        App.trashItem(url: URL(string: item.url)!)
                    },
                    label: {
                        Text("Delete")
                        Image(systemName: "trash")
                    })
                
                Button(action: {
                    guard let itemURL = item._url, let url = URL(string: App.workSpaceStorage.currentDirectory.url) else {return}
                    App.workSpaceStorage.copyItem(
                        at: itemURL, to: url.appendingPathComponent(itemURL.lastPathComponent),
                        completionHandler: { error in
                            if let error = error {
                                App.notificationManager.showErrorMessage(error.localizedDescription)
                            }
                        })
                }) {
                    Label(
                        "复制到工作区",
                        systemImage: "folder")
                }

                Button(action: {
                    App.popupManager.showSheet(content: AnyView(
                        DirectoryPickerView(onOpen: { url in
                            guard let itemURL = URL(string: item.url) else {
                                return
                            }
                            App.workSpaceStorage.copyItem(
                                at: itemURL, to: url.appendingPathComponent(itemURL.lastPathComponent),
                                completionHandler: { error in
                                    if let error = error {
                                        App.notificationManager.showErrorMessage(error.localizedDescription)
                                    }
                                })
                        })
                    ))
                }) {
                    Label(
                        item.url.hasPrefix("file") ? "file.copy" : "file.download",
                        systemImage: "folder")
                }
                
                
            }

            Divider()

            Button(action: {
                let pasteboard = UIPasteboard.general
                guard let targetURL = URL(string: item.url),
                    let baseURL = (App.activeEditor as? EditorInstanceWithURL)?.url
                else {
                    return
                }
                pasteboard.string = targetURL.relativePath(from: baseURL)
            }) {
                Text("Copy Relative Path")
                Image(systemName: "link")
            }

            if item.subFolderItems != nil {
                Button(action: {
                    App.popupManager.showSheet(content: AnyView(
                        PYNewFileView(targetUrl: item.url).environmentObject(App)
                    ))
                }) {
                    Text("New File")
                    Image(systemName: "doc.badge.plus")
                }

                Button(action: {
                    Task {
                        guard let url = item._url else { return }
                        try await App.createFolder(at: url)
                    }
                }) {
                    Text("New Folder")
                    Image(systemName: "folder.badge.plus")
                }

                Button(action: {
                    App.loadFolder(url: URL(string: item.url)!)
                }) {
                    Text("Assign as workspace folder")
                    Image(systemName: "folder.badge.gear")
                }
            }

            if item.subFolderItems == nil {
                Button(action: {
                    App.selectedURLForCompare = item._url
                }) {
                    Text("Select for compare")
                    Image(systemName: "square.split.2x1")
                }

                if App.selectedURLForCompare != nil && App.selectedURLForCompare != item._url {
                    Button(action: {
                        guard let url = item._url else { return }
                        Task {
                            do {
                                try await App.compareWithSelected(url: url)
                            } catch {
                                App.notificationManager.showErrorMessage(error.localizedDescription)
                            }

                        }
                    }) {
                        Text("Compare with selected")
                        Image(systemName: "square.split.2x1")
                    }
                }
            }
        }
    }
}




struct DocumentThumbnailView: View {
    let url: URL
    var thumbnailSize = CGSize(width: 150, height: 150)
    @State var thumbnail = Image(systemName: "doc")
    @Environment(\.displayScale) var displayScale: CGFloat
    
    func generateThumbnail(
        size: CGSize,
        scale: CGFloat,
        completion: @escaping (UIImage) -> Void
    ) {
          let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .all
          )
          
          let generator = QLThumbnailGenerator.shared
          generator.generateRepresentations(for: request) { thumbnail, _, error in
              if let thumbnail = thumbnail {
//                  print("\(name) thumbnail generated")
                  completion(thumbnail.uiImage)
              } else if let error = error {
//                  print("\(name) - \(error)")
              }
          }
      }

    
    var body: some View {
        GroupBox(label: Text(verbatim: url.lastPathComponent).font(.system(size: 12))) {
            thumbnail
                .font(.system(size: 120))
                .foregroundColor(Color(.label))
                .frame(width: thumbnailSize.width, height: thumbnailSize.height, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding()
        }
        .groupBoxStyle(PlainGroupBoxStyle())
        .onAppear {
            generateThumbnail(
                size: thumbnailSize,
                scale: displayScale
            ) { uiImage in
                DispatchQueue.main.async {
                    self.thumbnail = Image(uiImage: uiImage)
                }
            }
        }
    }
}

struct PlainGroupBoxStyle: GroupBoxStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .center) {
      configuration.label
        .padding()
      configuration.content
    }
    .background(Color(.systemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}
