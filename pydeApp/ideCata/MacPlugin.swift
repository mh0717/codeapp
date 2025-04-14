//
//  MacPlugin.swift
//  Code
//
//  Created by huima on 2025/4/10.
//
import AppKit

class MacPlugin: NSObject, Plugin {
    func runRemote(_ path: String) -> Int {
       
        
//        let exeURL = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("ideRemoteCata")
        let exeURL = Bundle.main.executableURL
//        let exeURL = Bundle.main.executableURL!
        let process = Process()
        let pipe = Pipe()

        // 设置执行的命令和参数
        process.executableURL = exeURL
        process.arguments = [path]
        
        do {
            try process.run()
            process.waitUntilExit()
            return 0
        } catch {
            return 1
        }
        return 1
    }
    
    required override init() {
    }

    func sayHello() {
        let process = Process()
        let pipe = Pipe()

        // 设置执行的命令和参数
        process.executableURL = URL(fileURLWithPath: "/bin/ls")
        process.arguments = ["-l"]  // 可选参数，例如显示详细信息
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit() // 等待命令执行完成
            
            // 读取命令输出
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("输出结果：\n\(output)")
            }
        } catch {
            print("执行失败：\(error.localizedDescription)")
        }
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Hello from AppKit!"
        alert.informativeText = "It Works!"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
