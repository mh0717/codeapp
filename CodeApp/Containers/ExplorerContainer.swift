//
//  ExplorerContainer.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import UniformTypeIdentifiers
//import pydeCommon
import SwiftGit2
import Combine

var cancellableSet: Set<AnyCancellable> = []

struct ExplorerContainer: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State var selectedURL: String = ""
    @State private var selectKeeper = Set<String>()
    @State private var editMode = EditMode.inactive
    @State private var searchString: String = ""
    @State private var searching: Bool = false

    @AppStorage("explorer.showHiddenFiles") var showHiddenFiles: Bool = false

    func onOpenNewFile() {
        stateManager.showsNewFileSheet.toggle()
    }

    func onPickNewDirectory() {
        stateManager.showsDirectoryPicker.toggle()
    }

    func openSharedFilesApp(urlString: String) {
        let sharedurl = urlString.replacingOccurrences(of: "file://", with: "shareddocuments://")
        if let furl: URL = URL(string: sharedurl) {
            UIApplication.shared.open(furl, options: [:], completionHandler: nil)
        }
    }

    func onDragCell(item: WorkSpaceStorage.FileItemRepresentable) -> NSItemProvider {
        guard let url = item._url else {
            return NSItemProvider()
        }
        if item.subFolderItems != nil {
            let itemProvider = NSItemProvider()
            itemProvider.suggestedName = url.lastPathComponent
            itemProvider.registerFileRepresentation(
                forTypeIdentifier: "public.folder", visibility: .all
            ) {
                $0(url, false, nil)
                return nil
            }
            return itemProvider
        } else {
            guard let provider = NSItemProvider(contentsOf: url) else {
                return NSItemProvider()
            }
            provider.suggestedName = url.lastPathComponent
            return provider
        }
    }

    func onDropToFolder(item: WorkSpaceStorage.FileItemRepresentable, providers: [NSItemProvider])
        -> Bool
    {
        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: UTType.item.identifier) {
                data, error in
                if let at = data as? URL,
                    let to = item._url?.appendingPathComponent(
                        at.lastPathComponent, conformingTo: .item)
                {
                    App.workSpaceStorage.copyItem(
                        at: at, to: to,
                        completionHandler: { error in
                            if let error = error {
                                App.notificationManager.showErrorMessage(
                                    error.localizedDescription)
                            }
                        })
                }
            }
        }
        return true
    }

    func scrollToActiveEditor(proxy: ScrollViewProxy) {
        if let url = (App.activeEditor as? EditorInstanceWithURL)?.url {
            proxy.scrollTo(url.absoluteString, anchor: .top)
        }
    }
//    
//    @State var outlineHeight = 200.0
//    @State var tagsExpanded: Bool = true
//    
//    @State var history: [CMNode] = []
//    
//    @State var tags: [CTag] = []
//    @State var mtitle: String = ""
//    
//    
//    struct CMNode: Identifiable, Hashable {
//        var anodes: [Int] = []
//        var pnodes: [Int] = []
//        var nextAnodes: [Int] = []
//        var msg: String = ""
//        var id: Int = 0
//    }
//    @MainActor
//    func updateHistory() async {
//        var clist: [CMNode] = []
//        var lastNode: CMNode?
//        var list: [Commit] = []
//        if let commites = try? await App.workSpaceStorage.gitServiceProvider?.history() {
//            while let item = commites.next(), let commit = try? item.get() {
//                var cnode = CMNode()
//                cnode.msg = commit.message
//                cnode.id = commit.oid.hashValue
//                cnode.pnodes = commit.parents.map({$0.hashValue})
//                if var lastNode {
//                    lastNode.anodes.forEach { item in
//                        if !cnode.anodes.contains(item) {
//                            cnode.anodes.append(item)
//                        }
//                    }
//                    
//                    lastNode.pnodes.forEach({item in
//                        if !cnode.anodes.contains(item) {
//                            cnode.anodes.append(item)
//                        }
//                    })
////                    lastNode.anodes.forEach { item in
////                        if !cnode.anodes.contains(item) {
////                            cnode.anodes.append(item)
////                        }
////                    }
//                    cnode.anodes.removeAll(where: {$0 == lastNode.id})
//                    if (!cnode.anodes.contains(cnode.id)) {
//                        cnode.anodes.append(cnode.id)
//                    }
//                    lastNode.nextAnodes = cnode.anodes
//                    clist[clist.count - 1] = lastNode
//                } else {
//                    cnode.anodes = [cnode.id]
//                }
//                lastNode = cnode
//                clist.append(cnode)
//            }
//            self.history = clist
//        }
//    }
//    
//    func updateHistory() {
//        Task.init {
//            await self.updateHistory()
//        }
//    }

    var body: some View {
        
        GeometryReader(content: { geometry in
            VStack(spacing: 0) {
                
                InfinityProgressView(enabled: App.workSpaceStorage.explorerIsBusy)
                
                ScrollViewReader { proxy in
                    List {
                        ExplorerEditorListSection(
                            onOpenNewFile: onOpenNewFile,
                            onPickNewDirectory: onPickNewDirectory
                        )
                        ExplorerFileTreeSection(
                            searchString: searchString, onDrag: onDragCell,
                            onDropToFolder: onDropToFolder)
                        
//                        ExplorerTagTreeSection()
                        
//                        ForEach(history) { commit in
//                            ZStack(alignment: .topLeading) {
//                                HStack(spacing: 0) {
//                                    ForEach(commit.anodes.indices) {index in
//                                        Divider()
//                                        Text((commit.anodes[index] == commit.id) ? "O" : " ")
//                                            .frame(width: 16).padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: 8))
//                                    }.id(commit)
//                                    Text(commit.msg).lineLimit(1)
//                                }.id(commit)
//                                ForEach(0..<commit.pnodes.count) { index in
//                                    let cindex = commit.anodes.firstIndex(of: commit.id) ?? 0
//                                    let tindex = commit.nextAnodes.firstIndex(of: commit.pnodes[index]) ?? 0
//                                    Path { path in
//                                        path.move(to: CGPoint(x: cindex * 15, y: 20))
//                                        path.addLine(to: CGPoint(x: tindex * 15, y: 40))
//                                    }.stroke(Color.red, lineWidth: 3)
//                                }
//                            }.id(commit)
//                        }
                        
                        
                    }
                    .listStyle(SidebarListStyle())
                    .environment(\.defaultMinListRowHeight, 10)
                    .environment(\.editMode, $editMode)
                    .onAppear {
                        scrollToActiveEditor(proxy: proxy)
                    }
                }
                
                
//                ScrollViewReader(content: { proxy in
//                    DisclosureGroup(
//                        isExpanded: $tagsExpanded,
//                        content: {
//                            List {
//                                
//                            }
//                            .listRowSeparator(.hidden)
//                            .listStyle(SidebarListStyle())
//                            .frame(minHeight: max(80, min(outlineHeight, geometry.size.height * 0.5)))
//                            .id(App.activeEditor)
//                        },
//                        label: {
//                            Text("\(App.activeEditor?.title ?? ""): \(geometry.size.height)")
//                                .gesture(
//                                    DragGesture()
//                                        .onChanged { value in
//                                            let proposedNewHeight = outlineHeight - value.translation.height
//                                            outlineHeight = max(80, min(proposedNewHeight, geometry.size.height * 0.5))
//                                        }
//                                )
//                        }
//                    )
//                    .id(App.activeEditor)
//                })
//                
                
//                WebView(url: ConstantManager.GIT_HISTORY_H5_RUL)
//                    .frame(minHeight: 250)
                
                
                HStack(spacing: 30) {
                    if editMode == EditMode.inactive {
                        if searching {
                            HStack {
                                Image(systemName: "line.horizontal.3.decrease").font(.subheadline)
                                    .foregroundColor(Color.init(id: "activityBar.foreground"))
                                TextField("Filter", text: $searchString)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                Image(systemName: "checkmark.circle").contentShape(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                    Color.init(id: "activityBar.foreground")
                                ).onTapGesture { withAnimation { searching = false } }
                            }
                        } else {
                            Image(systemName: "doc.badge.plus").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture { onOpenNewFile() }
                            Image(systemName: "folder.badge.plus").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture {
                                Task {
                                    guard let url = App.workSpaceStorage.currentDirectory._url else {
                                        return
                                    }
                                    try await App.createFolder(at: url)
                                }
                            }
                            
                            if !App.workSpaceStorage.remoteConnected {
                                Image(systemName: "folder.badge.gear").contentShape(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                    Color.init(id: "activityBar.foreground")
                                ).onTapGesture { onPickNewDirectory() }
                            }
                            
                            Image(systemName: "line.3.horizontal.decrease").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture { withAnimation { searching = true } }
                            Image(systemName: "arrow.clockwise").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture { App.reloadDirectory() }
                        }
                    } else {
                        if selectKeeper.isEmpty {
                            //                        Image(systemName: "square.and.arrow.up").contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).hoverEffect(.highlight).font(.subheadline).foregroundColor(.gray)
                            Image(systemName: "trash").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(.gray)
                            Image(systemName: "square.on.square").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(.gray)
                        } else {
                            //                        Image(systemName: "square.and.arrow.up").contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).hoverEffect(.highlight).font(.subheadline).foregroundColor(Color.init(id: "activityBar.foreground"))
                            //                            .onTapGesture{activityViewController.share(urls: Array(selectKeeper).map{URL.init(string: $0)!})}
                            Image(systemName: "trash").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture {
                                for i in selectKeeper {
                                    App.trashItem(url: URL(string: i)!)
                                    selectKeeper.remove(i)
                                }
                                editMode = EditMode.inactive
                            }
                            Image(systemName: "square.on.square").contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture {
                                for i in selectKeeper {
                                    Task {
                                        try await App.duplicateItem(at: URL(string: i)!)
                                    }
                                }
                                editMode = EditMode.inactive
                            }
                        }
                        Image(systemName: "checkmark.circle").contentShape(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                        ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                            Color.init(id: "activityBar.foreground")
                        ).onTapGesture { withAnimation { editMode = EditMode.inactive } }
                    }
                    
                }.padding(.horizontal, 15).padding(.vertical, 8).background(
                    Color.init(id: "activityBar.background")
                ).cornerRadius(12).padding(.bottom, 15).padding(.horizontal, 8)
                
            }
        })}
}


struct WebView: UIViewRepresentable {

    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let wview = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            wview.isInspectable = true
        }
        
        return wview
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
