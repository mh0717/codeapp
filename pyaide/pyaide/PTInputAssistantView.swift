//
//  PTInputAssistant.swift
//  pyaide
//
//  Created by Huima on 2023/5/17.
//

import Foundation
import InputAssistant
import KeyboardToolbar

class PTInputAssistantView: UIInputView, UIInputViewAudioFeedback, InputAssistantViewDelegate, InputAssistantViewDataSource {
    
    let keyboardToolbarView = KeyboardToolbarView()
    let completionView = InputAssistantView()
    var currentSuggestionIndex: Int = -1
    private var _completionResult: CompletionResult?
    public var completionResult: CompletionResult? {
        get {
            return _completionResult
        }
    }
    private weak var textView: UITextView?
    
    public init(textView: UITextView) {
        self.textView = textView
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 101)
        super.init(frame: frame, inputViewStyle: .keyboard)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.addSubview(completionView)
        self.addSubview(keyboardToolbarView)
        
        if let textView = self.textView {
            // Setup our tool groups.
            let canUndo = textView.undoManager?.canUndo ?? false
            let canRedo = textView.undoManager?.canRedo ?? false
            keyboardToolbarView.groups = [
                // Tools for undoing and redoing text in the text view.
                KeyboardToolGroup(items: [
                    KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.backward") { [weak self] in
                        self?.textView?.undoManager?.undo()
    //                    self?.setupKeyboardTools()
                    }, isEnabled: canUndo),
                    KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.forward") { [weak self] in
                        self?.textView?.undoManager?.redo()
    //                    self?.setupKeyboardTools()
                    }, isEnabled: canRedo),
                    KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.forward.to.line") { [weak self] in
                        self?.insertTab()
                    }),
                ]),
                // Tools for inserting characters into our text view.
                KeyboardToolGroup(items: [
                    KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "(", textView: textView), tools: [
                        InsertTextKeyboardTool(text: "(", textView: textView),
                        InsertTextKeyboardTool(text: "{", textView: textView),
                        InsertTextKeyboardTool(text: "[", textView: textView),
                        InsertTextKeyboardTool(text: "]", textView: textView),
                        InsertTextKeyboardTool(text: "}", textView: textView),
                        InsertTextKeyboardTool(text: ")", textView: textView)
                    ]),
                    KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: ".", textView: textView), tools: [
                        InsertTextKeyboardTool(text: ".", textView: textView),
                        InsertTextKeyboardTool(text: ",", textView: textView),
                        InsertTextKeyboardTool(text: ";", textView: textView),
                        InsertTextKeyboardTool(text: "!", textView: textView),
                        InsertTextKeyboardTool(text: "&", textView: textView),
                        InsertTextKeyboardTool(text: "|", textView: textView)
                    ]),
                    KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "=", textView: textView), tools: [
                        InsertTextKeyboardTool(text: "=", textView: textView),
                        InsertTextKeyboardTool(text: "+", textView: textView),
                        InsertTextKeyboardTool(text: "-", textView: textView),
                        InsertTextKeyboardTool(text: "/", textView: textView),
                        InsertTextKeyboardTool(text: "*", textView: textView),
                        InsertTextKeyboardTool(text: "<", textView: textView),
                        InsertTextKeyboardTool(text: ">", textView: textView)
                    ]),
                    KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "#", textView: textView), tools: [
                        InsertTextKeyboardTool(text: "#", textView: textView),
                        InsertTextKeyboardTool(text: "\"", textView: textView),
                        InsertTextKeyboardTool(text: "'", textView: textView),
                        InsertTextKeyboardTool(text: "$", textView: textView),
                        InsertTextKeyboardTool(text: "\\", textView: textView),
                        InsertTextKeyboardTool(text: "@", textView: textView),
                        InsertTextKeyboardTool(text: "%", textView: textView),
                        InsertTextKeyboardTool(text: "~", textView: textView)
                    ])
                ]),
                KeyboardToolGroup(items: [
                    // Tool to present the find navigator.
    //                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "magnifyingglass") { [weak self] in
    //                    self?.textView.findInteraction?.presentFindNavigator(showingReplace: false)
    //                }),
                    
                    // Tool to dismiss the keyboard.
                    KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.left") { [weak self] in
                        guard let textView = self?.textView else {return}
                        let range = textView.selectedRange
                        var newRange = range
                        if (range.length > 0) {
                            newRange.length = 0
                        }
                        else {
                            newRange.location = max(range.location - 1, 0)
                        }
                        textView.selectedRange = newRange
                    }),
                    KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.right") { [weak self] in
                        guard let textView = self?.textView else {return}
                        let range = textView.selectedRange
                        var newRange = range
                        if (range.length > 0) {
                            newRange.length = 0
                            newRange.location = range.upperBound
                        }
                        else {
                            newRange.location = min(range.upperBound + 1, textView.text.count)
                        }
                        textView.selectedRange = newRange
                    }),
                    KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "keyboard.chevron.compact.down") { [weak self] in
                        self?.textView?.resignFirstResponder()
                    })
                ])
            ]
        }
        
//        completionView.leadingActions = [InputAssistantAction(image: UIImage(systemName: "arrow.forward.to.line") ?? UIImage(), target: self, action: #selector(insertTab))]
//        completionView.trailingActions = [InputAssistantAction(image: PTCodeTextView.downArrow, target: textView, action: #selector(textView.resignFirstResponder))]
        
        completionView.dataSource = self
        completionView.delegate = self
        
        
        if let textView = self.textView {
            completionView.attach(to: textView)
            
            textView.inputAccessoryView = self
            textView.reloadInputViews()
        }
    }
    
    override func layoutSubviews() {
        keyboardToolbarView.frame = CGRect(x: 0, y: 55, width: bounds.size.width, height: 46)
        completionView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: 55)
    }
    
    var enableInputClicksWhenVisible: Bool { get {true} }
    
    func reloadCompletion(result: CompletionResult?) {
        self._completionResult = result
        self.completionView.reloadData()
    }
    
    /// Indents current line.
    @objc func insertTab() {
        guard let textView = self.textView else {return}
        if let range = textView.selectedTextRange, let selected = textView.text(in: range) {

            let nsRange = textView.selectedRange

            var lines = [String]()
            for line in selected.components(separatedBy: "\n") {
                lines.append(PTCodeTextView.indentation+line)
            }
            textView.insertText(lines.joined(separator: "\n"))

            textView.selectedRange = NSRange(location: nsRange.location, length: textView.selectedRange.location-nsRange.location)
            if selected.components(separatedBy: "\n").count == 1, let range = textView.selectedTextRange {
                textView.selectedTextRange = textView.textRange(from: range.end, to: range.end)
            }
        } else {
            textView.insertText(PTCodeTextView.indentation)
        }
    }
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        guard let result = self.completionResult else {return}
        guard let textView = self.textView else {return}
        
        guard result.completions.indices.contains(index), result.suggestions.indices.contains(index) else {
            currentSuggestionIndex = -1
            return
        }

        var completion = result.completions[index]
        var suggestion = result.suggestions[index]

        let isFuzzy: Bool
        if completion == "__is_fuzzy__" {
            completion = suggestion
            isFuzzy = true
        } else {
            isFuzzy = false
        }

        var isParam = false

        if suggestion.hasSuffix("=") {
            suggestion.removeLast()
            isParam = true
        }

        if isFuzzy, let wordRange = textView.currentWordWithUnderscoreRange {
            let location = textView.offset(from: textView.beginningOfDocument, to: wordRange.start)
            let length = textView.offset(from: wordRange.start, to: wordRange.end)
            let nsRange = NSRange(location: location, length: length)
            var text = textView.text as NSString
            text = text.replacingCharacters(in: nsRange, with: "") as NSString
            textView.text = text as String

            textView.selectedTextRange = textView.textRange(from: wordRange.start, to: wordRange.start)
        }

        let selectedRange = textView.selectedRange

        let location = selectedRange.location-(suggestion.count-completion.count)
        let length = suggestion.count-completion.count

        /*

         hello_w HELLO_WORLD ORLD

         */

        let iDonTKnowHowToNameThisVariableButItSSomethingWithTheSelectedRangeButFromTheBeginingLikeTheEntireSelectedWordWithUnderscoresIncluded = NSRange(location: location, length: length)

        textView.selectedRange = iDonTKnowHowToNameThisVariableButItSSomethingWithTheSelectedRangeButFromTheBeginingLikeTheEntireSelectedWordWithUnderscoresIncluded

        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { [weak self] in

            guard let self = self, let textView = self.textView else {
                return
            }

            textView.insertText(suggestion)
            if suggestion.hasSuffix("(") {
                let range = textView.selectedRange
                textView.insertText(")")
                textView.selectedRange = range
            }

            if isParam {
                textView.insertText("=")
            }
        }

//        completionsHostingController.view.isHidden = true

        currentSuggestionIndex = -1
    }
    
    func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
    
    func numberOfSuggestionsInInputAssistantView() -> Int {
        guard let result = self.completionResult else {return 0}
        guard let textView = self.textView else {return 0}
        
        if let currentTextRange = textView.selectedTextRange {

            var range = textView.selectedRange

            if range.length > 1 {
                return 0
            }

            if textView.text(in: currentTextRange) == "" {

                range.length += 1

                let word = textView.currentWord?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")

                if word == "\"\"\"" || word == "'''" {
                    return 0
                } else if word?.isEmpty != false {

                    range.location -= 1

                    if let range = range.toTextRange(textInput: textView), [
                        "(",
                        "[",
                        "{"
                    ].contains(textView.text(in: range) ?? "") {
                        return result.suggestions.count
                    } else if let currentLineStart = textView.currentLineRange?.start, let cursor = textView.selectedTextRange?.start, let range = textView.textRange(from: currentLineStart, to: cursor), let text = textView.text(in: range), text.replacingOccurrences(of: " ", with: "").hasSuffix(","), cursor != textView.currentLineRange?.end {
                        return result.suggestions.count
                    } else {
                        return 0
                    }
                }

                range.location -= 1
                if let textRange = range.toTextRange(textInput: textView), let word = textView.word(in: range), let last = word.last, String(last) != textView.text(in: textRange) {
                    return 0
                }
            }
        }
        
        return result.suggestions.count
    }
    
    func inputAssistantView(_ inputAssistantView: InputAssistant.InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
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


struct InsertTextKeyboardTool: KeyboardTool {
    let displayRepresentation: KeyboardToolDisplayRepresentation

    private let text: String
    private weak var textView: UITextInput?

    init(text: String, textView: UITextInput) {
        self.displayRepresentation = .text(text)
        self.text = text
        self.textView = textView
    }

    func performAction() {
        textView?.insertText(text)
    }
}
