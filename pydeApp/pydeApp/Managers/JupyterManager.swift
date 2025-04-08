//
//  JupyterManager.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import SwiftUI
import pydeCommon
import CryptoKit
import CCommon
import pyde

class JupyterManager: ObservableObject {
    @Published var running: Bool = false
    @Published var firstRuned: Bool = false
    
    @AppStorage("jupyter_server_password") var password: String = ""
    @AppStorage("jupyter_server_port") var port: String = "8888"
    @AppStorage("jupyter_server_public") var public_server: Bool = false
    @AppStorage("jupyter_play_whitespace") var play_ws: Bool = true
    
    @Published var ip: String = ""
    
    let runner = PYRunnerWidget()
    
    private var forwarder: UnixSocketProxy?
    
    lazy var runnerWidget: AnyView = AnyView(runner.id(UUID()))
    
    var runnerView: ConsoleView {
        return runner.consoleView
    }
    
    func closeNotebook() {
        running = false
        
        runnerView.executor?.kill()
        
        forwarder?.clear()
        forwarder = nil
    }
    
    let passwdSalt = "bfa0495a0305"
    
    
    func openNotebook(_ wkurl: URL? = nil) {
        if runnerView.executor?.state != .idle {
            return
        }
        
        if let url = wkurl {
            runnerView.resetAndSetNewRootDirectory(url: url)
        }
        
        ip = getIPAddress()
        
        let sha1 = Insecure.SHA1.hash(data: (password + passwdSalt).data(using: .utf8)!).hexString().lowercased()
        
        let configText = """
        c.KernelManager.autorestart = False
        #c.KernelManager.ip = '0.0.0.0'
        #c.NotebookApp.ip = '\(public_server ? "0.0.0.0" : "127.0.0.1")'
        c.NotebookApp.password = 'sha1:\(passwdSalt):\(sha1)'
        #c.NotebookApp.port = \(port)
        c.NotebookApp.disable_check_xsrf = True
        c.NotebookApp.allow_remote_access = True
        #c.NotebookApp.local_hostnames = ['localhost', '127.0.0.1']
        c.NotebookApp.allow_origin = '*'
        
        # 设置传输协议为 ipc
        c.KernelManager.transport = 'ipc'

        c.KernelManager.ip = '\(ConstantManager.appGroupContainer.appendingPathComponent("kernel.sock").path)'

        # 可选：关闭端口绑定（避免与 TCP 冲突）
        #c.Session.key = b''  # 禁用密钥（仅用于 IPC）
        """
        
        let configDir = ConstantManager.appGroupContainer.appendingPathComponent(".jupyter")
        if !FileManager.default.fileExists(atPath: configDir.path) {
            try? FileManager.default.createDirectory(atPath: configDir.path, withIntermediateDirectories: true)
        }
        let configUrl = configDir.appendingPathComponent("/jupyter_notebook_config.py")
        try? configText.write(to: configUrl, atomically: true, encoding: .utf8)
        
        let serverSock = ConstantManager.appGroupContainer.appendingPathComponent("notebook.sock").path
        let command = "remote jupyter-notebook --config \(configUrl.path) --sock=\(serverSock) --debug"
        
        running = true
        runnerView.clear()
//        runnerView.terminalView.isUserInteractionEnabled = false
        runnerView.executor?.dispatch(command: command, isInteractive: false, completionHandler: { [self] _ in
            DispatchQueue.main.async { [self] in
                running = false
            }
        })
        
        // 使用示例
        forwarder = UnixSocketProxy(tcpPort: Int32(port, radix: 10) ?? 8888, unixPath: serverSock)

        // 启动服务
        do {
            try forwarder?.start()
        } catch {
            print("启动失败: \(error)")
        }

        
//        forwarder = SocketForwarder(
//            tcpPort: UInt16(port, radix: 10) ?? 8888,
//            unixSocketPath: serverSock
//        )

        // 启动服务
//        forwarder?.start()

        // 在适当的时候调用 stop()
        // forwarder.stop()

    }
}

class JupyterExtension: CodeAppExtension {
    
    public static let jupyterManager = JupyterManager()
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
//        let outline = ActivityBarItem(
//            itemID: "JUPYTER",
//            iconSystemName: "note",
//            title: "JUPYTER",
//            shortcutKey: "n",
//            modifiers: [.command, .shift],
//            view: AnyView(JupyterContainer(jupyterManager: jupyterManager)),
//            contextMenuItems: nil,
//            bubble: {nil},
//            isVisible: { true }
//        )
//        jupyterManager.runner.consoleView.resetAndSetNewRootDirectory(url: URL(fileURLWithPath: app.workSpaceStorage.currentDirectory.url))
//        contribution.activityBar.registerItem(item: outline)
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        JupyterExtension.jupyterManager.runner.consoleView.executor?.setNewWorkingDirectory(url: newUrl)
    }
}




import Foundation
import Network

import Foundation

class UnixSocketProxy {
    // MARK: 配置属性
    private let tcpPort: Int32
    private let unixPath: String
    private var tcpServerFD: Int32 = -1
    private var isRunning: Bool = false
    private let queue = DispatchQueue(label: "jupyter.proxy.queue", attributes: .concurrent)
    private var activeConnections = Set<Connection>()
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var healthTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "jupyter.timer.queue")
    private var shouldResume: Bool = false
    
    // MARK: 连接结构体
    private struct Connection: Hashable {
        let clientFD: Int32
        let unixFD: Int32
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(clientFD)
        }
        
        static func == (lhs: Connection, rhs: Connection) -> Bool {
            return lhs.clientFD == rhs.clientFD
        }
    }
    
    // MARK: 初始化
    init(tcpPort: Int32, unixPath: String) {
        self.tcpPort = tcpPort
        self.unixPath = unixPath
        
        setupNotifications()
    }
    
    func clear() {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: 启动服务
    func start() throws {
        guard !isRunning else { return }
        
        // 创建 TCP 服务器
        tcpServerFD = socket(AF_INET, SOCK_STREAM, 0)
        guard tcpServerFD != -1 else {
            throw SocketError.creationFailed
        }
        
        // 配置 TCP 套接字
        var reuseAddr: Int32 = 1
        setsockopt(tcpServerFD, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout.size(ofValue: reuseAddr)))
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(tcpPort).bigEndian
        addr.sin_addr.s_addr = INADDR_ANY
        
        // 绑定 TCP 端口
        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(tcpServerFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult != -1 else {
            throw SocketError.bindFailed
        }
        
        // 开始监听
        listen(tcpServerFD, 100)
        isRunning = true
        print("✅ 代理服务已启动 [TCP:\(tcpPort) ↔ UNIX:\(unixPath)]")
        
        // 接受客户端连接
        queue.async { [weak self] in
            while self?.isRunning == true {
                var clientAddr = sockaddr()
                var addrLen = socklen_t(MemoryLayout<sockaddr>.size)
                let clientFD = accept(self?.tcpServerFD ?? -1, &clientAddr, &addrLen)
                
                guard let self = self, clientFD != -1 else { continue }
                
                print("🔌 新的客户端连接: \(clientFD)")
                
                // 连接到 Unix 域套接字
                let unixFD = self.connectToUnixSocket()
                guard unixFD != -1 else {
                    close(clientFD)
                    continue
                }
                
                // 创建连接记录
                let connection = Connection(clientFD: clientFD, unixFD: unixFD)
                self.queue.async(flags: .barrier) {
                    self.activeConnections.insert(connection)
                }
                
                // 启动数据桥接
                self.bridge(connection: connection)
            }
        }
        
        // 新增健康检查
        setupHealthCheck()
        // 注册后台通知
//        setupNotifications()
        print("✅ 代理服务已启动 [TCP:\(tcpPort) ↔ UNIX:\(unixPath)]")
    }
    
    // MARK: 停止服务
    func stop() {
        shouldResume = false
        guard isRunning else { return }
        isRunning = false
        
        // 取消定时器
        healthTimer?.cancel()
        healthTimer = nil
//        NotificationCenter.default.removeObserver(self)
        
        // 关闭 TCP 服务器
        close(tcpServerFD)
        
        // 关闭所有活跃连接
        queue.async(flags: .barrier) { [weak self] in
            self?.activeConnections.forEach {
                close($0.clientFD)
                close($0.unixFD)
            }
            self?.activeConnections.removeAll()
        }
        print("🛑 代理服务已停止")
    }
    
    // MARK: 新增健康检查机制
        private func setupHealthCheck() {
            
//            healthTimer?.cancel()
//            
//            let timer = DispatchSource.makeTimerSource(queue: timerQueue)
//            timer.schedule(deadline: .now() + 5, repeating: 5)
//            timer.setEventHandler { [weak self] in
//                self?.checkServerStatus()
//            }
//            timer.resume()
//            healthTimer = timer
        }
        
        private func checkServerStatus() {
            queue.async { [weak self] in
                guard let self = self else { return }
                
                // 双重检查确保运行状态
                guard self.isRunning else { return }
                
                // 检查TCP服务器套接字有效性
                var error = 0
                var len = socklen_t(MemoryLayout.size(ofValue: error))
                let status = getsockopt(self.tcpServerFD, SOL_SOCKET, SO_ERROR, &error, &len)
                
                if status != 0 || error != 0 {
                    print("‼️ 检测到服务异常，尝试重启...")
                    self.restartServer()
                }
            }
        }
        
        // MARK: 新增重启逻辑
        private func restartServer() {
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                
                print("🔄 尝试重启服务...")
                do {
                    self.stop()
                    try self.start()
                } catch {
                    print("‼️ 重启失败: \(error)")
                    // 失败后延迟重试
                    self.queue.asyncAfter(deadline: .now() + 5) {
                        self.restartServer()
                    }
                }
            }
        }
        
        // MARK: 新增后台任务管理
        private func setupNotifications() {
            NotificationCenter.default.addObserver(self,
                selector: #selector(appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil)
            
            NotificationCenter.default.addObserver(self,
                selector: #selector(appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil)
        }
        
        @objc private func appDidEnterBackground() {
            beginBackgroundTask()
        }
        
        @objc private func appWillEnterForeground() {
            endBackgroundTask()
            
            if shouldResume {
                restartServer()
            }
        }
        
        private func beginBackgroundTask() {
            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                if UIApplication.shared.applicationState == .background {
                    self?.stop()
                    self?.shouldResume = true
                }
                self?.endBackgroundTask()
            }
        }
        
        private func endBackgroundTask() {
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        }
    
    // MARK: 私有方法
    private func connectToUnixSocket() -> Int32 {
        let unixFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard unixFD != -1 else {
            perror("创建 Unix 套接字失败")
            return -1
        }
        
        // 创建本地副本避免内存访问冲突
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        
        // 分离路径处理逻辑
        let pathData: [CChar] = {
            let maxLength = Int(MemoryLayout.size(ofValue: addr.sun_path)) - 1
            var buffer = [CChar](repeating: 0, count: maxLength + 1)
            
            return unixPath.withCString { cString in
                let copyLength = min(strlen(cString), maxLength)
                strncpy(&buffer, cString, copyLength)
                buffer[copyLength] = 0
                return buffer
            }
        }()
        
        // 安全拷贝到结构体字段
        withUnsafeMutableBytes(of: &addr.sun_path) { destPtr in
            pathData.withUnsafeBytes { srcPtr in
                destPtr.copyMemory(from: srcPtr)
            }
        }
        
        // 连接操作
        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(unixFD, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        guard connectResult != -1 else {
            perror("连接 Unix 域套接字失败")
            close(unixFD)
            return -1
        }
        
        return unixFD
    }


    
    private func bridge(connection: Connection) {
        let clientSource = DispatchSource.makeReadSource(fileDescriptor: connection.clientFD)
        let unixSource = DispatchSource.makeReadSource(fileDescriptor: connection.unixFD)
        
        // 客户端 -> Unix 转发
        clientSource.setEventHandler { [weak self] in
            self?.forwardData(from: connection.clientFD, to: connection.unixFD)
        }
        
        // Unix -> 客户端转发
        unixSource.setEventHandler { [weak self] in
            self?.forwardData(from: connection.unixFD, to: connection.clientFD)
        }
        
        // 连接关闭处理
        let cancelHandler = { [weak self] in
            clientSource.cancel()
            unixSource.cancel()
            close(connection.clientFD)
            close(connection.unixFD)
            self?.queue.async(flags: .barrier) {
                self?.activeConnections.remove(connection)
            }
            print("🔌 连接关闭: \(connection.clientFD)")
        }
        
        clientSource.setCancelHandler(handler: cancelHandler)
        unixSource.setCancelHandler(handler: cancelHandler)
        
        clientSource.resume()
        unixSource.resume()
    }
    
    private func forwardData(from sourceFD: Int32, to destFD: Int32) {
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(sourceFD, &buffer, 4096)
        
        if bytesRead > 0 {
            _ = write(destFD, buffer, bytesRead)
        } else {
            // 连接关闭时自动触发清理
            close(sourceFD)
            close(destFD)
        }
    }
    
    // MARK: 错误枚举
    enum SocketError: Error {
        case creationFailed
        case bindFailed
        case listenFailed
        case unixSocketFailed
    }
    
    deinit {
        clear()
    }
}




//import asyncio
//
//async def tcp_to_unix_proxy(tcp_reader, tcp_writer):
//    unix_reader, unix_writer = await asyncio.open_unix_connection("/Volumes/Python/jupyteripc/ipc.sock")
//    
//    async def forward(src_reader, dst_writer):
//        try:
//            while True:
//                data = await src_reader.read(4096)
//                if not data:
//                    break
//                dst_writer.write(data)
//                await dst_writer.drain()
//        finally:
//            dst_writer.close()
//    
//    # 双向转发
//    await asyncio.gather(
//        forward(tcp_reader, unix_writer),
//        forward(unix_reader, tcp_writer)
//    )
//
//async def main():
//    server = await asyncio.start_server(tcp_to_unix_proxy, '0.0.0.0', 9999)
//    async with server:
//        await server.serve_forever()
//
//if __name__ == "__main__":
//    asyncio.run(main())
//
