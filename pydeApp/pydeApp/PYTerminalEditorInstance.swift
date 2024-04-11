//
//  PYTerminalEditorInstance.swift
//  iPyDE
//
//  Created by Huima on 2024/4/9.
//
import SwiftUI

private var _terminalCount = 0
class PYTerminalEditorInstance: EditorInstance {
    let widget = PYRunnerWidget()
    
    init(_ rootDir: URL) {
        _terminalCount += 1
        widget.consoleView.resetAndSetNewRootDirectory(url: rootDir)
        super.init(view: AnyView(widget), title: "\(NSLocalizedString("TERMINAL", comment: ""))#\(_terminalCount)")
    }
    
    override func dispose() {
        super.dispose()
        widget.consoleView.kill()
    }
}
