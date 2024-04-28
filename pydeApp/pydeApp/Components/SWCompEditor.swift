//
//  SWCompEditor.swift
//  iPyDE
//
//  Created by Huima on 2024/4/28.
//

import Foundation
import ios_system
import SwiftUI

class SWCompEditorInstance: EditorInstanceWithURL {
    init(title: String, url: URL) {
        super.init(view: AnyView(SWCompView(url: url)), title: title, url: url)
    }
}


struct SWCompView :View {
    let url: URL
    @EnvironmentObject var App: MainApp
    
    var body: some View {
        VStack {
            Button("unzip", systemImage: "folder") {
                App.notificationManager.showAsyncNotification(title: "解压缩: \(url.lastPathComponent)\nswcomp zip \(url.path) -e .", task: {
                    let exdir = url.deletingPathExtension()
                    try? FileManager.default.createDirectory(at: exdir, withIntermediateDirectories: true)
                    let newCommand = "swcomp zip \(url.path) -e \(exdir)"
                    ios_switchSession(newCommand)
                    ios_setContext(newCommand)
                    
                    var pid = ios_fork()
                    
                    let returnCode = ios_system("remote \(newCommand)")
                    ios_waitpid(pid)
                    ios_releaseThreadId(pid)
                    
                    if returnCode == 0 {
                        App.notificationManager.showSucessMessage("sucess")
                    } else {
                        App.notificationManager.showErrorMessage("failed")
                    }
                })
            }
        }
    }
}


class SWCompViewerExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {

        let provider = EditorProvider(
            registeredFileExtensions: ["zip", "gzip", "7z"],
            onCreateEditor: { url in
                
                let editorInstance = EditorInstanceWithURL(view: AnyView(SWCompView(url: url).id(UUID())), title: url.lastPathComponent, url: url)

                return editorInstance
            }
        )
        contribution.editorProvider.register(provider: provider)
    }
}
