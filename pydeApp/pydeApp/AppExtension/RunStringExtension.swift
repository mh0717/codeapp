//
//  RunStringExtension.swift
//  Code
//
//  Created by huima on 2025/3/21.
//
import pydeCommon
import ios_system

class RunStringExtension: CodeAppExtension {
    
    weak var app: MainApp?
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        self.app = app
        
        
        NotificationCenter.default.addObserver(forName: Notification.Name(ConstantManager.RUN_PYTHON3_STRING_NOTIFICATION), object: nil, queue: nil) { notification in
            guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? String, sceneIdentifier == app.pyapp.sceneIdentifier else {
                return
            }
            guard let script = notification.userInfo?["script"] as? String else {
                return
            }
            
            runString(app: app, script: script)
        }
    }
    
    
}
    
func runString(app: MainApp, script: String) {
    let ins = app.pyapp.consoleInstance
    let hasCommand = script.hasPrefix("#!")
    let idle = app.pyapp.consoleInstance.executor.state == .idle
    
    DispatchQueue.main.async {
        app.pyapp.currentPanel = DefaultUIState.PANEL_FOCUSED_ID
    }
    
    if (hasCommand && !idle) {
        app.notificationManager.showErrorMessage("Terminal is busy")
        return
    }
    
    if (hasCommand && idle) {
        do {
            let dir = ConstantManager.appGroupContainer.appendingPathComponent("run_selection_tmp")
            if !FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
            }
            let path = dir.appendingPathComponent(UUID().uuidString)
            var src = script
            if script.split(separator: "\n").first?.contains("python") == true {
                src = convertPython2PrintToPython3(script)
            }
            try src.write(to: path, atomically: true, encoding: .utf8)
            app.pyapp.consoleInstance.terminalView.feed(text: "run\r\n")
            _ = app.pyapp.consoleInstance.executor.evaluateCommands([path.path])
            return
        } catch {
            ins.terminalView.feed(text: "run failed!\r\n")
        }
        return
    }
    
    let isPython = ins.executor.lastCommand?.contains("python") == true || ins.executor.lastCommand?.contains("python3") == true
    if !idle && isPython {
        guard let src = convertPython2PrintToPython3(script).base64Encoded() else {
            return
        }
        let runStr = "from __ios import canEval;import base64;__src=base64.b64decode(\"\(src)\").decode('utf-8');print(__src);__result=eval(__src) if canEval(__src) else exec(__src);print(__result) if __result != None else None;"
        ins.executor.sendInput(input: runStr)
        return
    }
    
    if !idle {
        script.split(separator: "\n").forEach { str in
            app.pyapp.consoleInstance.terminalView.send(txt: String(str))
            app.pyapp.consoleInstance.terminalView.send(txt: "\r")
        }
        return
    }
    
    app.pyapp.consoleInstance.terminalView.send(txt: "python3 -q -i")
    app.pyapp.consoleInstance.terminalView.send(txt: "\r")
    
    DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(200))) {
        guard let src = convertPython2PrintToPython3(script).base64Encoded() else {
            return
        }
        let runStr = "from __ios import canEval;import base64;__src=base64.b64decode(\"\(src)\").decode('utf-8');print(__src);__result=eval(__src) if canEval(__src) else exec(__src);print(__result) if __result != None else None;"
        app.pyapp.consoleInstance.executor.sendInput(input: runStr)
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
    if input.contains("print(") || input.contains("print (") || input.contains("print  (") {
        return input
    }
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
        
        if let originalMethod = class_getInstanceMethod(WKWebView.self, originalSelector),
           let swizzledMethod = class_getInstanceMethod(WKWebView.self, swizzledSelector) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        
        // 交换 canBecomeFirstResponder
        let originalCanBecome = #selector(getter: UIResponder.canBecomeFirstResponder)
        let swizzledCanBecome = #selector(swizzled_canBecomeFirstResponder)

        if let originalMethod = class_getInstanceMethod(self, originalCanBecome),
           let swizzledMethod = class_getInstanceMethod(self, swizzledCanBecome) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    @objc func swizzled_canBecomeFirstResponder() -> Bool {
        UIMenuController.shared.menuItems = [
            UIMenuItem(title: NSLocalizedString("Web Menu Run", comment: ""), action: WKWebView.runAction)
        ]
        return true
    }
    
    
    
    // 替换后的 canPerformAction
    @objc func swizzled_canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 如果是自定义的 Action，返回 true
        if action == Self.runAction {
            return true
        }
        
        if UIDevice.isiPad {
            return self.swizzled_canPerformAction(action, withSender: sender)
        }
        
        if action == Selector("copy:") {
            return true
        }
        
        if action == Selector("_share:") {
            return true
        }
        
        return false
    }
    
    // 处理菜单点击
    @objc func runCustomAction() {
        let getSel = """
            if (window.reader && window.reader.view && window.reader.view.renderer) {
                window.reader.view.renderer.getContents().map((item)=>item.doc.getSelection().toString()).join()
            } else {
                window.getSelection().toString()
            }
            """
        let sceneIdentifier = window?.windowScene?.session.persistentIdentifier ?? ""
        evaluateJavaScript(getSel) { msg, err in
            if let str = msg as? String, !str.isEmpty {
                NotificationCenter.default.post(
                    name: NSNotification.Name(
                        rawValue: ConstantManager.RUN_PYTHON3_STRING_NOTIFICATION), object: nil,
                    userInfo: ["script": str, "sceneIdentifier": sceneIdentifier])
            }
        }
    }
}

extension UIDevice {
    static var isiPad: Bool {
        return current.userInterfaceIdiom == .pad
    }
}



// MARK: - 方法替换逻辑
//extension WKWebView {
//    static func swizzleWKWebViewMenu() {
//        // 定义原始方法和替换方法的选择器
//        let originalSelector = #selector(buildMenu(with:))
//        let swizzledSelector = #selector(swizzledBuildMenu(with:))
//        
//        // 获取方法的 Method 对象
//        guard let originalMethod = class_getInstanceMethod(WKWebView.self, originalSelector),
//              let swizzledMethod = class_getInstanceMethod(WKWebView.self, swizzledSelector) else {
//            print("⚠️ 方法替换失败")
//            return
//        }
//        
//        // 交换方法实现
//        method_exchangeImplementations(originalMethod, swizzledMethod)
//    }
//    
//    // 动态添加的替换方法（需标记为 @objc）
//    @objc func swizzledBuildMenu(with builder: UIMenuBuilder) {
//        // 调用原始实现（已交换，实际调用原来的 buildMenuWithBuilder:）
//        self.swizzledBuildMenu(with: builder)
//        
//        // 添加自定义 "Run" 动作
//        let runAction = UIAction(
//            title: NSLocalizedString("Web Menu Run", comment: ""),
//            image: UIImage(systemName: "play.fill"),
//            identifier: UIAction.Identifier("com.example.run")
//        ) { _ in
//            self.handleRunAction()
//        }
//        
//        // 将动作插入菜单末尾（可调整位置）
//        let runMenu = UIMenu(title: "", options: .displayInline, children: [runAction])
//        builder.insertChild(runMenu, atEndOfMenu: .standardEdit)
//    }
//    
//    // 处理 "Run" 动作
//    private func handleRunAction() {
//        let getSel = """
//            if (window.reader && window.reader.view && window.reader.view.renderer) {
//                window.reader.view.renderer.getContents().map((item)=>item.doc.getSelection().toString()).join()
//            } else {
//                window.getSelection().toString()
//            }
//            """
//        let sceneIdentifier = window?.windowScene?.session.persistentIdentifier ?? ""
//        evaluateJavaScript(getSel) { msg, err in
//            if let str = msg as? String, !str.isEmpty {
//                NotificationCenter.default.post(
//                    name: NSNotification.Name(
//                        rawValue: ConstantManager.RUN_PYTHON3_STRING_NOTIFICATION), object: nil,
//                    userInfo: ["script": str, "sceneIdentifier": sceneIdentifier])
//            }
//        }
//    }
//}



import WebKit
import ObjectiveC

extension WKWebView {
    // MARK: - 方法替换
    private typealias OriginalBuildMenuIMP = @convention(c) (AnyObject, Selector, UIMenuBuilder) -> Void
    
    // 保存原始方法实现的指针
    private static var originalBuildMenuIMP: OriginalBuildMenuIMP?
    
    // 供外部调用的激活方法
    @objc public static func enableCustomMenu() {
        DispatchQueue.once(token: "WKWebViewCustomMenu") {
            swizzleBuildMenu()
        }
    }
    
    // MARK: - 私有实现
    @objc dynamic private func custom_buildMenu(with builder: UIMenuBuilder) {
        // 调用原始方法
        if let imp = WKWebView.originalBuildMenuIMP {
            imp(self, #selector(WKWebView.buildMenu(with:)), builder)
        }
        
        // 移除查找菜单
        builder.remove(menu: .lookup)
        
        // 添加 RUN 菜单
        let runAction = UIAction(
            title: NSLocalizedString("Web Menu Run", comment: ""),
            image: UIImage(systemName: "play.fill"),
            identifier: UIAction.Identifier("custom.run")
        ) { [weak self] _ in
            self?.runCustomAction()
        }
        
        builder.insertChild(
            UIMenu(title: "", options: .displayInline, children: [runAction]),
            atStartOfMenu: .root
        )
    }
    
    
    // 方法替换核心逻辑
    static func swizzleBuildMenu() {
        let originalSelector = #selector(WKWebView.buildMenu(with:))
        let swizzledSelector = #selector(WKWebView.custom_buildMenu(with:))
        
        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else {
            return
        }
        
        // 保存原始实现
        originalBuildMenuIMP = unsafeBitCast(
            method_getImplementation(originalMethod),
            to: OriginalBuildMenuIMP.self
        )
        
        // 替换实现
        method_setImplementation(originalMethod, method_getImplementation(swizzledMethod))
    }
}

// 一次性执行封装
extension DispatchQueue {
    private static var tokens = Set<String>()
    
    static func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard !tokens.contains(token) else { return }
        tokens.insert(token)
        block()
    }
}
