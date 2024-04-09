//
//  PYTerminalEditorInstance.swift
//  iPyDE
//
//  Created by Huima on 2024/4/9.
//
import SwiftUI


class PYTerminalEditorInstance: EditorInstance {
    let widget = PYRunnerWidget()
    
    init(_ rootDir: URL) {
        widget.consoleView.resetAndSetNewRootDirectory(url: rootDir)
        super.init(view: AnyView(widget), title: "Terminal")
    }
    
    override func dispose() {
        super.dispose()
        widget.consoleView.kill()
    }
}
