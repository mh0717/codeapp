//
//  RSCodeEditor.swift
//  Code
//
//  Created by Huima on 2023/5/22.
//

import Foundation
import Runestone
import TreeSitterPythonRunestone


class RSCodeEditorView: UIView, InputCompletionViewDelegate, TextViewDelegate {
    
    weak var editor:TextEditorInstance?
    let inputAssistantView:InputCompletionView
    let textView: TextView
    
    init(editor: TextEditorInstance?) {
        
        self.inputAssistantView = InputCompletionView()
        self.textView = TextView()
        self.editor = editor
        
        super.init(frame: .zero)
        
        setupView()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        backgroundColor = UIColor.darkGray
        textView.backgroundColor = UIColor.systemGray6
        
        textView.alwaysBounceVertical = true
        textView.contentInsetAdjustmentBehavior = .always
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.spellCheckingType = .no
        
        textView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        textView.lineSelectionDisplayType = .line
        textView.lineHeightMultiplier = 1.3
        textView.kern = 0.3
        textView.pageGuideColumn = 80
        textView.characterPairs = [
            BasicCharacterPair(leading: "(", trailing: ")"),
            BasicCharacterPair(leading: "{", trailing: "}"),
            BasicCharacterPair(leading: "[", trailing: "]"),
            BasicCharacterPair(leading: "\"", trailing: "\""),
            BasicCharacterPair(leading: "'", trailing: "'"),
            BasicCharacterPair(leading: "\"", trailing: "\"")
        ]
        textView.isEditable = true
        textView.isSelectable = true
        textView.showLineNumbers = true
        
        let theme = DefaultTheme()
        let state = TextViewState(text: self.editor?.content ?? "", theme: theme, language: .python)
        textView.setState(state)
        
        
        textView.inputAccessoryView = inputAssistantView
        textView.editorDelegate = self
        
        inputAssistantView.delegate = self
        inputAssistantView.attach(textView)
        
        addSubview(textView)
    }
    
    private func setupLayout() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func requestDiffUpdate(modelUri: String, force: Bool = false) {
        guard let app = (editor as? PTTextEditorInstance)?.app else {return}
        guard
            let sanitizedUri = URL(string: modelUri)?.standardizedFileURL.absoluteString
                .removingPercentEncoding
        else {
            return
        }

        // If the cache hasn't been invalidated, it means the editor also have the up-to-date model.
        if let isCached = app.workSpaceStorage.gitServiceProvider?.isCached(
            url: sanitizedUri),
            !force, isCached
        {
            return
        }

        if let hasRepo = app.workSpaceStorage.gitServiceProvider?.hasRepository,
            hasRepo
        {
            app.workSpaceStorage.gitServiceProvider?.previous(
                path: sanitizedUri, error: { err in print(err) },
                completionHandler: { value in
//                    DispatchQueue.main.async {
//                        app.monacoInstance.provideOriginalTextForUri(uri: modelUri, value: value)
//                    }
                })
        }
    }
    
    func updateSuggestions(force: Bool = false, getDefinitions: Bool = false) {
        guard self.textView.isEditing, self.textView.selectedRange.length == 0 else {return}
        let location = self.textView.selectedRange.location
        Task.init { [weak self] in
            guard let editor = self?.editor else {return}
            
            //            if let result = await CompletionService.instance.requestCompletion(vid: editor.currentVersionId, path: editor.url.path, index: location), result.vid == editor.currentVersionId {
            //                self.inputAssistantView?.reloadCompletion(result: result)
            //            }
            
            let result = await completeCode(code: editor.content, path: editor.url.path, index: location, getdef: getDefinitions, vid: editor.currentVersionId)
            
            if result?.vid == editor.currentVersionId {
                self?.inputAssistantView.reloadCompletion(result: result)
            }
        }
    }
}

// MARK: InputCompletionViewDelegate
extension RSCodeEditorView {
    func inputCompletionView(_ inputCompletionView: InputCompletionView, didSelectSuggestionAtIndex index: Int) {
        guard let result = self.inputAssistantView.completionResult else {return}
        
        guard result.completions.indices.contains(index), result.suggestions.indices.contains(index) else {
            self.inputAssistantView.currentSuggestionIndex = -1
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

        DispatchQueue.main.async(){ [weak self] in

            guard let self = self else {
                return
            }
            
            let textView = self.textView

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

        self.inputAssistantView.currentSuggestionIndex = -1
    }
    
    func inputCompletionView(_ inputCompletionView: InputCompletionView, didInsertText text: String) {
        self.textView.insertText(text)
    }
    
    func inputCompletionViewDidInsertIndent(_ inputCompletionView: InputCompletionView) {
        self.textView.shiftRight()
    }
    
    func inputCompletionViewDidRevertIndent(_ inputCompletionView: InputCompletionView) {
        self.textView.shiftLeft()
    }
    
    func inputCompletionViewRedo(_ inputCompletionView: InputCompletionView) {
        self.textView.undoManager?.redo()
    }
    
    func inputCompletionViewUndo(_ inputCompletionView: InputCompletionView) {
        self.textView.undoManager?.redo()
    }
    
    func inputCompletionViewCursorBackward(_ inputCompletionView: InputCompletionView) {
        guard let currRange = self.textView.selectedTextRange else {return}
        var backPosition = currRange.start
        if (currRange.isEmpty) {
            backPosition = self.textView.position(from: currRange.start, in: .left, offset: 1) ?? backPosition
        }
        
        guard let backRange = self.textView.textRange(from: backPosition, to: backPosition) else {return}
        self.textView.selectedTextRange = backRange
    }
    
    func inputCompletionViewCursorForward(_ inputCompletionView: InputCompletionView) {
        guard let currRange = self.textView.selectedTextRange else {return}
        var forPosition = currRange.end
        if (currRange.isEmpty) {
            forPosition = self.textView.position(from: currRange.end, in: .right, offset: 1) ?? forPosition
        }
        
        guard let forRange = self.textView.textRange(from: forPosition, to: forPosition) else {return}
        self.textView.selectedTextRange = forRange
    }
    
    func inputCompletionViewCursorUpward(_ inputCompletionView: InputCompletionView) {
        guard let currRange = self.textView.selectedTextRange else {return}
        guard let upPosition = self.textView.position(from: currRange.start, in: .up, offset: 1) else {return}
        guard let upRange = self.textView.textRange(from: upPosition, to: upPosition) else {return}
        self.textView.selectedTextRange = upRange
    }
    
    func inputCompletionViewCursorDownward(_ inputCompletionView: InputCompletionView) {
        guard let currRange = self.textView.selectedTextRange else {return}
        guard let downPosition = self.textView.position(from: currRange.start, in: .down, offset: 1) else {return}
        guard let downRange = self.textView.textRange(from: downPosition, to: downPosition) else {return}
        self.textView.selectedTextRange = downRange
    }
    
    func inputCompletionViewDidComment(_ inputCompletionView: InputCompletionView) {
        
    }
    
    func inputCompletionDismissKeyboard(_ inputCompletionView: InputCompletionView) {
        self.textView.resignFirstResponder()
    }
}

// MARK: TextViewDelegate
extension RSCodeEditorView {
//    func textViewShouldBeginEditing(_ textView: TextView) -> Bool {
//
//    }
//
//    func textViewShouldEndEditing(_ textView: TextView) -> Bool {
//
//    }
    
//    func textViewDidBeginEditing(_ textView: TextView) {
//
//    }
//
//    func textViewDidEndEditing(_ textView: TextView) {
//
//    }
    
    func textViewDidChange(_ textView: TextView) {
        if let editor = editor {
            let version = editor.currentVersionId + 1
            let content = textView.text
            
            editor.currentVersionId = version
            editor.content = content
            
            let modelUri = editor.url.path
            self.requestDiffUpdate(modelUri: modelUri)
            
            (editor as? PTTextEditorInstance)?.app?.saveCurrentFile()
        }
        
        if textView.isEditing {
            self.updateSuggestions()
        }
    }
    
//    func textViewDidChangeSelection(_ textView: TextView) {
//
//    }
    
//    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        
//    }
//
//    func textView(_ textView: TextView, shouldInsert characterPair: CharacterPair, in range: NSRange) -> Bool {
//
//    }
//
//    func textView(_ textView: TextView, shouldSkipTrailingComponentOf characterPair: CharacterPair, in range: NSRange) -> Bool {
//
//    }
//
//    func textViewDidChangeGutterWidth(_ textView: TextView) {
//
//    }
//
//    func textViewDidBeginFloatingCursor(_ textView: TextView) {
//
//    }
//
//    func textViewDidEndFloatingCursor(_ textView: TextView) {
//
//    }
//
//    func textViewDidLoopToLastHighlightedRange(_ textView: TextView) {
//
//    }
//
//    func textViewDidLoopToFirstHighlightedRange(_ textView: TextView) {
//
//    }
//
//    func textView(_ textView: TextView, canReplaceTextIn highlightedRange: HighlightedRange) -> Bool {
//
//    }
//
//    func textView(_ textView: TextView, replaceTextIn highlightedRange: HighlightedRange) {
//
//    }
}


final class BasicCharacterPair: CharacterPair {
    let leading: String
    let trailing: String

    init(leading: String, trailing: String) {
        self.leading = leading
        self.trailing = trailing
    }
}


fileprivate extension TextView {
    
    // MARK: - Words
    
    /// Returns the range of the selected word with underscores.
    var currentWordWithUnderscoreRange: UITextRange? {
        guard var range = currentWordRange else {
            return nil
        }
        
        var text = self.text(in: range) ?? ""
        while !text.isEmpty && ![
            "\t",
            " ",
            "(",
            "[",
            "{",
            "\"",
            "\'",
            "\n",
            ",",
            "."
        ].contains(String(text.first ?? Character(""))) {
            guard let newStart = position(from: range.start, offset: -1), let newPos = textRange(from: newStart, to: range.end) else {
                break
            }
            
            range = newPos
            text = self.text(in: range) ?? ""
        }
        
        if let pos = position(from: range.start, offset: 1), let newRange = textRange(from: pos, to: range.end) {
            range = newRange
        }
        
        return range
    }
    
    /// Returns the range of the selected word.
    var currentWordRange: UITextRange? {
        let beginning = beginningOfDocument
        
        if let start = position(from: beginning, offset: selectedRange.location),
            let end = position(from: start, offset: selectedRange.length) {
            
            let textRange = tokenizer.rangeEnclosingPosition(end, with: .word, inDirection: UITextDirection(rawValue: 1))
            
            return textRange ?? selectedTextRange
        }
        return selectedTextRange
    }
    
    /// Returns the current typed word.
    var currentWord : String? {
        if let textRange = currentWordRange {
            return text(in: textRange)
        } else {
            return nil
        }
    }
    
    /// Returns word in given range.
    ///
    /// - Parameters:
    ///     - range: Range contained by the word.
    ///
    /// - Returns: Word in given range.
    func word(in range: NSRange) -> String? {
        
        var wordRange: UITextRange? {
            let beginning = beginningOfDocument
            
            if let start = position(from: beginning, offset: range.location),
                let end = position(from: start, offset: range.length) {
                
                let textRange = tokenizer.rangeEnclosingPosition(end, with: .word, inDirection: UITextDirection(rawValue: 1))
                
                return textRange ?? selectedTextRange
            }
            return selectedTextRange
        }
        
        if let textRange = wordRange {
            return text(in: textRange)
        }
        
        return nil
    }
    
    // MARK: - Lines
    
    /// Get the entire line range from given range.
    ///
    /// - Parameters:
    ///     - range: The range contained in returned line.
    ///
    /// - Returns: The entire line range.
    func line(at range: NSRange) -> UITextRange? {
        let beginning = beginningOfDocument
        
        if let start = position(from: beginning, offset: range.location),
            let end = position(from: start, offset: range.length) {
            
            let textRange = tokenizer.rangeEnclosingPosition(end, with: .line, inDirection: UITextDirection(rawValue: 1))
            
            return textRange ?? selectedTextRange
        }
        return selectedTextRange
    }
    
    /// Returns the range of the selected line.
    var currentLineRange: UITextRange? {
        return line(at: selectedRange)
    }
    
    /// Returns the current selected line.
    var currentLine : String? {
        if let textRange = currentLineRange {
            return text(in: textRange)
        } else {
            return nil
        }
    }
    
    // MARK: - Other
    
    /// Scrolls to the bottom of the text view.
    func scrollToBottom() {
        let range = NSMakeRange(((text ?? "") as NSString).length - 1, 1)
        scrollRangeToVisible(range)
    }
}
