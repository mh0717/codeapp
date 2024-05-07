//
//  DownloadContainer.swift
//  iPyDE
//
//  Created by Huima on 2024/4/25.
//

import Foundation
import SwiftUI
import Tiercel

struct DownloadContainer: View {
    @ObservedObject var manager = DownloadManager.instance
    
    @FocusState private var addingFocus: Bool
    @State var downloadAdding = false
    @State var addingUrl = ""
    
    @State var showDeleteAlert = false
    @State var shouldDeleteCache = false
    
    func addDonwload() {
        guard  !addingUrl.isEmpty, let url = URL(string: addingUrl) else {
            return
        }
        
        manager.sessionManager.download(url)
    }
    
    var body: some View {
        VStack {
            List {
                Section(
                    header: VStack {
                        HStack{
                            Text("Dwonload")
                            Spacer()
                            Menu {
                                Button("New download", systemImage: "plus") {
                                    downloadAdding = true
                                }
                                
                                Button("Total Start", systemImage: "play") {
                                    manager.totalStart()
                                }
                                
                                Button("Total Stop", systemImage: "stop") {
                                    manager.totalSuspend()
                                }
                                
                                Button("Total Remove", systemImage: "trash") {
                                    shouldDeleteCache = false
                                    showDeleteAlert = true
                                }
                            } label: {
                                Image(systemName: "ellipsis").font(.system(size: 17))
                                    .foregroundColor(Color.init("T1"))
                                    .padding(5)
                                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .hoverEffect(.highlight)
                            }
                        }
                    }
                ) {
                    ForEach(manager.sessionManager.tasks, id: \.self) { task in
                        DownloadCell(task: task)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
               
            }
            .listStyle(.sidebar)
            .listRowSeparator(.hidden)
            
            Spacer()
            
            HStack(spacing: 30) {
                if downloadAdding {
                    HStack {
                        TextField("Input Download url", text: $addingUrl)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($addingFocus)
                            .onSubmit {
                                downloadAdding = false
                                addDonwload()
                            }
                            .task {
                                addingFocus = true
                            }
                        Image(systemName: "plus").contentShape(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                        ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                            Color.init(id: "activityBar.foreground")
                        ).onTapGesture {
                            downloadAdding = false
                            addDonwload()
                        }
                    }
                } else {
                    
                    Image(systemName: "plus").contentShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                        Color.init(id: "activityBar.foreground")
                    ).onTapGesture { downloadAdding = true
                        addingUrl = ""
                        if let url = URL(string: UIPasteboard.general.string ?? "") {
                            addingUrl = UIPasteboard.general.string ?? ""
                        }
                        /*manager.download("https://officecdn-microsoft-com.akamaized.net/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/Microsoft_Office_16.24.19041401_Installer.pkg")*/}
                    
                    Image(systemName: "play").contentShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                        Color.init(id: "activityBar.foreground")
                    ).onTapGesture {
                        manager.totalStart()
                    }
                    
                    Image(systemName: "stop").contentShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                        Color.init(id: "activityBar.foreground")
                    ).onTapGesture {
                        manager.totalSuspend()
                    }
                    
                    Image(systemName: "trash").contentShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                        Color.init(id: "activityBar.foreground")
                    ).onTapGesture {  
                        showDeleteAlert = true
                        shouldDeleteCache = false
                    }
                }
            }.padding(.horizontal, 15).padding(.vertical, 8).background(
                Color.init(id: "activityBar.background")
            ).cornerRadius(12).padding(.bottom, 15).padding(.horizontal, 8)
        }.alert("Total Remove?", isPresented: $showDeleteAlert) {
            Button("Total Remove", role: .destructive) {
                manager.totalRemove()
            }
            Button("Total Remove and Delete files", role: .destructive) {
                manager.totalRemove(delete: true)
            }
            Button("Cancel", role: .cancel) {
                
            }
        }
    }
}

struct DownloadCell: View {
    @ObservedObject var task: DownloadTask
    @EnvironmentObject var App: MainApp
    
    var fileName: String {
        if task.status == .succeeded {
            return task.fileName
        }
        
        return task.response?.suggestedFilename ?? task.fileName
    }
    
    var state: (String, Color) {
        switch task.status {
        case .canceled:
            return ("已取消", Color.primary)
        case .removed:
            return ("已删除", Color.primary)
        case .suspended:
            return ("暂停", Color.primary)
        case .running:
            return ("下载中...", Color.blue)
        case .succeeded:
            return ("已完成", Color.green)
        case .failed:
            return ("失败", Color.red)
        case .waiting:
            return ("等待中...", Color.orange)
        
        default:
            return ("", Color.primary)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
                Text("\(Image(systemName: "doc"))\u{2060} \u{2060}\(fileName)"/*.map({ String($0) }).joined(separator: "\u{200B}")*/).font(.subheadline).multilineTextAlignment(.leading)/*.lineLimit(1).truncationMode(.middle)*/
            ProgressView(value: task.status == .succeeded ? 1.0 : Double(task.progress.completedUnitCount), total: task.status == .succeeded  ? 1.0 : Double(max(task.progress.totalUnitCount, 1))).tint(.blue)
                HStack {
                    Text(task.status == .succeeded ? ByteCountFormatter.string(fromByteCount: task.progress.totalUnitCount, countStyle: .file) : "\(ByteCountFormatter.string(fromByteCount: task.progress.completedUnitCount, countStyle: .file))/\(ByteCountFormatter.string(fromByteCount: task.progress.totalUnitCount, countStyle: .file))").font(.system(size: 12)).opacity(0.8)
                    Spacer()
                    
                    if task.status == .running {
                        Text(task.speedString).font(.system(size: 12)).opacity(0.8)
                    } else if task.status == .succeeded {
                        Text("完成").font(.system(size: 12)).foregroundColor(.green).opacity(1)
                    }
                    
                    
                    if task.status == .running {
                        
                        Image(systemName: "pause")
                            .contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture {
                                DownloadManager.instance.suspend(task.url)
                            }
                    }
                    else if task.status == .suspended || task.status == .canceled || task.status == .waiting {
                        
                        Image(systemName: "play")
                            .contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture {
                                DownloadManager.instance.start(task.url)
                            }
                    }
                    else if task.status == .failed {
                        Image(systemName: "memories")
                            .foregroundColor(.red)
                            .contentShape(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                            ).hoverEffect(.highlight).font(.subheadline).foregroundColor(
                                Color.init(id: "activityBar.foreground")
                            ).onTapGesture {
                                DownloadManager.instance.start(task.url)
                            }
                    }
//                    else {
//                        Text(state.0).font(.system(size: 12)).foregroundColor(state.1)
//                    }
                    
                }
            }.padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            .contextMenu(menuItems: {
                if task.status == .succeeded {
                    let url = URL(fileURLWithPath: task.filePath)
                    ForEach(App.extensionManager.fileMenuManager.items) { fitem in
                        if fitem.isVisible(url) {
                            Button(fitem.title, systemImage: fitem.iconSystemName) {
                                fitem.onClick(url)
                            }
                        }
                    }
                    Divider()
                }
                
                
                if task.status == .running {
                    Button("stop", systemImage: "stop") {
                        DownloadManager.instance.suspend(task.url)
                    }
                }
                
                if task.status == .failed ||
                    task.status == .canceled ||
                    task.status == .suspended ||
                    task.status == .waiting  {
                    Button("start", systemImage: "play") {
                        DownloadManager.instance.start(task.url)
                    }
                }
                
                Button("copy url", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = task.url.absoluteString
                }
                
                Button("delete", systemImage: "trash") {
                    DownloadManager.instance.remove(task.url)
                }
                
                Button("delete file", systemImage: "trash") {
                    DownloadManager.instance.remove(task.url, true)
                }
            })
        .onTapGesture {
            
            if task.status == .succeeded {
                App.openFile(url: URL(fileURLWithPath: task.filePath), alwaysInNewTab: true)
            }
        }

        
    }
}
