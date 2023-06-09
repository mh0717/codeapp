//
//  TMConsoleView.swift
//  Code
//
//  Created by Huima on 2023/5/22.
//

import Foundation
import SwiftTerm
import ios_system

class TMConsoleView: UIView, TerminalViewDelegate {
    let terminalView: TerminalView
    
    var _inputLine: String = ""
    var _inputIndex: Int = 0
    var _inputCursorIndex: Int = 0
    
    public var executor: Executor? = nil
    
    init(root: URL) {
        terminalView = TerminalView(frame: .zero, font: UIFont.monospacedSystemFont (ofSize: 14, weight: .regular))
        terminalView.getTerminal().foregroundColor = Color(red: 65535, green: 65535, blue: 65535)
        
        super.init(frame: .zero)
        
        self.executor = Executor(
            root: root,
            onStdout: { [weak self] data in
                self?.feed(data)
            },
            onStderr: { [weak self] data in
                self?.feed(data)
            },
            onRequestInput: { [weak self] prompt in
                let prompt = prompt.replacingOccurrences(of: "\n", with: "\r\n")
                if let data = prompt.data(using: .utf8) {
                    self?.feed(data)
                }
            })
//        var buffer = Data()
        /*for i in 1...5 {
            let tid = "\(self.executor!.persistentIdentifier).\(i).stdout"
            binaryWMessager.listenForMessage(withIdentifier: tid) { [weak self] msg in
//                print("tid: \(tid)")
                if let content = msg as? Data {
//                    print([UInt8](content)[content.count - 2])
//                    print([UInt8](content)[content.count - 1])
//                    let path = FileManager.default.currentDirectoryPath.appendingPathComponent(path: "host\(i).txt")
//                    try? content.write(to: URL(fileURLWithPath: path), options: .atomic)
                    if content.contains(where: {$0 == 0x0A}) {
                        if let str = String(data: content, encoding: .utf8) {
                            self?.terminalView.feed(text: str.replacingOccurrences(of: "\n", with: "\r\n"))
                        } else {
                            self?.terminalView.feed(byteArray: ([UInt8](content))[...])
                        }
//                        self?.terminalView.feed(byteArray: ([UInt8](content))[...])
                        
                    } else {
                        self?.terminalView.feed(byteArray: ([UInt8](content))[...])
                    }
                    
//                    buffer += content
//                    if (buffer.last == 92) {
//                        self?.terminalView.feed(byteArray: ([UInt8](buffer))[...])
//                        buffer = Data()
//                    }
                }
            }
        }*/
        
        
        setupView()
        setupLayout()
        
//        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mh.Python3IDE") else {
//            return
//        }
//        let path = appGroupContainer.appendingPathComponent("protest.txt").path
//
//        let tqueue = DispatchQueue(label: "test process")
//        tqueue.async {
//            mkfifo(path, 0x1FF)
//            let fileHandle = FileHandle(forWritingAtPath: path)
//            fileHandle?.write("hello".data(using: .utf8)!)
//            var count = 0
//            let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { Timer in
//                fileHandle?.write("hello \(count)".data(using: .utf8)!)
//                count += 1
//            }
//            let runloop = RunLoop.current
//            runloop.add(timer, forMode: .default)
//            runloop.run()
//        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.terminalView.terminalDelegate = self
        addSubview(self.terminalView)
    }
    
    func setupLayout() {
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            terminalView.topAnchor.constraint(equalTo: topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private var _isFirstReadedLine = false
    override func didMoveToWindow() {
        if !_isFirstReadedLine && self.window != nil {
            _isFirstReadedLine = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.readLine()
            }
        }
    }
    
    func resetAndSetNewRootDirectory(url: URL) {
        executor?.setNewWorkingDirectory(url: url)
        
        if executor?.state == .idle {
            readLine()
        }
//        executeScript("localEcho._activePrompt.prompt = `\(prompt)`")
        reset()
    }
    
    func reset() {
        
    }
    
    private var buffer = Data()
    private func feed(_ data: Data) {
        self.terminalView.feed(byteArray: [UInt8](data)[...])
        print([UInt8](data[(data.count - 6)...]))
        return
        if (self.buffer.isEmpty) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.terminalView.feed(byteArray: [UInt8](self.buffer)[...])
                self.buffer = Data()
            }
        }
        self.buffer += data
    }
    
    func readLine() {
        if executor?.state == .idle {
            terminalView.feed(text: executor?.prompt ?? "")
        }
    }
    
    func handleLine(_ line: String) {
        if self.executor?.state == .interactive {
            self.executor?.sendInput(input: line + "\n")
            return
        }

        if self.executor?.state == .running {
            self.executor?.sendInput(input: line + "\n")
            return
        }
        
        switch line {
        case "clear":
            readLine()
            break
        default:
            let command = line
            guard command.count > 0 else {
                readLine()
                return
            }
            let isInteractive = command.hasPrefix("ssh ") || command.hasPrefix("sftp")
            if isInteractive {
//                startInteractive()
            }
            executor?.dispatch(command: command, isInteractive: isInteractive) { _ in
                DispatchQueue.main.async {
//                    if self.isInteractive {
//                        self.stopInteractive()
//                    }
                    self.readLine()
                }
            }
        }
    }
}


extension TMConsoleView {
    func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
//        setenv("LINES", "\(newRows)", 1)
//        setenv("COLUMNS", "\(newCols - 5)", 1)
        self.executor?.winsize = (newCols, newRows)
        ios_setWindowSize(Int32(newCols), Int32(newRows), self.executor?.persistentIdentifier.utf8CString)
        wmessager.passMessage(message: "\(newCols):\(newRows)", identifier: "\(self.executor?.remoteIdentifier ?? "").winsize")
    }
    
    func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {
        
    }
    
    func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
        
    }
    
    func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
        if (data.isEmpty) {return}
        
        guard let msg = String(bytes: data, encoding: .utf8) else {
            print("send parse input error! : \(data)")
            return
        }
            
        switch msg {
        case "\u{3}":
            self._interrupt()
            return
        case "\u{1b}":
            self._escape()
            return
        case "\u{7f}":
            self._backspace()
            break
        case "\r":
            self._enter()
            break
        case "\t":
            self._tab()
            break
        case "\u{1b}[D":
            self._back()
            break
        case "\u{1b}[C":
            self._forward()
            break
        case "\u{1b}[A":
            self._up()
            break
        case "\u{1b}[B":
            self._down()
            break
        default:
            self._insertInputLine(msg.replacingOccurrences(of: "\u{1b}", with: ""))
            break
        }
    }
    
    func scrolled(source: SwiftTerm.TerminalView, position: Double) {
        
    }
    
    func requestOpenLink(source: SwiftTerm.TerminalView, link: String, params: [String : String]) {
        if let fixedup = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = NSURLComponents(string: fixedup) {
                if let nested = url.url {
                    UIApplication.shared.open (nested)
                }
            }
        }
    }
    
    func clipboardCopy(source: SwiftTerm.TerminalView, content: Data) {
        if let str = String (bytes: content, encoding: .utf8) {
            UIPasteboard.general.string = str
        }
    }
    
    func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {
        
    }
    
    private func _insertInputLine(_ msg: String) {
        if (msg.isEmpty || msg.containsEmoji) {
            return
        }
        
        if (_inputIndex <= 0) {
            _inputLine = msg + _inputLine
        }
        else if (_inputIndex >= _inputLine.count) {
            _inputLine = _inputLine + msg
        }
        else {
            _inputLine = _inputLine[0..<_inputIndex] + msg + _inputLine[_inputIndex...]
        }
        _inputIndex += msg.count
        
//        self.feed(text: "\u{001b}[2k\r")
//        self.feed(text: _inputLine)
        var count = 0
        msg.forEach { char in
            count += char.isASCII ? 1 : 2
        }
        self.terminalView.feed(text: "\u{001b}[\(count)@\(msg)")
    }
    
    private func _backspace() {
        if (_inputIndex <= 0) {return}
        if (_inputIndex > _inputLine.count) {
            _inputIndex -= 1
            return
        }
        
        let char = _inputLine[_inputLine.index(_inputLine.startIndex, offsetBy: _inputIndex-1)]
        _inputLine = _inputLine[0..<_inputIndex-1] + _inputLine[_inputIndex...]
        _inputIndex -= 1
        
        let count = char.isASCII ? 1 : 2
        self.terminalView.feed(text: "\u{1b}[\(count)D\u{1b}[\(count)P")
        
//        self.feed(text: "\u{001b}[P")
//        self.terminalView.feed(text: "\u{001b}7\u{001b}[2K\r")
//        self.terminalView.feed(text: _inputLine)
//        self.terminalView.feed(text: "\u{001b}8\u{001b}[\(char.isASCII ? 1 : 2)D")
    }
    
    private func _enter() {
        print("input line: \(_inputLine)")
        let line = self._inputLine
        self._inputLine = ""
        self._inputIndex = 0
        self.terminalView.feed(text: "\r\n")
        
        self.handleLine(line)
    }
    
    private func _back() {
        if (_inputIndex <= 0) {return}
        _inputIndex -= 1
        let char = _inputLine[_inputLine.index(_inputLine.startIndex, offsetBy: _inputIndex)]
        if (char.isASCII) {
            self.terminalView.feed(text: "\u{001b}[1D")
        } else {
            self.terminalView.feed(text: "\u{001b}[2D")
        }
    }
    
    private func _forward() {
        if (_inputIndex >= _inputLine.count) {return}
        let char = _inputLine[_inputLine.index(_inputLine.startIndex, offsetBy: _inputIndex)]
        _inputIndex += 1
        if (char.isASCII) {
            self.terminalView.feed(text: "\u{001b}[1C")
        } else {
            self.terminalView.feed(text: "\u{001b}[2C")
        }
    }
    
    private func _up() {
        
    }
    
    private func _down() {
        
    }
    
    private func _interrupt() {
        guard let executor = self.executor else {return}
        wmessager.passMessage(message: nil, identifier: "\(executor.remoteIdentifier).stop")
        
        self.executor?.kill()
    }
    
    private func _escape() {
        
    }
    
    private func _tab() {
        self._insertInputLine("    ")
    }
    
}


extension String {
    subscript(_ indexs: ClosedRange<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[beginIndex...endIndex])
    }
    
    subscript(_ indexs: Range<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indexs: PartialRangeThrough<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[startIndex...endIndex])
    }
    
    subscript(_ indexs: PartialRangeFrom<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indexs: PartialRangeUpTo<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[startIndex..<endIndex])
    }
}


extension Character {
    /// 简单的emoji是一个标量，以emoji的形式呈现给用户
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else{
            return false
        }
        return unicodeScalars.count == 1 &&
            (firstProperties.isEmojiPresentation ||
                firstProperties.generalCategory == .otherSymbol)
    }

    /// 检查标量是否将合并到emoji中
    var isCombinedIntoEmoji: Bool {
        return unicodeScalars.count > 1 &&
            unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }

    /// 是否为emoji表情
    /// - Note: http://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
    var isEmoji:Bool{
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}

extension String {
    /// 是否为单个emoji表情
    var isSingleEmoji: Bool {
        return count == 1 && containsEmoji
    }

    /// 包含emoji表情
    var containsEmoji: Bool {
        return contains{ $0.isEmoji}
    }

    /// 只包含emoji表情
    var containsOnlyEmoji: Bool {
        return !isEmpty && !contains{!$0.isEmoji}
    }

    /// 提取emoji表情字符串
    var emojiString: String {
        return emojis.map{String($0) }.reduce("",+)
    }

    /// 提取emoji表情数组
    var emojis: [Character] {
        return filter{ $0.isEmoji}
    }

    /// 提取单元编码标量
    var emojiScalars: [UnicodeScalar] {
        return filter{ $0.isEmoji}.flatMap{ $0.unicodeScalars}
    }
}
