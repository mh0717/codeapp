//
//  DebugMenu.swift
//  Code
//
//  Created by Ken Chung on 18/11/2022.
//

import SwiftUI

#if PYDEAPP
import pydeCommon
#endif

struct DebugMenu: View {

    @EnvironmentObject var App: MainApp

    var body: some View {
        Section("UI Debug Menu") {
            Button("Regular Notification") {
                App.notificationManager.showErrorMessage("Error")
            }
            Button("Progress Notification") {
                App.notificationManager.postProgressNotification(
                    title: "Progress", progress: Progress())
            }
            Button("Action Notification") {
                App.notificationManager.postActionNotification(
                    title: "Error", level: .error, primary: {},
                    primaryTitle: "primaryTitle", source: "source")
            }
            Button("Async Notification") {
                App.notificationManager.showAsyncNotification(
                    title: "Task Name",
                    task: {
                        try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                    })
            }
            #if PYDEAPP
            Button("大纲") {
                App.popupManager.showCover(content: AnyView(IAPView()))
            }
            
            Button("大纲Sheet") {
                App.popupManager.showSheet(content: AnyView(IAPView()))
            }
            
            Button("copySite") {
                App.notificationManager.showAsyncNotification(title: "copySite...", task: {
                    Task {
                        copySitePackagesToContainer()
                    }
                })
            }
//            Button("pydeUI") {
//                App.popupManager.showCover(content: AnyView(ShareSheet()))
//            }
//            Button("ctags") {
//                Task.init {
//                    if let tags = await testCTagsServiceStart() {
//                        App.notificationManager
//                            .showInformationMessage(tags.map{"\($0.kind):\($0.name)"}.joined(separator: ", "))
//                    }
//                }
//            }
//            Button("histor") {
//                Task.init {
//                    if let commit = try await App.workSpaceStorage.gitServiceProvider?.history() {
//                        App.notificationManager.showInformationMessage("\(try commit.next()?.get().message ?? "")")
//                    }
//                }
//            }
            #endif
        }
    }
}


#if PYDEAPP
struct ShareSheet:UIViewControllerRepresentable{
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let provider = NSItemProvider(item: "run pydeUI" as NSSecureCoding, typeIdentifier: "mh.pydeApp.pydeUI")
        let item = NSExtensionItem()
        item.attributedTitle = NSAttributedString(string: "This is title")
        item.accessibilityLabel = "run pyde ui"
        item.attachments = [provider]
        //你想分享的数据
        let items:[Any] = [item]
        
        let controller = UIActivityViewController(activityItems: items, applicationActivities: /*[CustomUIActicity()]*/nil)
        
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}
#endif
