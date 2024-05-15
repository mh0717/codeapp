//
//  RunParamsExtension.swift
//  Code
//
//  Created by Huima on 2024/5/14.
//

import SwiftUI

class RunParamsExtension: CodeAppExtension {

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let paramsPanel = Panel(
            labelId: "ARGS",
            mainView: AnyView(
                RunParamsView()
            ),
            toolBarView: AnyView(
                HStack(spacing: 12) {
            })
        )
        contribution.panel.registerPanel(panel: paramsPanel)
    }
}


struct RunParamsView: View {
    @EnvironmentObject var App: MainApp
    @ObservedObject var codeThemeManager = rscodeThemeManager
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
    
    @State var lastArgs = ""
    @FocusState private var isFocused: Bool
    
    @State var showPlaceHolder = false
    
    var body: some View {
        TextEditor(text: Binding(get: {
            App.activeUrlEditor?.runArgs ?? ""
        }, set: { value in
            App.activeUrlEditor?.runArgs = value
            if value.isEmpty {
                showPlaceHolder = true
            } else {
                showPlaceHolder = false
            }
        }))
        .background(Color.init(id: "editor.background"))
            .padding(0)
            .focused($isFocused)
            .allowsHitTesting(PYLOCAL_EXECUTION_COMMANDS.keys.contains(App.activeUrlEditor?.url.pathExtension.lowercased() ?? ""))
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .font(.system(size: CGFloat(consoleFontSize)))
            .overlay(alignment: .topLeading, content: {
                Text(showPlaceHolder ? NSLocalizedString("Input run args", comment: "") : "")
                    .font(.system(size: CGFloat(consoleFontSize)))
                    .opacity(0.6)
                    .padding(7)
                    .disabled(true)
                    .allowsHitTesting(false)
            })
            .onAppear {
                if let args = App.activeTextEditor?.runArgs, !args.isEmpty {
                    showPlaceHolder = false
                } else {
                    showPlaceHolder = true
                }
            }
            .onChange(of: isFocused) { isFocused in
                guard let editor = App.activeTextEditor else {return}
                if isFocused {
                    lastArgs = editor.runArgs
                    return
                }
                if lastArgs == editor.runArgs {return}
                
                let fileName = editor.url.lastPathComponent
                let argsName = ".\(fileName).args"
                let argsUrl = editor.url.deletingLastPathComponent().appendingPathComponent(argsName)
                Task {
                    do {
                        guard let argsData = editor.runArgs.data(using: .utf8) else {return}
                        try await App.workSpaceStorage.write(at: argsUrl, content: argsData, atomically: true, overwrite: true)
                    } catch {
                        print(error)
                    }
                    
                }
            }
    }
}

