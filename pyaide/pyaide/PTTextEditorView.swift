//
//  PTTextEditorView.swift
//  pyaide
//
//  Created by Huima on 2023/5/10.
//

import Foundation
import KeyboardToolbar



class PTTextEditorView: UIView {
    let label = UILabel(frame: CGRectZero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.numberOfLines = 1024
        addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    /// The font used in the code editor and the console.
    static var font: UIFont {
        get {
            return UserDefaults.standard.font(forKey: "codeFont") ?? DefaultSourceCodeTheme().font
        }
        
        set {
            UserDefaults.standard.set(font: newValue, forKey: "codeFont")
        }
    }
}





import UIKit
import SourceEditor
import SavannaKit
import InputAssistant
import IntentsUI
import SwiftUI
import Highlightr
import AVKit

import Intents
import Dynamic
import InputAssistant

extension NSRange {
    
    func toTextRange(textInput:UITextInput) -> UITextRange? {
        if let rangeStart = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length) {
            return textInput.textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
}


extension UIKeyCommand {
    
    //UIKeyCommand(input: "C", modifierFlags: .control, action: #selector(interrupt), discoverabilityTitle: NSLocalizedString("interrupt", comment: "Description for CTRL+C key command."))
    
    static func command(input: String, modifierFlags: UIKeyModifierFlags, action: Selector, discoverabilityTitle: String?) -> UIKeyCommand {
        return UIKeyCommand(title: discoverabilityTitle ?? "", image: nil, action: action, input: input, modifierFlags: modifierFlags, propertyList: nil, alternates: [], discoverabilityTitle: discoverabilityTitle, attributes: [], state: .off)
    }
}

extension UserDefaults {
    
    /// The `UserDefaults` instance shared with app extensions.
    static var shared: UserDefaults? {
        return UserDefaults(suiteName: "group.pyto")
    }
    
    /// Taken from https://stackoverflow.com/a/41814164/7515957
    func set(font: UIFont, forKey key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: font, requiringSecureCoding: false)
            self.set(data, forKey: key)
        } catch {
            print(error.localizedDescription)
        }
    }

    /// Taken from https://stackoverflow.com/a/41814164/7515957
    func font(forKey key: String) -> UIFont? {
        guard let data = data(forKey: key) else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIFont.self], from: data) as? UIFont
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

@objc extension NSString {
    
    /// Replaces the first occurrence of the given `String` with another `String`.
    ///
    /// - Parameters:
    ///     - string: String to replace.
    ///     - replacement: Replacement of `string`.
    ///
    /// - Returns: This string replacing the first occurrence of `string` with `replacement`.
    @objc func replacingFirstOccurrence(of string: String, with replacement: String) -> String {
        return (self as String).replacingFirstOccurrence(of: string, with: replacement)
    }
}


extension String {
    
    /// Replaces the first occurrence of the given `String` with another `String`.
    ///
    /// - Parameters:
    ///     - string: String to replace.
    ///     - replacement: Replacement of `string`.
    ///     - options: Compare options.
    ///
    /// - Returns: This string replacing the first occurrence of `string` with `replacement`.
    func replacingFirstOccurrence(of string: String, with replacement: String, options: CompareOptions = []) -> String {
        guard let range = self.range(of: string, options: options) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
    
    /// Get string between two strings.
    ///
    /// - Returns: Substring between `from` to `to`:
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    #if MAIN || WIDGET
    /// Returns a `wchar_t` pointer from this String to be used with CPython.
//    var cWchar_t: UnsafeMutablePointer<wchar_t> {
//        return Py_DecodeLocale(cValue, nil)
//    }
    #endif
    
    /// Returns a C pointer to pass this `String` to C functions.
    var cValue: UnsafeMutablePointer<Int8> {
        guard let cString = cString(using: .utf8) else {
            let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 1)
            buffer.pointee = 0
            return buffer
        }
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: cString.count)
        memcpy(buffer, cString, cString.count)
        
        return buffer
    }
    
    /// Taken from https://stackoverflow.com/a/38809531/7515957
    func image() -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        
        #if MAIN
        let color = ConsoleViewController.choosenTheme.sourceCodeTheme.color(for: .plain)
        #else
        let color = UIColor.black
        #endif
        
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 40), .foregroundColor: color])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        return self.compare(otherVersion, options: .numeric)
    }
}

// https://stackoverflow.com/a/40413663/7515957
extension String {
    public func allRanges(
        of aString: String,
        options: String.CompareOptions = [],
        range: Range<String.Index>? = nil,
        locale: Locale? = nil
    ) -> [Range<String.Index>] {
        
        // the slice within which to search
        let slice = (range == nil) ? self[...] : self[range!]
        
        var previousEnd = slice.startIndex
        var ranges = [Range<String.Index>]()
        
        while let r = slice.range(
            of: aString, options: options,
            range: previousEnd ..< slice.endIndex,
            locale: locale
        ) {
            if previousEnd != self.endIndex { // don't increment past the end
                previousEnd = self.index(after: r.lowerBound)
            }
            ranges.append(r)
        }
        
        return ranges
    }
    
    public func allRanges(
        of aString: String,
        options: String.CompareOptions = [],
        range: Range<String.Index>? = nil,
        locale: Locale? = nil
    ) -> [Range<Int>] {
        return allRanges(of: aString, options: options, range: range, locale: locale)
            .map(indexRangeToIntRange)
    }
    
    
    private func indexRangeToIntRange(_ range: Range<String.Index>) -> Range<Int> {
        return indexToInt(range.lowerBound) ..< indexToInt(range.upperBound)
    }
    
    private func indexToInt(_ index: String.Index) -> Int {
        return self.distance(from: self.startIndex, to: index)
    }
}



extension UITextView {
    
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



/// An `UITextView` to be used on the editor.
public class EditorTextView: LineNumberTextView, UITextViewDelegate {
    
    /// Undo.
    @objc func undo() {
        let theDelegate = delegate
        delegate = nil
        undoManager?.undo()
        delegate = theDelegate
    }
    
    /// Redo.
    @objc func redo() {
        let theDelegate = delegate
        delegate = nil
        undoManager?.redo()
        delegate = theDelegate
    }
    
    @objc public override func find(_ sender: Any?) {
//        var next = self.next
//        while !(next is EditorViewController) && next != nil {
//            next = next?.next
//        }
//
//        (next as? EditorViewController)?.search()
    }
        
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(undo) {
            return undoManager?.canUndo ?? false
        } else if action == #selector(redo) {
            return undoManager?.canRedo ?? false
        } else {
            return super.canPerformAction(action, withSender: send)
        }
    }
    
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        
//        if #available(iOS 15.0, *), presses.first?.key?.keyCode == .keyboardTab {
//            var next = self.next
//            while !(next is EditorViewController) && next != nil {
//                next = next?.next
//            }
//
//            guard let editor = next as? EditorViewController else {
//                return super.pressesBegan(presses, with: event)
//            }
//
//            if editor.numberOfSuggestionsInInputAssistantView() != 0 {
//                editor.nextSuggestion()
//                return
//            }
//        }
        
        super.pressesBegan(presses, with: event)
    }
    
    public override var keyCommands: [UIKeyCommand]? {
        
        if #available(iOS 15.0, *) {
            return nil
        }
        
        let undoCommand = UIKeyCommand.command(input: "z", modifierFlags: .command, action: #selector(undo), discoverabilityTitle: NSLocalizedString("menuItems.undo", comment: "The 'Undo' menu item"))
        let redoCommand = UIKeyCommand.command(input: "z", modifierFlags: [.command, .shift], action: #selector(redo), discoverabilityTitle: NSLocalizedString("menuItems.redo", comment: "The 'Redo' menu item"))
        
        var commands = [UIKeyCommand]()
        
        if undoManager?.canUndo == true {
            commands.append(undoCommand)
        }
        
        if undoManager?.canRedo == true {
            commands.append(redoCommand)
        }
        
        return commands
    }
    
    public override var canBecomeFirstResponder: Bool {
        return true
    }
    
    public override func paste(_ sender: Any?) {
        let theDelegate = delegate
        delegate = self
        
        if let range = selectedTextRange, let pasteboard = UIPasteboard.general.string {
            replace(range, withText: pasteboard)
        }
        
        delegate = theDelegate
    }
    
    public override func cut(_ sender: Any?) {
        let theDelegate = delegate
        delegate = self
        
        if let range = selectedTextRange {
            let text = self.text(in: range)
            UIPasteboard.general.string = text
            replace(range, withText: "")
        }
        
        delegate = theDelegate
    }
    
    // Fixes a weird bug while cutting
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "" && range.length > 1 {
            textView.replace(range.toTextRange(textInput: textView) ?? UITextRange(), withText: text)
            return false
        } else {
            return true
        }
    }
}



@objc public class PTCodeTextView: UIView, UITextViewDelegate {
    
    /// Returns string used for indentation
    static var indentation: String {
        get {
            return UserDefaults.standard.string(forKey: "indentation") ?? "    "
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "indentation")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// The font used in the code editor and the console.
    static var font: UIFont {
        get {
            return UserDefaults.standard.font(forKey: "codeFont") ?? DefaultSourceCodeTheme().font
        }
        
        set {
            UserDefaults.standard.set(font: newValue, forKey: "codeFont")
        }
    }
    
    /// A down arrow image for dismissing keyboard.
    static var downArrow: UIImage {
        return UIGraphicsImageRenderer(size: .init(width: 24, height: 24)).image(actions: { context in
         
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 1, y: 7))
            path.addLine(to: CGPoint(x: 11, y: 17))
            path.addLine(to: CGPoint(x: 22, y: 7))
            
            if UITraitCollection.current.userInterfaceStyle == .dark {
                UIColor.white.setStroke()
            } else {
                UIColor.black.setStroke()
            }
            path.lineWidth = 2
            path.stroke()
            
            context.cgContext.addPath(path.cgPath)
            
        }).withRenderingMode(.alwaysOriginal)
    }
    
    /// The text view containing the code.
    let textView: UITextView = {
        let textStorage = CodeAttributedString()
        textStorage.language = "Python"
        
        let textView = EditorTextView(frame: .zero, andTextStorage: textStorage) ?? EditorTextView(frame: .zero)
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return textView
    }()
    
    /// The text storage of the text view.
    var textStorage: CodeAttributedString? {
        return textView.layoutManager.textStorage as? CodeAttributedString
    }
    
    
    /// The line number where an error occurred. If this value is set at `viewDidAppear(_:)`, the error will be shown and the value will be reset to `nil`.
    var lineNumberError: Int?
    
    /// Returns the text of the text view from any thread.
    @objc var text: String {
        
        if Thread.current.isMainThread {
            return textView.text
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            
            var value = ""
            
            DispatchQueue.main.async {
                value = self.text
                semaphore.signal()
            }
            
            semaphore.wait()
            
            return value
        }
    }
    
    weak var editor: TextEditorInstance?
    
    open var edgesForExtendedLayout: UIRectEdge?
    
    private var inputAssistantView: PTInputAssistantView?
    /// Initialize with given document.
    ///
    /// - Parameters:
    ///     - document: The document to be edited.
    init(frame: CGRect, editor: TextEditorInstance) {
        
        super.init(frame: frame)
        
        
        self.editor = editor
        
        self.inputAssistantView = PTInputAssistantView(textView: self.textView)
        self.textView.inputAccessoryView = self.inputAssistantView!
        self.textView.reloadInputViews()
        
        addSubview(textView)
        setup(theme: Themes.first!.value)
        textView.text = editor.content
        textView.delegate = self
        
        if #available(iOS 16.0, *) {
            textView.isFindInteractionEnabled = true
        }

//        NoSuggestionsLabel = {
//            let label = MarqueeLabel(frame: .zero, rate: 100, fadeLength: 1)
//            return label
//        }
//        inputAssistant.dataSource = self
//        inputAssistant.delegate = self
//
        completionsHostingController = UIHostingController(rootView: CompletionsView(manager: codeCompletionManager))
        completionsHostingController.view.isHidden = true
//
////        codeCompletionManager.editor = self
//        codeCompletionManager.didSelectSuggestion = { [weak self] index in
//            self?.inputAssistantView(self!.inputAssistant, didSelectSuggestionAtIndex: index)
//        }

        edgesForExtendedLayout = []

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func layoutSubviews() {
        textView.frame = bounds
        super.layoutSubviews()
    }
    
    // MARK: - Theme
    
    private var lastCSS = ""
    
    /// Setups the View controller interface for given theme.
    ///
    /// - Parameters:
    ///     - theme: The theme to apply.
    func setup(theme: PTTheme) {
        
        textView.isHidden = false
        
        textView.font = PTCodeTextView.font.withSize(CGFloat(ThemeFontSize))
        textStorage?.highlightr.theme.codeFont = textView.font
        
        // SwiftUI
//        parent?.parent?.parent?.view.backgroundColor = theme.sourceCodeTheme.backgroundColor
        
        backgroundColor = theme.sourceCodeTheme.backgroundColor
//        parent?.view.backgroundColor = view.backgroundColor
        
//        let firstChild = (parent as? EditorSplitViewController)?.firstChild
//        let secondChild = (parent as? EditorSplitViewController)?.secondChild
//        firstChild?.view.backgroundColor = view.backgroundColor
//        secondChild?.view.backgroundColor = view.backgroundColor
        
        let highlightrTheme = HighlightrTheme(themeString: theme.css)
        highlightrTheme.setCodeFont(PTCodeTextView.font.withSize(CGFloat(ThemeFontSize)))
        highlightrTheme.themeBackgroundColor = theme.sourceCodeTheme.backgroundColor
        highlightrTheme.themeTextColor = theme.sourceCodeTheme.color(for: .plain)
        
        if lastCSS != theme.css {
            textStorage?.highlightr.theme = highlightrTheme
            textView.textColor = theme.sourceCodeTheme.color(for: .plain)
            textView.backgroundColor = theme.sourceCodeTheme.backgroundColor
        }
        lastCSS = theme.css
        
        if traitCollection.userInterfaceStyle == .dark {
            textView.keyboardAppearance = .dark
        } else {
            textView.keyboardAppearance = theme.keyboardAppearance
        }
        
        let lineNumberText = textView as? LineNumberTextView
        lineNumberText?.lineNumberTextColor = theme.sourceCodeTheme.color(for: .plain).withAlphaComponent(0.5)
        lineNumberText?.lineNumberBackgroundColor = theme.sourceCodeTheme.backgroundColor
        lineNumberText?.lineNumberFont = PTCodeTextView.font.withSize(CGFloat(ThemeFontSize))
        lineNumberText?.lineNumberBorderColor = .clear
        
//        if parent?.superclass?.isSubclass(of: EditorSplitViewController.self) == false {
//            (parent as? EditorSplitViewController)?.separatorColor = theme.sourceCodeTheme.color(for: .plain).withAlphaComponent(0.5)
//        }
    }
    
//    /// Called when the user choosed a theme.
//    @objc func themeDidChange(_ notification: Notification?) {
//        setup(theme: ConsoleViewController.choosenTheme)
//    }
//
//
//
//    public override func viewDidLoad() {
//        super.viewDidLoad()
//
//        completionsHostingController = UIHostingController(rootView: CompletionsView(manager: codeCompletionManager))
//        completionsHostingController.view.isHidden = true
//
//        codeCompletionManager.editor = self
//        codeCompletionManager.didSelectSuggestion = { [weak self] index in
//            self?.inputAssistantView(self!.inputAssistant, didSelectSuggestionAtIndex: index)
//        }
//
//        edgesForExtendedLayout = []
//
//        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(_:)), name: ThemeDidChangeNotification, object: nil)
//        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] (notif) in
//            self?.textView.resignFirstResponder()
//        }
//        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] (notif) in
//            self?.themeDidChange(notif)
//        }
//
//        if #available(iOS 13.0, *) {
//            view.backgroundColor = .systemBackground
//        }
//
//        view.addSubview(textView)
//        textView.delegate = self
//        textView.isHidden = true
//
//        textView.addSubview(completionsHostingController.view)
//
//        if #available(iOS 16.0, *) {
//            textView.isFindInteractionEnabled = true
//        }
//
////        NoSuggestionsLabel = {
////            let label = MarqueeLabel(frame: .zero, rate: 100, fadeLength: 1)
////            return label
////        }
//        inputAssistant.dataSource = self
//        inputAssistant.delegate = self
//
//    }
    
   
    
//    public override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        setup(theme: ConsoleViewController.choosenTheme)
//
//        func openDoc() {
//            guard let doc = self.document else {
//                return
//            }
//
//            let path = doc.fileURL.path
//
//            switch document?.fileURL.pathExtension.lowercased() ?? "" {
//            case "py", "pyi":
//                (textView.textStorage as? CodeAttributedString)?.language = "python"
//                codeCompletionManager.language = .python
//            case "pyx", "pxd", "pxi":
//                (textView.textStorage as? CodeAttributedString)?.language = "cython"
//                codeCompletionManager.language = .cython
//            case "html":
//                (textView.textStorage as? CodeAttributedString)?.language = "html"
//            case "c", "h":
//                (textView.textStorage as? CodeAttributedString)?.language = "c"
//                codeCompletionManager.language = .c
//            case "cpp", "cxx", "cc", "hpp":
//                (textView.textStorage as? CodeAttributedString)?.language = "c++"
//                codeCompletionManager.language = .cpp
//            case "m", "mm":
//                (textView.textStorage as? CodeAttributedString)?.language = "objc"
//                codeCompletionManager.language = .objc
//            default:
//                (textView.textStorage as? CodeAttributedString)?.language = document?.fileURL.pathExtension.lowercased()
//            }
//
//            self.textView.text = document?.text ?? ""
//
//#if !SCREENSHOTS
//            if !FileManager.default.isWritableFile(atPath: doc.fileURL.path) {
//                self.navigationItem.leftBarButtonItem = nil
//                self.textView.contentTextView.isEditable = false
//                self.textView.contentTextView.inputAccessoryView = nil
//            }
//#endif
//
//            if doc.fileURL.path == Bundle.main.path(forResource: "installer", ofType: "py") && (!(parent is REPLViewController) && !(parent is RunModuleViewController) && !(parent is PipInstallerViewController)) {
//                self.parentNavigationItem?.leftBarButtonItems = []
//                if Python.shared.isScriptRunning(path) {
//                    self.parentNavigationItem?.rightBarButtonItems = [self.stopBarButtonItem]
//                } else {
//                    self.parentNavigationItem?.rightBarButtonItems = [self.runBarButtonItem]
//                }
//            }
//        }
//
//        if !isDocOpened {
//
//            parent?.addChild(completionsHostingController)
//            parent?.view.addSubview(completionsHostingController.view)
//
//            isDocOpened = true
//
//            let console = (parent as? EditorSplitViewController)?.console
//
//            for child in console?.children ?? [] {
//                if child is PytoUIPreviewViewController {
//                    child.view.removeFromSuperview()
//                    child.removeFromParent()
//                }
//            }
//
//            if document?.fileURL.pathExtension == "pytoui" {
//                let previewVC = PytoUIPreviewViewController()
//                previewVC.view.frame = console?.view.frame ?? .zero
//                previewVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//                console?.addChild(previewVC)
//                DispatchQueue.main.async {
//                    console?.view.addSubview(previewVC.view)
//                }
//
//                console?.webView.isHidden = true
//                console?.movableTextField?.toolbar.isHidden = true
//                console?.movableTextField?.textField.isHidden = true
//            } else {
//                console?.webView.isHidden = false
//                console?.movableTextField?.toolbar.isHidden = false
//                console?.movableTextField?.textField.isHidden = false
//            }
//
//            if document?.hasBeenOpened != true {
//                document?.open(completionHandler: { (_) in
//                    openDoc()
//                })
//            } else {
//                openDoc()
//            }
//        }
//
//        if shouldRun, let path = document?.fileURL.path {
//            shouldRun = false
//
//            if Python.shared.isScriptRunning(path) {
//                stop()
//            }
//
//            if Python.shared.isScriptRunning(path) || !Python.shared.isSetup {
//                _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
//                    if !Python.shared.isScriptRunning(path) && Python.shared.isSetup {
//                        timer.invalidate()
//                        self?.run()
//                    }
//                })
//            } else {
//                self.run()
//            }
//        }
//
//        setBarItems()
//    }
    
    
    
//    public override var canBecomeFirstResponder: Bool {
//        return true
//    }
//
//    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        if action == #selector(unindent) {
//            return isIndented && textView.isFirstResponder
//        } else if action == #selector(search) || action == #selector(find(_:)) {
//            if #available(iOS 15.0, *) {
//                return true
//            } else {
//                return false
//            }
//        } else {
//            return super.canPerformAction(action, withSender: sender)
//        }
//    }

    private var isIndented: Bool {
        var indented = false
        if let range = textView.selectedTextRange {
            for line in textView.text(in: range)?.components(separatedBy: "\n") ?? [] {
                if line.hasPrefix(PTCodeTextView.indentation) {
                    indented = true
                    break
                }
            }
        }
        if let line = textView.currentLine, line.hasPrefix(PTCodeTextView.indentation) {
            indented = true
        }

        return indented
    }

//    public override var keyCommands: [UIKeyCommand]? {
//        if textView.contentTextView.isFirstResponder {
//            var commands = [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(toggleCompletionsView(_:)), discoverabilityTitle: "\(completionsHostingController?.view.isHidden == false ? "Show" : "Hide") completions")]
//
//            if #available(iOS 15.0, *) {
//            } else {
//                commands.append(contentsOf: [
//                    UIKeyCommand.command(input: "c", modifierFlags: [.command, .shift], action: #selector(toggleComment), discoverabilityTitle: NSLocalizedString("menuItems.toggleComment", comment: "The 'Toggle Comment' menu item")),
//                    UIKeyCommand.command(input: "\t", modifierFlags: [.alternate], action: #selector(unindent), discoverabilityTitle: NSLocalizedString("unindent", comment: "'Unindent' key command"))
//                ])
//            }
//
//            if numberOfSuggestionsInInputAssistantView() != 0 && completionsHostingController.view.isHidden {
//                commands.append(UIKeyCommand.command(input: "\t", modifierFlags: [], action: #selector(nextSuggestion), discoverabilityTitle: NSLocalizedString("nextSuggestion", comment: "Title for command for selecting next suggestion")))
//            }
//
//            return commands
//        } else {
//            return []
//        }
//    }
//
//
//
//    // MARK: - Actions
//
//    private var previousSelectedRange: NSRange?
//
//    private var previousSelectedLine: String?
//
//    @available(iOS 15.0, *)
//    @objc func showSnippets() {
//        previousSelectedRange = textView.selectedRange
//        previousSelectedLine = textView.currentLine
//        let snippetsView = SnippetsView(language: (textView.textStorage as? CodeAttributedString)?.language ?? "python", selectionHandler: { [weak self] codeString in
//
//            var codeLines = [String]()
//
//            if let range = self?.previousSelectedRange {
//                let line = self?.previousSelectedLine ?? ""
//                var indentation = ""
//                for char in line {
//                    let charString = String(char)
//                    if charString != " " && charString == "\t" {
//                        break
//                    }
//                    indentation += charString
//                }
//
//                var firstLine = true
//                for codeLine in codeString.components(separatedBy: "\n") {
//                    guard !firstLine else {
//                        firstLine = false
//                        codeLines.append(codeLine)
//                        continue
//                    }
//
//                    codeLines.append(indentation+codeLine)
//                }
//
//                let _code = self!.textView.text as NSString
//                self?.textView.text = _code.replacingCharacters(in: range, with: codeLines.joined(separator: "\n"))
//                self?.dismiss(animated: true) {
//                    self?.textView.becomeFirstResponder()
//                    self?.textView.selectedRange = NSRange(location: range.location, length: (codeLines.joined(separator: "\n") as NSString).length)
//                }
//            } else {
//
//            }
//        })
//
//        present(UIHostingController(rootView: snippetsView), animated: true)
//    }
//
//    private var definitionsNavVC: UINavigationController?
//
//    @available(iOS 15.0, *)
//    fileprivate struct LinterView: SwiftUI.View {
//
//        class WarningsHolder: ObservableObject {
//
//            var warnings = [Linter.Warning]() {
//                didSet {
//                    objectWillChange.send()
//                }
//            }
//        }
//
//        @ObservedObject var warningsHolder: WarningsHolder
//
//        var fileURL: URL
//
//        var editor: EditorViewController
//
//        var body: some SwiftUI.View {
//            NavigationView {
//                VStack {
//                    if warningsHolder.warnings.count > 0 {
//                        List {
//                            Linter(editor: editor, fileURL: fileURL, code: editor.textView.text, warnings: warningsHolder.warnings, showCode: true, language: fileURL.pathExtension.lowercased() == "py" ? "python" : "objc")
//                        }
//                    } else {
//                        Spacer()
//                        Text("No errors or warnings").foregroundColor(.secondary)
//                        Spacer()
//                    }
//                }
//                    .navigationTitle("Linter")
//                    .toolbar {
//                        Button {
//                            editor.dismiss(animated: true)
//                        } label: {
//                            Text("Done").bold()
//                        }
//                    }
//                    .navigationBarHidden(editor.traitCollection.horizontalSizeClass == .regular)
//            }.navigationViewStyle(.stack)
//        }
//    }
//
//    var warningsHolder: Any?
//
//    var linterVC: UIViewController?
//
//    @objc func showLinter() {
//
//        guard #available(iOS 15.0, *), let fileURL = document?.fileURL else {
//            return
//        }
//
//        if warningsHolder == nil {
//            warningsHolder = LinterView.WarningsHolder()
//        }
//
//        lint()
//
//        let linter = LinterView(warningsHolder: warningsHolder as! LinterView.WarningsHolder, fileURL: fileURL, editor: self)
//
//        linterVC = UIHostingController(rootView: linter)
//    }
//
//    /// Shows function definitions.
//    @objc func showDefintions(_ sender: Any) {
//        var navVC: UINavigationController! = definitionsNavVC
//
//        updateSuggestions(getDefinitions: true)
//
//        if navVC == nil {
//            let view = DefinitionsView(defintions: definitionsList, handler: { (def) in
//                navVC.dismiss(animated: true) {
//
//                    var lines = [NSRange]()
//
//                    let textView = self.textView.contentTextView
//                    let text = NSString(string: textView.text)
//                    text.enumerateSubstrings(in: text.range(of: text as String), options: .byLines) { (_, range, _, _) in
//                        lines.append(range)
//                    }
//
//                    if lines.indices.contains(def.line-1), textView.contentSize.height > textView.frame.height {
//                        let substringRange = lines[def.line-1]
//                        let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: substringRange, actualCharacterRange: nil)
//                        let rect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
//                        let topTextInset = textView.textContainerInset.top
//                        let contentOffset = CGPoint(x: 0, y: topTextInset + rect.origin.y)
//                        if textView.contentSize.height-contentOffset.y > textView.frame.height {
//                            textView.setContentOffset(contentOffset, animated: true)
//                        } else {
//                            textView.scrollToBottom()
//                        }
//                    }
//
//                    if lines.indices.contains(def.line-1) {
//                        textView.becomeFirstResponder()
//                        textView.selectedRange = lines[def.line-1]
//                    }
//                }
//            }) {
//                navVC.dismiss(animated: true, completion: nil)
//            }
//
//            navVC = UINavigationController(rootViewController: UIHostingController(rootView: view))
//            navVC.navigationBar.prefersLargeTitles = true
//            navVC.modalPresentationStyle = .popover
//        }
//
//        navVC.popoverPresentationController?.barButtonItem = definitionsItem
//        definitionsNavVC = navVC
//
//        navVC.isNavigationBarHidden = traitCollection.horizontalSizeClass == .regular
//
//        present(navVC, animated: true, completion: nil)
//    }
//
//    /// Shares the current script.
//    @objc func share(_ sender: UIBarButtonItem) {
//        let activityVC = UIActivityViewController(activityItems: [document?.fileURL as Any], applicationActivities: nil)
//        activityVC.popoverPresentationController?.barButtonItem = sender
//        present(activityVC, animated: true, completion: nil)
//    }
//
//    /// Opens an alert for setting arguments passed to the script.
//    ///
//    /// - Parameters:
//    ///     - sender: The sender object. If called programatically with `sender` set to `true`, will run code after setting arguments.
//    @objc func setArgs(_ sender: Any) {
//
//        let alert = UIAlertController(title: NSLocalizedString("argumentsAlert.title", comment: "Title of the alert for setting arguments"), message: NSLocalizedString("argumentsAlert.message", comment: "Message of the alert for setting arguments"), preferredStyle: .alert)
//
//        var textField: UITextField?
//
//        alert.addTextField { (textField_) in
//            textField = textField_
//            textField_.text = self.args
//        }
//
//        if (sender as? Bool) == true {
//            alert.addAction(UIAlertAction(title: NSLocalizedString("menuItems.run", comment: "The 'Run' menu item"), style: .default, handler: { _ in
//
//                if let text = textField?.text {
//                    self.args = text
//                }
//
//                self.run()
//
//            }))
//        } else {
//            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "'Ok' button"), style: .default, handler: { _ in
//
//                if let text = textField?.text {
//                    self.args = text
//                }
//
//            }))
//        }
//
//        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "'Cancel' button"), style: .cancel, handler: nil))
//
//        present(alert, animated: true, completion: nil)
//    }
//
//    /// Sets current directory.
//    @objc func setCwd(_ sender: Any) {
//
//        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
//        picker.delegate = self
//        if #available(iOS 13.0, *) {
//            picker.directoryURL = self.currentDirectory
//        } else {
//            picker.allowsMultipleSelection = true
//        }
//        self.present(picker, animated: true, completion: nil)
//    }
//
//    /// Stops the current running script.
//    @objc func stop() {
//
//        guard let path = document?.fileURL.path else {
//            return
//        }
//
//        for console in ConsoleViewController.visibles {
//            func stop_() {
//                Python.shared.stop(script: path)
//            }
//
//            if console.presentedViewController != nil {
//                console.dismiss(animated: true) {
//                    stop_()
//                }
//            } else {
//                stop_()
//            }
//        }
//    }
//
//    /// Debugs script.
//    @objc func debug() {
//        save { [weak self] _ in
//            guard let self = self else {
//                return
//            }
//
//            self.showDebugger(filePath: self.lastBreakpointFilePath, lineno: self.lastBreakpointLineno, tracebackJSON: self.lastTracebackJSON, id: self.lastBreakpointID)
//        }
//    }
//
//    private class DebuggerHostingController: UIHostingController<AnyView> {}
//
//    static let didTriggerBreakpointNotificationName = Notification.Name("DidTriggerBreakpointNotification")
//
//    static let didUpdateBarItemsNotificationName = Notification.Name("DidUpdateBarItemsNotification")
//
//    private var lastBreakpointFilePath: String?
//
//    private var lastBreakpointLineno: Int?
//
//    private var lastBreakpointID: String?
//
//    private var lastTracebackJSON: String?
//
//    func showDebugger(filePath: String?, lineno: Int?, tracebackJSON: String?, id: String?) {
//        let vc: DebuggerHostingController
//        if #available(iOS 15.0, *) {
//
//            let runningBreakpoint: Breakpoint?
//            if let filePath = filePath, let lineno = lineno, let json = tracebackJSON {
//                lastBreakpointFilePath = filePath
//                lastBreakpointLineno = lineno
//                lastTracebackJSON = json
//                runningBreakpoint = try? Breakpoint(url: URL(fileURLWithPath: filePath), lineno: lineno)
//            } else {
//                runningBreakpoint = nil
//            }
//
//            guard !(presentedViewController is DebuggerHostingController) else {
//                NotificationCenter.default.post(name: Self.didTriggerBreakpointNotificationName, object: runningBreakpoint, userInfo: ["id": id ?? "", "traceback": tracebackJSON ?? ""])
//                return
//            }
//
//            vc = DebuggerHostingController(rootView: AnyView(BreakpointsView(fileURL: document!.fileURL, id: id, run: {
//                self.runScript(debug: true)
//            }, runningBreakpoint: runningBreakpoint, tracebackJSON: tracebackJSON).environment(\.editor, self)))
//        } else {
//            vc = DebuggerHostingController(rootView: AnyView(Text("The debugger requires iOS / iPadOS 15+.")))
//        }
//
//        if #available(iOS 15.0, *) {
//            vc.sheetPresentationController?.prefersGrabberVisible = true
//        }
//        present(vc, animated: true, completion: nil)
//    }
//
//
//
//    private func makeDocsIfNeeded() {
//        if documentationNavigationController == nil || documentationNavigationController?.viewControllers.count == 0 {
//            documentationNavigationController = UINavigationController(rootViewController: DocumentationViewController())
//            let docVC = documentationNavigationController?.viewControllers.first as? DocumentationViewController
//            docVC?.editor = self
//            docVC?.loadViewIfNeeded()
//        }
//    }
//
//    /// Shows documentation
//    @objc func showDocs(_ sender: Any) {
//
//        guard presentedViewController == nil else {
//            return
//        }
//
//        makeDocsIfNeeded()
//        documentationNavigationController?.view.backgroundColor = .systemBackground
//        present(documentationNavigationController!, animated: true, completion: nil)
//    }

    /// Indents current line.
    @objc func insertTab() {
        if let range = textView.selectedTextRange, let selected = textView.text(in: range) {

            let nsRange = textView.selectedRange

            /*
             location: 3
             length: 37

             location: ~40
             length: 0

                .
             ->     print("Hello World")
                    print("Foo Bar")| selected
                               - 37
             */

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

    /// Unindent current line
    @objc func unindent() {
        if let range = textView.selectedTextRange, let selected = textView.text(in: range), selected.components(separatedBy: "\n").count > 1 {

            let nsRange = textView.selectedRange

            var lines = [String]()
            for line in selected.components(separatedBy: "\n") {
                lines.append(line.replacingFirstOccurrence(of: PTCodeTextView.indentation, with: ""))
            }

            textView.replace(range, withText: lines.joined(separator: "\n"))

            textView.selectedRange = NSRange(location: nsRange.location, length: textView.selectedRange.location-nsRange.location)
        } else if let range = textView.currentLineRange, let text = textView.text(in: range) {
            let newRange = textView.textRange(from: range.start, to: range.start)
            textView.replace(range, withText: text.replacingFirstOccurrence(of: PTCodeTextView.indentation, with: ""))
            textView.selectedTextRange = newRange
        }
    }

//    /// Comments / Uncomments line.
//    @objc func toggleComment() {
//
//        guard let selected = textView.contentTextView.selectedTextRange else {
//            return
//        }
//
//        if (textView.contentTextView.text(in: selected)?.components(separatedBy: "\n").count ?? 0) > 1 { // Multiple lines
//            guard let line = textView.contentTextView.selectedTextRange else {
//                return
//            }
//
//            guard let text = textView.contentTextView.text(in: line) else {
//                return
//            }
//
//            var newText = [String]()
//
//            for line in text.components(separatedBy: "\n") {
//                let _line = line.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")
//                if _line == "" {
//                    newText.append(line)
//                } else if _line.hasPrefix("#") {
//                    newText.append(line.replacingFirstOccurrence(of: "#", with: ""))
//                } else {
//                    newText.append("#"+line)
//                }
//            }
//
//            textView.contentTextView.replace(line, withText: newText.joined(separator: "\n"))
//        } else { // Current line
//            guard var line = textView.contentTextView.currentLine else {
//                return
//            }
//
//            let currentLine = line
//
//            line = line.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")
//
//            if line.hasPrefix("#") {
//                line = currentLine.replacingFirstOccurrence(of: "#", with: "")
//            } else {
//                line = "#"+currentLine
//            }
//            if let lineRange = textView.contentTextView.currentLineRange {
//                let location = textView.offset(from: textView.beginningOfDocument, to: lineRange.start)
//                let length = textView.offset(from: lineRange.start, to: lineRange.end)
//
//                textView.text = (textView.text as NSString).replacingCharacters(in: NSRange(location: location, length: length), with: line)
//            }
//        }
//    }
//
//    /// Undo.
//    @objc func undo() {
//        (textView as? EditorTextView)?.undo()
//    }
//
//    /// Redo.
//    @objc func redo() {
//        (textView as? EditorTextView)?.redo()
//    }
//
//    /// Shows runtime settings.
//    @objc func showRuntimeSettings(_ sender: Any) {
//
//        guard let navVC = UIStoryboard(name: "ScriptSettingsViewController", bundle: Bundle.main).instantiateInitialViewController() as? UINavigationController else {
//            return
//        }
//
//        guard let vc = navVC.viewControllers.first as? ScriptSettingsViewController else {
//            return
//        }
//
//        vc.editor = self
//
//        navVC.modalPresentationStyle = .formSheet
//        navVC.preferredContentSize = CGSize(width: 480, height: 640)
//
//        present(navVC, animated: true, completion: nil)
//    }
//
//    // MARK: - Breakpoints
//
//    /// The current breakpoint. An array containing the file path and the line number
//    @objc static func setCurrentBreakpoint(_ currentBreakpoint: NSArray?, tracebackJSON: String?, id: String, scriptPath: String?) {
//        DispatchQueue.main.async {
//            for console in ConsoleViewController.visibles {
//                guard let editor = console.editorSplitViewController?.editor else {
//                    continue
//                }
//
//                guard editor.document?.fileURL.path == scriptPath || scriptPath == nil else {
//                    continue
//                }
//
//                guard currentBreakpoint != nil else {
//                    editor.lastBreakpointFilePath = nil
//                    editor.lastBreakpointLineno = nil
//                    editor.lastBreakpointID = nil
//                    editor.lastTracebackJSON = nil
//                    return NotificationCenter.default.post(name: Self.didTriggerBreakpointNotificationName, object: nil, userInfo: [:])
//                }
//
//                guard currentBreakpoint!.count == 2 else {
//                    continue
//                }
//
//                guard let filePath = currentBreakpoint![0] as? String, let lineno = currentBreakpoint![1] as? Int else {
//                    continue
//                }
//
//                guard FileManager.default.fileExists(atPath: filePath) else {
//                    continue
//                }
//
//                guard BreakpointsStore.breakpoints(for: editor.document!.fileURL).contains(where: { $0.url?.path == filePath && $0.lineno == lineno }) else {
//                    continue
//                }
//
//                editor.lastBreakpointFilePath = filePath
//                editor.lastBreakpointLineno = lineno
//                editor.lastBreakpointID = id
//                editor.lastTracebackJSON = tracebackJSON
//                editor.showDebugger(filePath: filePath, lineno: lineno, tracebackJSON: tracebackJSON, id: id)
//
//                break
//            }
//        }
//    }
//
//    // MARK: - Keyboard
//
//    private var previousConstraintValue: CGFloat?
//
//    @objc func keyboardDidShow(_ notification:Notification) {
//    }
//
//    @objc func keyboardWillHide(_ notification:Notification) {
//        if EditorSplitViewController.shouldShowConsoleAtBottom, var previousConstraintValue = previousConstraintValue {
//
//            if previousConstraintValue == view.window?.frame.height {
//                previousConstraintValue = previousConstraintValue/2
//            }
//
//            let splitVC = parent as? EditorSplitViewController
//            let constraint = (splitVC?.firstViewHeightRatioConstraint?.isActive == true) ? splitVC?.firstViewHeightRatioConstraint : splitVC?.firstViewHeightConstraint
//
//            constraint?.constant = previousConstraintValue
//            self.previousConstraintValue = nil
//        }
//    }
//
//    @objc func keyboardWillShow(_ notification:Notification) {
//        guard let height = (notification.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect)?.height, height > 100 else { // Only software keyboard
//            return
//        }
//
//        let splitVC = parent as? EditorSplitViewController
//
//        if EditorSplitViewController.shouldShowConsoleAtBottom && textView.isFirstResponder {
//
//            splitVC?.firstViewHeightRatioConstraint?.isActive = false
//            let constraint = (splitVC?.firstViewHeightRatioConstraint?.isActive == true) ? splitVC?.firstViewHeightRatioConstraint : splitVC?.firstViewHeightConstraint
//
//            guard constraint?.constant != 0 else {
//                return
//            }
//
//            previousConstraintValue = constraint?.constant
//            constraint?.constant = parent?.view?.frame.height ?? 0
//        }
//    }
//
//    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
//        guard !completionsHostingController.view.isHidden, completions != [""], !codeCompletionManager.isDocStringExpanded else {
//            return super.pressesBegan(presses, with: event)
//        }
//
//        switch presses.first?.key?.keyCode {
//        case .keyboardUpArrow:
//            codeCompletionManager.selectedIndex -= 1
//        case .keyboardDownArrow:
//            codeCompletionManager.selectedIndex += 1
//        default:
//            super.pressesBegan(presses, with: event)
//        }
//    }
//
//    // MARK: - Text view delegate
//
//    /// Taken from https://stackoverflow.com/a/52515645/7515957.
//    private func characterBeforeCursor() -> String? {
//        // get the cursor position
//        if let cursorRange = textView.contentTextView.selectedTextRange {
//            // get the position one character before the cursor start position
//            if let newPosition = textView.contentTextView.position(from: cursorRange.start, offset: -1) {
//                let range = textView.contentTextView.textRange(from: newPosition, to: cursorRange.start)
//                return textView.contentTextView.text(in: range!)
//            }
//        }
//        return nil
//    }
//
//    /// Taken from https://stackoverflow.com/a/52515645/7515957.
//    private func characterAfterCursor() -> String? {
//        // get the cursor position
//        if let cursorRange = textView.contentTextView.selectedTextRange {
//            // get the position one character before the cursor start position
//            if let newPosition = textView.contentTextView.position(from: cursorRange.start, offset: 1) {
//                let range = textView.contentTextView.textRange(from: newPosition, to: cursorRange.start)
//                return textView.contentTextView.text(in: range!)
//            }
//        }
//        return nil
//    }
//
//    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        for console in ConsoleViewController.visibles {
//            if console.movableTextField?.textField.isFirstResponder == false {
//                continue
//            } else {
//                console.movableTextField?.textField.resignFirstResponder()
//                return false
//            }
//        }
//        return true
//    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        
//        if textView.isFirstResponder {
//            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
//                self.updateSuggestions()
//            }
//        }
    }

//    @objc static var linterCode: String?
//
//    @objc static func setWarnings(_ warnings: String, scriptPath: String) {
//        guard #available(iOS 15.0, *) else {
//            return
//        }
//
//        DispatchQueue.main.async {
//            for console in ConsoleViewController.visibles {
//                guard let editor = console.editorSplitViewController?.editor else {
//                    continue
//                }
//
//                guard editor.document?.fileURL.path == scriptPath else {
//                    continue
//                }
//
//                editor.warnings = Linter.warnings(pylintOutput: warnings)
//            }
//        }
//    }
//
//    @objc func lint() {
//        guard #available(iOS 15.0, *) else {
//            return
//        }
//
//        if document?.fileURL.pathExtension.lowercased() == "py" {
//            Self.linterCode = textView.text
//            Python.shared.run(code: """
//            try:
//                import io
//                import sys
//                import traceback
//                import threading
//                import console
//
//                from astroid import MANAGER
//                #MANAGER.astroid_cache.clear()
//
//                #console.__clear_mods__()
//
//                script_path = "\(document!.fileURL.path.replacingOccurrences(of: "\"", with: "\\\""))"
//                threading.current_thread().script_path = "/linter.py"
//
//                import multiprocessing
//                import configparser
//                import optparse
//                import getopt
//
//                from pylint import lint
//                from pylint.reporters import text
//
//                from pyto import EditorViewController
//
//                class Input(io.BytesIO):
//
//                    def detach(self):
//                        return self
//
//                if hasattr(sys, "sys") and hasattr(sys.sys.path, "path"):
//                    path = list(sys.sys.path.path)
//                else:
//                    path = sys.path
//
//                try:
//                    sys.path = sys.path.path
//                except AttributeError:
//                    pass
//
//                output = io.StringIO()
//                stdin = Input(str(EditorViewController.linterCode).encode("utf-8"))
//
//                _stdin = sys.stdin
//                sys.stdin = stdin
//                sys.__stdin__ = stdin
//
//                try:
//                    args = ["-E", "--from-stdin", script_path]
//
//                    reporter = text.TextReporter(output)
//
//                    lint.Run(args, reporter=reporter, exit=False)
//                except (Exception, SystemExit, KeyboardInterrupt):
//                    pass
//                finally:
//                    sys.stdin = _stdin
//                    sys.__stdin__ = _stdin
//
//                res = output.getvalue()
//                EditorViewController.setWarnings(res, scriptPath=script_path)
//            except Exception:
//                pass
//            """)
//        } else if let url = document?.fileURL, ["c", "cpp", "cxx", "cc", "h", "hpp", "m", "mm"].contains(url.pathExtension.lowercased()) {
//
////            DispatchQueue.global().async {
////                lintCSource(url: url, textView: self.textView) { warnings in
////                    self.warnings = warnings
////                }
////            }
//        }
//    }
    
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

    public func textViewDidChange(_ textView: UITextView) {
        if let editor = editor {
            let version = editor.currentVersionId + 1
            let content = textView.text
            
            editor.currentVersionId = version
            editor.content = content ?? ""
            
            let modelUri = editor.url.path
            self.requestDiffUpdate(modelUri: modelUri)
            
            (editor as? PTTextEditorInstance)?.app?.saveCurrentFile()
        }
        
        if textView.isFirstResponder {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                self.updateSuggestions()
            }
        }
        

//        let startOffset = result["startOffset"] as! Int
//        let endOffset = result["endOffset"] as! Int
//        if control.editorSpellCheckEnabled && control.editorSpellCheckOnContentChanged {
//            control.checkSpelling(
//                text: content, uri: modelUri, startOffset: startOffset, endOffset: endOffset
//            )
//        }
        
        
        
        
        
        
        
        
        
        

//        #if MAIN
//        setHasUnsavedChanges(textView.text != document?.text)
//        #endif
//
//        let text = textView.text ?? ""
//        EditorViewController.isCompleting = true
//        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
//            if textView.text == text {
//                EditorViewController.isCompleting = false
//            }
//        }
//
//        if #available(iOS 13.0, *) {
//            for scene in UIApplication.shared.connectedScenes {
//
//                guard scene != view.window?.windowScene else {
//                    continue
//                }
//
//                let editor = ((scene.delegate as? SceneDelegate)?.sidebarSplitViewController?.sidebar?.editor?.vc as? EditorSplitViewController)?.editor
//
//                guard editor?.textView.text != textView.text, editor?.document?.fileURL.path == document?.fileURL.path else {
//                    continue
//                }
//
//                editor?.textView.text = textView.text
//            }
//        }
//
//        if document?.fileURL.pathExtension == "pytoui" {
//            for child in (parent as? EditorSplitViewController)?.console?.children ?? [] {
//                (child as? PytoUIPreviewViewController)?.preview(self)
//            }
//        }
    }


    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        docString = nil

        if text == "\n", let inputAssistantView = self.inputAssistantView, inputAssistantView.currentSuggestionIndex != -1, completionsHostingController.view.isHidden {
            inputAssistantView.inputAssistantView(inputAssistantView.completionView, didSelectSuggestionAtIndex: inputAssistantView.currentSuggestionIndex)
            return false
        }

//        if text == "\n", !completionsHostingController.view.isHidden, codeCompletionManager.completions.indices.contains(codeCompletionManager.selectedIndex) {
//            if codeCompletionManager.completions[codeCompletionManager.selectedIndex].isEmpty || codeCompletionManager.isDocStringExpanded {
//                completionsHostingController.view.isHidden = true
//            } else {
//                inputAssistantView(inputAssistant, didSelectSuggestionAtIndex: codeCompletionManager.selectedIndex)
//                return false
//            }
//        }
//
//        // Delete new line
//        if (textView.text as NSString).substring(with: range) == "\n" {
//            let regex = try! NSRegularExpression(pattern: "\n", options: [])
//            let lineNumber = regex.numberOfMatches(in: textView.text, options: [], range: NSMakeRange(0, textView.selectedRange.location)) + 1
//
//            // Move breakpoints
//            var breakpoints = [Breakpoint]()
//            for breakpoint in BreakpointsStore.breakpoints(for: document!.fileURL) {
//                if breakpoint.url == document?.fileURL && breakpoint.lineno > lineNumber {
//
//                    do {
//                        breakpoints.append(try Breakpoint(url: breakpoint.url!, lineno: breakpoint.lineno-1, isEnabled: breakpoint.isEnabled))
//                    } catch {
//                        breakpoints.append(breakpoint)
//                    }
//                } else {
//                    breakpoints.append(breakpoint)
//                }
//            }
//
//            BreakpointsStore.set(breakpoints: breakpoints, for: document!.fileURL)
//        }

        if text == "" && range.length == 1, PTCodeTextView.indentation != "\t" { // Un-indent
            var _range = range
            var rangeToDelete = range

            var i = 0
            while true {
                if (_range.location+_range.length <= (textView.text as NSString).length) && _range.location >= 1 && (textView.text as NSString).substring(with: _range) == " " {
                    rangeToDelete = NSRange(location: _range.location, length: i)
                    _range = NSRange(location: _range.location-1, length: _range.length)
                    i += 1

                    if i > PTCodeTextView.indentation.count {
                        break
                    }
                } else {
                    let oneMoreSpace = NSRange(location: rangeToDelete.location, length: rangeToDelete.length+1)
                    if NSMaxRange(oneMoreSpace) <= (textView.text as NSString).length, (textView.text as NSString).substring(with: oneMoreSpace) == PTCodeTextView.indentation {
                        rangeToDelete = oneMoreSpace
                    }
                    break
                }
            }

            if i < PTCodeTextView.indentation.count {
                return true
            }

            var indentation = ""
            var line = textView.currentLine ?? ""
            while line.hasPrefix(" ") {
                indentation += " "
                line.removeFirst()
            }
            if (indentation.count % PTCodeTextView.indentation.count) != 0 {
                return true // Not correctly indented, just remove the space
            }

            let nextChar = (textView.text as NSString).substring(with: _range)
            if nextChar != "\n" && nextChar != " " {
                return true
            }

            if let nsRange = rangeToDelete.toTextRange(textInput: textView) {
                textView.replace(nsRange, withText: "")

                let nextChar = NSRange(location: textView.selectedRange.location, length: 1)
                if NSMaxRange(nextChar) <= (textView.text as NSString).length, (textView.text as NSString).substring(with: nextChar) == " " {
                    textView.selectedTextRange = NSRange(location: nextChar.location+1, length: 0).toTextRange(textInput: textView)
                }

                return false
            }
        }

        if text == "\t" {
            if let textRange = range.toTextRange(textInput: textView) {
                if let selected = textView.text(in: textRange) {

                    let nsRange = textView.selectedRange

                    var lines = [String]()
                    for line in selected.components(separatedBy: "\n") {
                        lines.append(PTCodeTextView.indentation+line)
                    }
                    textView.replace(textRange, withText: lines.joined(separator: "\n"))

                    textView.selectedRange = NSRange(location: nsRange.location, length: textView.selectedRange.location-nsRange.location)
                    if selected.components(separatedBy: "\n").count == 1, let range = textView.selectedTextRange {
                        textView.selectedTextRange = textView.textRange(from: range.end, to: range.end)
                    }
                }
                return false
            }
        }

        // Close parentheses and brackets.
        let completable: [(String, String)] = [
            ("(", ")"),
            ("[", "]"),
            ("{", "}"),
            ("\"", "\""),
            ("'", "'")
        ]

        for chars in completable {
            if text == chars.1 {
                let range = textView.selectedRange
                let nextCharRange = NSRange(location: range.location, length: 1)
                let nsText = NSString(string: textView.text)

                if nsText.length > nextCharRange.location, nsText.substring(with: nextCharRange) == chars.1 {
                    textView.selectedTextRange = NSRange(location: range.location+1, length: 0).toTextRange(textInput: textView)
                    return false
                }
            }

            if (chars == ("\"", "\"") && text == "\"") || (chars == ("'", "'") && text == "'") {
                let range = textView.selectedRange
                let previousCharRange = NSRange(location: range.location-1, length: 1)
                let nsText = NSString(string: textView.text)
                if nsText.length > previousCharRange.location, nsText.substring(with: previousCharRange) == chars.1 {
                    return true
                }
            }

            if text == chars.0 {

                let range = textView.selectedRange
                let nextCharRange = NSRange(location: range.location, length: 1)
                let nsText = NSString(string: textView.text)
                if nsText.length > nextCharRange.location, !((completable+[(" ", " "), ("\t", "\t"), ("\n", "\n")]).contains(where: { (chars) -> Bool in
                    return nsText.substring(with: nextCharRange) == chars.1
                })) {
                    return true
                } else {
                    textView.insertText(chars.0)
                    let range = textView.selectedTextRange
                    textView.insertText(chars.1)
                    textView.selectedTextRange = range

                    return false
                }
            }
        }

        if text == "\n", var currentLine = textView.currentLine, let currentLineRange = textView.currentLineRange, let selectedRange = textView.selectedTextRange {

            let regex = try! NSRegularExpression(pattern: "\n", options: [])
            let lineNumber = regex.numberOfMatches(in: textView.text, options: [], range: NSMakeRange(0, textView.selectedRange.location)) + 1

//            // Move breakpoints
//            var breakpoints = [Breakpoint]()
//            for breakpoint in BreakpointsStore.breakpoints(for: document!.fileURL) {
//                if breakpoint.url == document?.fileURL && breakpoint.lineno > lineNumber {
//
//                    do {
//                        breakpoints.append(try Breakpoint(url: breakpoint.url!, lineno: breakpoint.lineno+1, isEnabled: breakpoint.isEnabled))
//                    } catch {
//                        breakpoints.append(breakpoint)
//                    }
//                } else {
//                    breakpoints.append(breakpoint)
//                }
//            }
//
//            BreakpointsStore.set(breakpoints: breakpoints, for: document!.fileURL)

            if selectedRange.start == currentLineRange.start {
                return true
            }

            var spaces = ""
            while currentLine.hasPrefix(" ") {
                currentLine.removeFirst()
                spaces += " "
            }

            if currentLine.replacingOccurrences(of: " ", with: "").hasSuffix(":") {
                spaces += PTCodeTextView.indentation
            }

            textView.insertText("\n"+spaces)

            return false
        }

        if text == "" && range.length > 1 {
            // That fixes a very strange bug causing the deletion of an extra space when removing an indented line
            textView.replace(range.toTextRange(textInput: textView) ?? UITextRange(), withText: text)
            return false
        }

        return true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        (editor as? PTTextEditorInstance)?.app?.saveCurrentFile()
//        save(completion: nil)
//
//        completionsHostingController.view.isHidden = true
//
//        parent?.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
//        if (!CompletionService.instance.serviceRunning) {
//            if let dir = (editor as? PTTextEditorInstance)?.app?.workSpaceStorage.currentDirectory.url {
//                FileManager.default.changeCurrentDirectoryPath(dir)
//            }
//            CompletionService.instance.startService()
//        }
        
//        if let console = (parent as? EditorSplitViewController)?.console, !ConsoleViewController.visibles.contains(console) {
//            ConsoleViewController.visibles.append(console)
//        }
//
//        parent?.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
//
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if !completionsHostingController.view.isHidden {
//            placeCompletionsView()
//        }
//    }
//
//    // MARK: - Suggestions
//
//    /// Linter warnings.
//    var warnings = [Any]() {
//        didSet {
//            guard #available(iOS 15.0, *) else {
//                return
//            }
//
//            (warningsHolder as? LinterView.WarningsHolder)?.warnings = (warnings as? [Linter.Warning]) ?? []
//
//            guard let linter = linterVC else {
//                return
//            }
//
//            linter.preferredContentSize = CGSize(width: 500, height: (120*warnings.count)+100)
//            linter.modalPresentationStyle = .popover
//            linter.popoverPresentationController?.barButtonItem = linterItem
//            present(linter, animated: false)
//        }
//    }

    /// Sets the position of the completions view.
    func placeCompletionsView() {
        guard let selection = textView.selectedTextRange?.start else {
            return
        }

//        guard let parent = parent else {
//            return
//        }
//
//        codeCompletionManager.currentWord = textView.text(in: textView.currentWordWithUnderscoreRange ?? UITextRange())
//
//        let cursorPosition = parent.view.convert(textView.caretRect(for: selection).origin, from: textView)
//
//        completionsHostingController.view.sizeToFit()
//
//        completionsHostingController.view.frame.origin = CGPoint(x: cursorPosition.x, y: cursorPosition.y+(textView.font?.pointSize ?? 17)+5)
//
//        while completionsHostingController.view.frame.maxX >= parent.view.frame.maxX {
//            completionsHostingController.view.frame.origin.x -= 1
//        }
//
//        let oldY = completionsHostingController.view.frame.origin.y
//        if completionsHostingController.view.frame.maxY >= parent.view.frame.maxY {
//            completionsHostingController.view.frame.origin.y = cursorPosition.y-completionsHostingController.view.frame.height-(textView.font?.pointSize ?? 17)-5
//        }
//
//        if completionsHostingController.view.frame.minY <= parent.view.frame.minY {
//            completionsHostingController.view.frame.origin.y = oldY
//        }
    }

    /// The view for code completion on an horizontal size class.
    var completionsHostingController: UIHostingController<CompletionsView>!

//    /// The definitions of the scripts. Array of arrays: [["content", lineNumber]]
//    @objc var definitions = NSMutableArray() {
//        didSet {
//            DispatchQueue.main.async { [weak self] in
//
//                guard let self = self else {
//                    return
//                }
//
//                if let hostC = (self.presentedViewController as? UINavigationController)?.viewControllers.first as? UIHostingController<DefinitionsView> {
//                    hostC.rootView.dataSource.definitions = self.definitionsList
//                }
//            }
//        }
//    }
//
//    /// Definitions of the scripts.
//    var definitionsList: [Definition] {
//        var definitions = [Definition]()
//        for def in self.definitions {
//            if let content = def as? [Any], content.count == 8 {
//                guard let description = content[0] as? String else {
//                    continue
//                }
//
//                guard let line = content[1] as? Int else {
//                    continue
//                }
//
//                guard let docString = content[2] as? String else {
//                    continue
//                }
//
//                guard let name = content[3] as? String else {
//                    continue
//                }
//
//                guard let signatures = content[4] as? [String] else {
//                    continue
//                }
//
//                guard let _definedNames = content[5] as? [Any] else {
//                    continue
//                }
//
//                guard let moduleName = content[6] as? String else {
//                    continue
//                }
//
//                guard let type = content[7] as? String else {
//                    continue
//                }
//
//                var definedNames = [Definition]()
//
//                for _name in _definedNames {
//
//                    guard let name = _name as? [Any] else {
//                        continue
//                    }
//
//                    guard name.count == 8 else {
//                        continue
//                    }
//
//                    guard let description = name[0] as? String else {
//                        continue
//                    }
//
//                    guard let line = name[1] as? Int else {
//                        continue
//                    }
//
//                    guard let docString = name[2] as? String else {
//                        continue
//                    }
//
//                    guard let _name = name[3] as? String else {
//                        continue
//                    }
//
//                    guard let signatures = name[4] as? [String] else {
//                        continue
//                    }
//
//                    guard let moduleName = name[6] as? String else {
//                        continue
//                    }
//
//                    guard let type = name[7] as? String else {
//                        continue
//                    }
//
//                    definedNames.append(Definition(signature: description, line: line, docString: docString, name: _name, signatures: signatures, definedNames: [], moduleName: moduleName, type: type))
//                }
//
//                definitions.append(Definition(signature: description, line: line, docString: docString, name: name, signatures: signatures, definedNames: definedNames, moduleName: moduleName, type: type))
//            }
//
//        }
//
//        return definitions
//    }

    @objc private static var codeToComplete = ""

    /// Selects a suggestion from hardware tab key.
    @objc func nextSuggestion() {
        guard let inputAssistantView = self.inputAssistantView else {return}
        
        guard let result = inputAssistantView.completionResult else {return}
        
        if (inputAssistantView.numberOfSuggestionsInInputAssistantView() <= 0) {return}

            let new = inputAssistantView.currentSuggestionIndex+1

        if result.suggestions.indices.contains(new) {
            inputAssistantView.currentSuggestionIndex = new
        } else {
            inputAssistantView.currentSuggestionIndex = -1
        }
    }

    /// A boolean indicating whether the editor is completing code.
    @objc static var isCompleting = false

    let codeCompletionManager = CodeCompletionManager()

    private var _signature = ""

    /// Function or class signature displayed in the completion bar.
    @objc var signature: String {
        get {
            var comps = [String]() // Remove annotations because it's too long

            let sig = _signature.components(separatedBy: " ->").first ?? _signature

            for component in sig.components(separatedBy: ",") {
                if let name = component.components(separatedBy: ":").first {
                    comps.append(name)
                }
            }

            var str = comps.joined(separator: ",")
            if !str.hasSuffix(")") && sig.hasSuffix(")") {
                str.append(")")
            }
            return str
        }

        set {
            if newValue != "NoneType()" {
                _signature = newValue
            }
        }
    }

    /// The doc string to display.
    @objc var docString: String? {
        didSet {

            class DocViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

                override func viewLayoutMarginsDidChange() {
                    super.viewLayoutMarginsDidChange()

                    view.subviews.first?.frame = view.safeAreaLayoutGuide.layoutFrame
                }

                override func viewWillAppear(_ animated: Bool) {
                    super.viewWillAppear(animated)

                    view.subviews.first?.isHidden = true
                }

                override func viewDidAppear(_ animated: Bool) {
                    super.viewDidAppear(animated)

                    view.subviews.first?.frame = view.safeAreaLayoutGuide.layoutFrame
                    view.subviews.first?.isHidden = false
                }

                func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
                    return .none
                }
            }

//            if presentedViewController != nil, presentedViewController! is DocViewController {
//                presentedViewController?.dismiss(animated: false) {
//                    self.docString = self.docString
//                }
//                return
//            }

            guard docString != nil else {
                return
            }

//            DispatchQueue.main.async { [weak self] in
//
//                guard let self = self else {
//                    return
//                }
//
//                let docView = UITextView()
//                docView.textColor = .white
//                docView.font = UIFont(name: "Menlo", size: UIFont.systemFontSize)
//                docView.isEditable = false
//                docView.text = self.docString
//                docView.backgroundColor = .black
//
//                let docVC = DocViewController()
//                docView.frame = docVC.view.safeAreaLayoutGuide.layoutFrame
//                docVC.view.addSubview(docView)
//                docVC.view.backgroundColor = .black
//                docVC.preferredContentSize = CGSize(width: 300, height: 100)
//                docVC.modalPresentationStyle = .popover
//                docVC.presentationController?.delegate = docVC
//                docVC.popoverPresentationController?.backgroundColor = .black
//                docVC.popoverPresentationController?.permittedArrowDirections = [.up, .down]
//
//                if let selectedTextRange = self.textView.contentTextView.selectedTextRange {
//                    docVC.popoverPresentationController?.sourceView = self.textView.contentTextView
//                    docVC.popoverPresentationController?.sourceRect = self.textView.contentTextView.caretRect(for: selectedTextRange.end)
//                } else {
//                    docVC.popoverPresentationController?.sourceView = self.textView.contentTextView
//                    docVC.popoverPresentationController?.sourceRect = self.textView.contentTextView.bounds
//                }

//                self.present(docVC, animated: true, completion: nil)
//            }
        }
    }

    var isCompleting = false

    var codeCompletionTimer: Timer?

    let completeQueue = DispatchQueue(label: "code-completion")

    /// Returns information about the pyhtml Python script tag the cursor is currently in.
    var currentPythonScriptTag: (codeRange: NSRange, code: String, relativeCodeRange: NSRange)? {

        let selectedRange = textView.selectedRange

        var openScriptTagRange: NSRange?
        var closeScriptTagRange: NSRange?

        (text as NSString).enumerateSubstrings(in: NSRange(location: 0, length: selectedRange.location), options: .byLines) { (line, a, b, continue) in

            guard let line = line else {
                return
            }

            let withoutSpaces = line.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")

            if withoutSpaces.hasPrefix("<scripttype=") && withoutSpaces.contains("python") {

                openScriptTagRange = a
                `continue`.pointee = false
            }
        }

        (text as NSString).enumerateSubstrings(in: NSRange(location: selectedRange.location, length: (text as NSString).length-selectedRange.location), options: .byLines) { (line, a, b, continue) in
            guard let line = line else {
                return
            }

            let withoutSpaces = line.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")

            if withoutSpaces.hasPrefix("</script>") {
                closeScriptTagRange = a
                `continue`.pointee = false
            }
        }

        let isInsidePythonScriptTag = openScriptTagRange != nil && closeScriptTagRange != nil

        var code: String!

        var codeRange: NSRange!

        var relativeCodeRange: NSRange!

        if isInsidePythonScriptTag {
            let start = openScriptTagRange!.location+openScriptTagRange!.length
            codeRange = NSRange(location: start, length: closeScriptTagRange!.location-start)
            code = (text as NSString).substring(with: codeRange)
            relativeCodeRange = NSRange(location: selectedRange.location-start+1, length: 0)
        }

        if !isInsidePythonScriptTag {
            return nil
        } else {
            return (codeRange: codeRange, code: code, relativeCodeRange: relativeCodeRange)
        }
    }
    
    /// Directory in which the script will be ran.
    var currentDirectory: URL {
        get {
            if let url = editor?.url {
                return url.deletingLastPathComponent()
            } else {
                return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            }
        }
        
        set {
//            guard newValue != self.editor?.url.deletingLastPathComponent() else {
//                if (try? self.editor?.url.extendedAttribute(forName: "currentDirectory")) != nil {
//                    do {
//                        try self.document?.fileURL.removeExtendedAttribute(forName: "currentDirectory")
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                }
//                return
//            }
//
//#if !SCREENSHOTS
//            if let data = try? newValue.bookmarkData() {
//                do {
//                    try self.document?.fileURL.setExtendedAttribute(data: data, forName: "currentDirectory")
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//#endif
        }
    }

    /// Updates suggestions.
    ///
    /// - Parameters:
    ///     - force: If set to `true`, the Python code will be called without doing any check.
    ///     - getDefinitions: If set to `true` definitons will be retrieved, we don't need to update them every time, just when we open the definitions list.
    func updateSuggestions(force: Bool = false, getDefinitions: Bool = false) {

        switch editor!.url.pathExtension.lowercased() {
        case "c", "cpp", "cxx", "m", "mm":
            completionsHostingController.view.isHidden = true
            codeCompletionManager.selectedIndex = -1

            /*
             visibleEditor.lastCodeFromCompletions = code
                         visibleEditor.signature = signature
                         visibleEditor.suggestionsType = types
                         visibleEditor.completions = completions
                         visibleEditor.suggestions = suggestions
                         visibleEditor.docStrings = docs
                         visibleEditor.signatures = signatures
             */

            let code = textView.text
            let selectedRange = textView.selectedRange
            DispatchQueue.global().async {
//                completeCSource(url: self.document!.fileURL, range: selectedRange, textView: self.textView, completionHandler: { [weak self] completions in
//                    self?.lastCodeFromCompletions = code
//                    for completion in completions {
//                        self?.suggestionsType[completion.name] = ""
//                    }
//                    self?.completions = completions.map({ $0.name })
//                    self?.suggestions = completions.map({ $0.name })
//                    self?.docStrings = [:]
//                    for completion in completions {
//                        self?.signatures[completion.name] = completion.signature
//                    }
//                })
            }
        default:
            break
        }

        guard editor?.url.pathExtension.lowercased() == "py" || editor?.url.pathExtension.lowercased() == "html" else {
            return
        }

        let currentPythonScriptTag = self.currentPythonScriptTag
        let text = currentPythonScriptTag?.code ?? self.text

        if currentPythonScriptTag == nil && editor?.url.pathExtension.lowercased() == "html" {
            return
        }

        guard let textRange = textView.selectedTextRange else {
            return
        }

        if !force && !getDefinitions {
            guard let line = textView.currentLine, !line.isEmpty else {
                self.signature = ""
                codeCompletionManager.docStrings = [:]
                codeCompletionManager.signatures = [:]
                completionsHostingController.view.isHidden = true
                codeCompletionManager.selectedIndex = -1
                self.inputAssistantView?.reloadCompletion(result: nil)
                return
            }
        }

        var location = 0
        if currentPythonScriptTag == nil {
            guard let range = textView.textRange(from: textView.beginningOfDocument, to: textRange.end) else {
                return
            }
            for _ in textView.text(in: range) ?? "" {
                location += 1
            }
        } else {
            location = currentPythonScriptTag!.relativeCodeRange.location-1
        }

//        EditorViewController.codeToComplete = text
//
//        ConsoleViewController.ignoresInput = true

        codeCompletionManager.docStrings = [:]
        codeCompletionManager.signatures = [:]

        completionsHostingController.view.isHidden = true
        codeCompletionManager.selectedIndex = -1
        
        Task.init {
            guard let editor = self.editor else {return}
            
//            if let result = await CompletionService.instance.requestCompletion(vid: editor.currentVersionId, path: editor.url.path, index: location), result.vid == editor.currentVersionId {
//                self.inputAssistantView?.reloadCompletion(result: result)
//            }
            
            let result = await completeCode(code: editor.content, path: editor.url.path, index: location, getdef: getDefinitions, vid: editor.currentVersionId)
            
            if result?.vid == editor.currentVersionId {
                self.inputAssistantView?.reloadCompletion(result: result)
            }
                
            
//            if let jsonStr = result {
//                let completion = try? JSONSerialization.jsonObject(with: jsonStr.data(using: .utf8)!)
//                if let completion = completion as? [String: Any] {
//        //            let vid = completion["vid"] as! String
//                    let vid = self.editor?.currentVersionId
//                    if (vid == self.editor?.currentVersionId) {
//                        self.suggestions = completion["suggestions"] as? [String] ?? []
//                        self.completions = completion["completions"] as? [String] ?? []
//                        self.suggestionsType = completion["suggestionsType"] as? [String: String] ?? [:]
//                        self.signatures = completion["signatures"] as? [String: String] ?? [:]
//                        self.signature = completion["signature"] as? String ?? ""
//                        self.lastCodeFromCompletions = self.text
//                        self.currentSuggestionIndex = -1
//                        self.inputAssistant.reloadData()
//                    }
//                }
//            }
        }
//        self.suggestions = ["print", "hello", "world"]
//        self.completions = ["rint", "ello", "orld"]
//        self.suggestionsType = ["print": "", "hello": "", "world": ""]
//        self.lastCodeFromCompletions = self.text
//        self.currentSuggestionIndex = -1
//        self.inputAssistant.reloadData()

//        if isCompleting { // A timer so it doesn't block the main thread
//
//            if !(codeCompletionTimer?.isValid == true) {
//                codeCompletionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
//
//                    if self?.isCompleting == false && timer.isValid {
//                        complete()
//                        timer.invalidate()
//                    }
//                })
//            }
//        } else {
//            complete()
//        }
        
//        Task.init {
//            async let result = await completionCmd(request: "")
//            try? await print(result)
//        }
    }

    @objc func toggleCompletionsView(_ sender: Any) {
        completionsHostingController.view.isHidden.toggle()
    }

//    // MARK: - Document picker delegate
//
//    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        let success = urls.first?.startAccessingSecurityScopedResource()
//
//        let url = urls.first ?? currentDirectory
//
//        func doChange() {
//            currentDirectory = url
//            if !FoldersBrowserViewController.accessibleFolders.contains(currentDirectory.resolvingSymlinksInPath()) {
//                FoldersBrowserViewController.accessibleFolders.append(currentDirectory.resolvingSymlinksInPath())
//            }
//
//            if success == true {
//                for item in (parentVC?.toolbarItems ?? []).enumerated() {
//                    if item.element.action == #selector(setCwd(_:)) {
//                        parentVC?.toolbarItems?.remove(at: item.offset)
//                        break
//                    }
//                }
//            }
//        }
//
//        if let file = document?.fileURL,
//            url.appendingPathComponent(file.lastPathComponent).resolvingSymlinksInPath() == file.resolvingSymlinksInPath() {
//
//            doChange()
//        } else {
//
//            let alert = UIAlertController(title: NSLocalizedString("couldNotAccessScriptAlert.title", comment: "Title of the alert shown when setting a current directory not containing the script"), message: NSLocalizedString("couldNotAccessScriptAlert.message", comment: "Message of the alert shown when setting a current directory not containing the script"), preferredStyle: .alert)
//
//            alert.addAction(UIAlertAction(title: NSLocalizedString("couldNotAccessScriptAlert.useAnyway", comment: "Use anyway"), style: .destructive, handler: { (_) in
//                doChange()
//            }))
//
//            alert.addAction(UIAlertAction(title: NSLocalizedString("couldNotAccessScriptAlert.selectAnotherLocation", comment: "Select another location"), style: .default, handler: { (_) in
//                self.setCwd(alert)
//            }))
//
//            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "'Cancel' button"), style: .cancel, handler: { (_) in
//                urls.first?.stopAccessingSecurityScopedResource()
//            }))
//
//            present(alert, animated: true, completion: nil)
//        }
//    }
}


let jsonstr111 = """
{"definitions": [], "signature": "", "suggestionsType": {"pass": "keyword", "PendingDeprecationWarning": "class", "PermissionError": "class", "pow": "function", "print": "function", "ProcessLookupError": "class", "property": "class", "BaseException": "class", "breakpoint": "function", "BrokenPipeError": "class", "ChildProcessError": "class", "compile": "function", "complex": "class", "copyright": "function", "DeprecationWarning": "class", "ellipsis": "class", "Ellipsis": "statement", "Exception": "class", "FloatingPointError": "class", "help": "function", "import": "keyword", "ImportError": "class", "ImportWarning": "class", "input": "function", "InterruptedError": "class", "KeyboardInterrupt": "class", "LookupError": "class", "map": "function", "NotImplemented": "statement", "NotImplementedError": "class", "open": "function", "repr": "function", "StopAsyncIteration": "class", "StopIteration": "class", "super": "class", "tuple": "class", "type": "class", "TypeError": "class", "zip": "function", "__import__": "function", "__package__": "instance"}, "completions": ["ass", "endingDeprecationWarning", "ermissionError", "ow", "rint", "rocessLookupError", "roperty", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__", "__is_fuzzy__"], "suggestions": ["pass", "PendingDeprecationWarning", "PermissionError", "pow", "print", "ProcessLookupError", "property", "BaseException", "breakpoint", "BrokenPipeError", "ChildProcessError", "compile", "complex", "copyright", "DeprecationWarning", "ellipsis", "Ellipsis", "Exception", "FloatingPointError", "help", "import", "ImportError", "ImportWarning", "input", "InterruptedError", "KeyboardInterrupt", "LookupError", "map", "NotImplemented", "NotImplementedError", "open", "repr", "StopAsyncIteration", "StopIteration", "super", "tuple", "type", "TypeError", "zip", "__import__", "__package__"], "docStrings": {"pass": "", "PendingDeprecationWarning": "", "PermissionError": "", "pow": "", "print": "", "ProcessLookupError": "", "property": "", "BaseException": "", "breakpoint": "", "BrokenPipeError": "", "ChildProcessError": "", "compile": "", "complex": "", "copyright": "", "DeprecationWarning": "", "ellipsis": "", "Ellipsis": "", "Exception": "", "FloatingPointError": "", "help": "", "import": "", "ImportError": "", "ImportWarning": "", "input": "", "InterruptedError": "", "KeyboardInterrupt": "", "LookupError": "", "map": "", "NotImplemented": "", "NotImplementedError": "", "open": "", "repr": "", "StopAsyncIteration": "", "StopIteration": "", "super": "", "tuple": "", "type": "", "TypeError": "", "zip": "", "__import__": "", "__package__": ""}, "signatures": {"pass": "", "PendingDeprecationWarning": "", "PermissionError": "", "pow": "", "print": "", "ProcessLookupError": "", "property": "", "BaseException": "", "breakpoint": "", "BrokenPipeError": "", "ChildProcessError": "", "compile": "", "complex": "", "copyright": "", "DeprecationWarning": "", "ellipsis": "", "Ellipsis": "", "Exception": "", "FloatingPointError": "", "help": "", "import": "", "ImportError": "", "ImportWarning": "", "input": "", "InterruptedError": "", "KeyboardInterrupt": "", "LookupError": "", "map": "", "NotImplemented": "", "NotImplementedError": "", "open": "", "repr": "", "StopAsyncIteration": "", "StopIteration": "", "super": "", "tuple": "", "type": "", "TypeError": "", "zip": "", "__import__": "", "__package__": ""}, "vid": "1"}
"""
