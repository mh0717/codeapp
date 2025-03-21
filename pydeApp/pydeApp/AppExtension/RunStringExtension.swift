//
//  RunStringExtension.swift
//  Code
//
//  Created by huima on 2025/3/21.
//
import pydeCommon

class RunStringExtension: CodeAppExtension {
    
    weak var app: MainApp?
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        self.app = app
        
        NotificationCenter.default.addObserver(forName: Notification.Name(ConstantManager.RUN_PYTHON3_STRING_NOTIFICATION), object: nil, queue: nil) { notification in
            guard let script = notification.userInfo?["script"] as? String else {
                return
            }
//            var str = script.replacingOccurrences(of: "\r\n", with: "\r")
//            str = str.replacingOccurrences(of: "\n", with: "\r")
            
            if app.pyapp.consoleInstance.executor.state == .idle {
                app.pyapp.consoleInstance.terminalView.send(txt: "python3 -q -i")
                app.pyapp.consoleInstance.terminalView.send(txt: "\r")
                
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(200))) {
                script.split(separator: "\n").forEach { str in
                    let src = convertPython2PrintToPython3(String(str))
                    app.pyapp.consoleInstance.terminalView.send(txt: src)
                    app.pyapp.consoleInstance.terminalView.send(txt: "\r")
                }
                app.pyapp.consoleInstance.terminalView.send(txt: "\r")
            }
            
            
//            guard app.pyapp.consoleInstance.executor.state == .idle else {
//                return
//            }
//            DispatchQueue.main.async {
//                app.pyapp.consoleInstance.executor.evaluateCommands([
//                    escapePythonCommand(script: script)
//                ])
//            }
        }
    }
    
    
}

fileprivate func escapePythonCommand(script: String) -> String {
    var escaped = script.replacingOccurrences(of: "\\\"", with: "\"")
    // 1. 转义双引号（替换 " 为 \"）
    escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
    
//    // 2. 转义反斜杠（替换 \ 为 \\）
//    escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
    
    // 3. 处理换行符（替换 \n 为 ; 或显式换行符）
    escaped = escaped.replacingOccurrences(of: "\n", with: "; ") // 单行模式
    // 或者保留多行结构（需确保Shell支持）：
    // escaped = escaped.replacingOccurrences(of: "\n", with: " \\\n")
    
    // 4. 包裹最终命令
    return "python3 -c \"\(escaped)\""
}


import Foundation

func convertPython2PrintToPython3(_ input: String) -> String {
    return input.components(separatedBy: .newlines)
        .map { line in
            var outputLine = line
            
            // 检测并转换 print 语句
            if let (indent, argsPart, suffix) = parsePython2Print(line: line) {
                let convertedArgs = convertPrintArgs(argsPart)
                outputLine = "\(indent)print(\(convertedArgs))\(suffix)"
            }
            
            return outputLine
        }
        .joined(separator: "\n")
}

// MARK: - 核心解析逻辑
private func parsePython2Print(line: String) -> (indent: String, args: String, suffix: String)? {
    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
    
    // 排除 Python3 语法和变量名包含 print 的情况
    guard trimmedLine.hasPrefix("print "),
          !trimmedLine.hasPrefix("print("),
          let printKeywordRange = line.range(of: "print\\s+", options: .regularExpression)
    else {
        return nil
    }
    
    // 提取缩进
    let indent = String(line[..<printKeywordRange.lowerBound])
    
    // 分离参数和后续内容（分号/注释）
    let contentAfterPrint = String(line[printKeywordRange.upperBound...])
    let (argsPart, suffix) = splitArgsAndSuffix(content: contentAfterPrint)
    
    return (indent, argsPart.trimmingCharacters(in: .whitespaces), suffix)
}

// MARK: - 分离参数与后缀（分号/注释）
private func splitArgsAndSuffix(content: String) -> (args: String, suffix: String) {
    var inSingleQuote = false
    var inDoubleQuote = false
    var escapeNext = false
    var splitIndex: String.Index? = nil
    
    for (index, char) in content.enumerated() {
        let currentIndex = content.index(content.startIndex, offsetBy: index)
        
        guard !escapeNext else {
            escapeNext = false
            continue
        }
        
        switch char {
        case "'" where !inDoubleQuote:
            inSingleQuote.toggle()
        case "\"" where !inSingleQuote:
            inDoubleQuote.toggle()
        case "\\":
            escapeNext = true
        case "#", ";" where !inSingleQuote && !inDoubleQuote:
            if splitIndex == nil { // 记录第一个分割点
                splitIndex = currentIndex
            }
        default:
            break
        }
    }
    
    guard let splitAt = splitIndex else {
        return (content, "")
    }
    
    return (
        String(content[..<splitAt]).trimmingCharacters(in: .whitespaces),
        String(content[splitAt...])
    )
}

// MARK: - 参数格式化（保持原有实现）
private func convertPrintArgs(_ args: String) -> String {
    guard !args.isEmpty else { return "" }
    
    var converted = ""
    var currentArg = ""
    var inSingleQuote = false
    var inDoubleQuote = false
    var escapeNext = false
    
    for char in args {
        if escapeNext {
            currentArg.append("\\\(char)")
            escapeNext = false
            continue
        }
        
        switch char {
        case "'" where !inDoubleQuote:
            inSingleQuote.toggle()
            currentArg.append(char)
        case "\"" where !inSingleQuote:
            inDoubleQuote.toggle()
            currentArg.append(char)
        case "\\":
            escapeNext = true
        case "," where !inSingleQuote && !inDoubleQuote:
            converted += currentArg.trimmingCharacters(in: .whitespaces) + ", "
            currentArg = ""
        default:
            currentArg.append(char)
        }
    }
    
    converted += currentArg
    return converted.trimmingCharacters(in: .whitespaces)
}



import WebKit
import ObjectiveC

// MARK: - 定义扩展
extension WKWebView {
    // 自定义的 Selector
    private static let runAction = #selector(runCustomAction)
    
    // 注册自定义菜单项
    static func swizzleForMenu() {
        let originalSelector = #selector(canPerformAction(_:withSender:))
        let swizzledSelector = #selector(swizzled_canPerformAction(_:withSender:))
        
        let originalMethod = class_getInstanceMethod(WKWebView.self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(WKWebView.self, swizzledSelector)!
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        // 注册自定义菜单项
        UIMenuController.shared.menuItems = [
            UIMenuItem(title: NSLocalizedString("Web Menu Run", comment: ""), action: runAction)
        ]
    }
    
    // 替换后的 canPerformAction
    @objc func swizzled_canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 如果是自定义的 Action，返回 true
        if action == Self.runAction {
            return true
        }
        // 其他情况调用原始实现
        return self.swizzled_canPerformAction(action, withSender: sender)
    }
    
    // 处理菜单点击
    @objc func runCustomAction() {
        let getSel = """
            if (reader && reader.view && reader.view.renderer) {
                reader.view.renderer.getContents().map((item)=>item.doc.getSelection().toString()).join()
            } else {
                window.getSelection().toString()
            }
            """
        evaluateJavaScript(getSel) { msg, err in
            if let str = msg as? String, !str.isEmpty {
                NotificationCenter.default.post(
                    name: NSNotification.Name(
                        rawValue: ConstantManager.RUN_PYTHON3_STRING_NOTIFICATION), object: nil,
                    userInfo: ["script": str])
            }
        }
    }
}
