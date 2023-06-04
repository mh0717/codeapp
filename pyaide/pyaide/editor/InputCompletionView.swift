//
//  InputCompletionView.swift
//  Code
//
//  Created by Huima on 2023/5/22.
//

import Foundation
import InputAssistant
import KeyboardToolbar
import Runestone


protocol InputCompletionViewDelegate: AnyObject {
    func inputCompletionView(_ inputCompletionView: InputCompletionView, didSelectSuggestionAtIndex index: Int)
    func inputCompletionView(_ inputCompletionView: InputCompletionView, didInsertText text: String)
    func inputCompletionViewDidInsertIndent(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewDidRevertIndent(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewRedo(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewUndo(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewCursorBackward(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewCursorForward(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewCursorUpward(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewCursorDownward(_ inputCompletionView: InputCompletionView)
    func inputCompletionViewDidComment(_ inputCompletionView: InputCompletionView)
    func inputCompletionDismissKeyboard(_ inputCompletionView: InputCompletionView)
}

class InputCompletionView: UIView, UIInputViewAudioFeedback, InputAssistantViewDelegate, InputAssistantViewDataSource {
    
    
    
    let keyboardToolbarView = KeyboardToolbarView()
    let completionView = InputAssistantView()
    var currentSuggestionIndex: Int = -1
    private var _completionResult: CompletionResult?
    public var completionResult: CompletionResult? {
        get {
            return _completionResult
        }
    }
    
    public weak var delegate: InputCompletionViewDelegate?
    
    init() {
        super.init(frame: CGRectMake(0, 0, UIScreen.main.bounds.width, 101))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal var keyboardAppearance: UIKeyboardAppearance = .default {
        didSet {
            switch keyboardAppearance {
            case .dark: self.tintColor = .white
            default: self.tintColor = .black
            }
        }
    }
    private var keyboardAppearanceObserver: NSKeyValueObservation?
    
    public func attach(_ textInput: TextView) {
        self.keyboardAppearance = .dark

        // Hide default undo/redo/etc buttons
        textInput.inputAssistantItem.leadingBarButtonGroups = []
        textInput.inputAssistantItem.trailingBarButtonGroups = []

        // Disable built-in autocomplete
        textInput.autocorrectionType = .no

        // Add the input assistant view as an accessory view
        textInput.inputAccessoryView = self

//        keyboardAppearanceObserver = textInput.observe(\TextView.keyboardAppearance) { [weak self] textInput, _ in
//            self?.keyboardAppearance = textInput.keyboardAppearance
//        }
    }
    
    func reloadCompletion(result: CompletionResult?) {
        self._completionResult = result
        self.completionView.reloadData()
    }
}

// MARK: Setup
extension InputCompletionView {
    private func setupView() {
        self.addSubview(completionView)
        self.addSubview(keyboardToolbarView)
        
        weak var wself = self
        func insertHandler(text: String) -> Void {
            if let self = wself {
                self.delegate?.inputCompletionView(self, didInsertText: text)
            }
        }
        
        keyboardToolbarView.groups = [
            // Tools for undoing and redoing text in the text view.
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.backward") { [weak self] in
                    if let self = self {
                        self.delegate?.inputCompletionViewUndo(self)
                    }
                }, isEnabled: true),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.forward") { [weak self] in
                    if let self = self {
                        self.delegate?.inputCompletionViewRedo(self)
                    }
                    
                }, isEnabled: true),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.forward.to.line") { [weak self] in
                    if let self = self {
                        self.delegate?.inputCompletionViewDidInsertIndent(self)
                    }
                    
                }),
            ]),
            // Tools for inserting characters into our text view.
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardToolItem(text: "(", handler: insertHandler), tools: [
                    InsertTextKeyboardToolItem(text: "(", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "{", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "[", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "]", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "}", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: ")", handler: insertHandler)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardToolItem(text: ".", handler: insertHandler), tools: [
                    InsertTextKeyboardToolItem(text: ".", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: ",", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: ";", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "!", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "&", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "|", handler: insertHandler)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardToolItem(text: "=", handler: insertHandler), tools: [
                    InsertTextKeyboardToolItem(text: "=", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "+", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "-", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "/", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "*", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "<", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: ">", handler: insertHandler)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardToolItem(text: "#", handler: insertHandler), tools: [
                    InsertTextKeyboardToolItem(text: "#", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "\"", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "'", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "$", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "\\", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "@", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "%", handler: insertHandler),
                    InsertTextKeyboardToolItem(text: "~", handler: insertHandler)
                ])
            ]),
            KeyboardToolGroup(items: [
                // Tool to present the find navigator.
//                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "magnifyingglass") { [weak self] in
//                    self?.textView.findInteraction?.presentFindNavigator(showingReplace: false)
//                }),
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "arrow.left") { [weak self] in
                        if let self = self {
                            self.delegate?.inputCompletionViewCursorBackward(self)
                        }
                    },
                    tools: [
                        BlockKeyboardTool(symbolName: "arrow.left") { [weak self] in
                            if let self = self {
                                self.delegate?.inputCompletionViewCursorBackward(self)
                            }
                        },
                        BlockKeyboardTool(symbolName: "arrow.up") { [weak self] in
                            if let self = self {
                                self.delegate?.inputCompletionViewCursorUpward(self)
                            }
                        },
                    ]
                ),
                
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "arrow.right") { [weak self] in
                        if let self = self {
                            self.delegate?.inputCompletionViewCursorForward(self)
                        }
                    },
                    tools: [
                        BlockKeyboardTool(symbolName: "arrow.right") { [weak self] in
                            if let self = self {
                                self.delegate?.inputCompletionViewCursorForward(self)
                            }
                        },
                        BlockKeyboardTool(symbolName: "arrow.down") { [weak self] in
                            if let self = self {
                                self.delegate?.inputCompletionViewCursorDownward(self)
                            }
                        },
                    ]
                ),
                
//                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.right") { [weak self] in
//                    if let self = self {
//                        self.delegate?.inputCompletionViewCursorForward(self)
//                    }
//                }),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "keyboard.chevron.compact.down") { [weak self] in
                    if let self = self {
                        self.delegate?.inputCompletionDismissKeyboard(self)
                    }
                })
            ])
        ]
        
        completionView.dataSource = self
        completionView.delegate = self
    }
    
    override func layoutSubviews() {
        keyboardToolbarView.frame = CGRect(x: 0, y: 55, width: bounds.size.width, height: 46)
        completionView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: 55)
    }
}

// MARK: UIInputViewAudioFeedback
extension InputCompletionView {
    var enableInputClicksWhenVisible: Bool { get {true} }
}

// MARK: InputAssistantViewDataSource
extension InputCompletionView {
    func textForEmptySuggestionsInInputAssistantView() -> String?{
        return nil
    }
    
    func numberOfSuggestionsInInputAssistantView() -> Int {
        guard let result = self.completionResult else {
            return 0
        }
        return result.suggestions.count
    }
    
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        guard let result = self.completionResult else {return ""}
        let suffix: String = ((currentSuggestionIndex != -1 && index == 0) ? " ⤶" : "")

        guard result.suggestions.indices.contains(index) else {
            return ""
        }

        if result.suggestions[index].hasSuffix("(") {
            return "()"+suffix
        }

        return result.suggestions[index]+suffix
    }
}

// MARK: InputAssistantViewDelegate
extension InputCompletionView {
    func inputAssistantView(_ inputAssistantView: InputAssistant.InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        delegate?.inputCompletionView(self, didSelectSuggestionAtIndex: index)
    }
}



struct InsertTextKeyboardToolItem: KeyboardTool {
    let displayRepresentation: KeyboardToolDisplayRepresentation

    private let text: String
    private let handler: (String) -> Void

    init(text: String, handler: @escaping (String) -> Void) {
        self.displayRepresentation = .text(text)
        self.text = text
        self.handler = handler
    }

    func performAction() {
        handler(text)
    }
}
