//
//  EditorAndRunnerView.swift
//  Code
//
//  Created by Huima on 2023/5/24.
//

import Foundation

class EditorAndRunnerView: UIView {
    public let splitView: SplitView
    public let editorView: RSCodeEditorView
    public let consoleView: TMConsoleView
    
    init(root: URL, editor: TextEditorInstance?) {
        splitView = SplitView(frame: .zero)
        editorView = RSCodeEditorView(editor: editor)
        consoleView = TMConsoleView(root: root)
        
        super.init(frame: .zero)
        
        setupView()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("EditorAndRunnerview deinit")
    }
}

extension EditorAndRunnerView {
    func setupView() {
        splitView.firstChild = editorView
        splitView.secondChild = consoleView
        addSubview(splitView)
    }
    
    func setupLayout() {
        splitView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: trailingAnchor),
            splitView.topAnchor.constraint(equalTo: topAnchor),
            splitView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
