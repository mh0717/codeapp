//
//  Python.swift
//  Code
//
//  Created by Huima on 2023/12/22.
//

import Foundation
import pydeCommon
import CCommon
import ios_system
//import UIKit

//@_cdecl("python3Main")
//public func python3Main(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
////    return pydeMainInMainIntp(argc, argv)
//    return 0
//}

private var _runMainInMainCount = 0
//@_cdecl("python3MainInMainThread")
//public func python3MainInMainThread(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
////    initDEMainIntp()
////    
////    if _runMainInMainCount > 0 {
////        return pydeMainInMainIntp(argc, argv)
////    }
////    
////    _runMainInMainCount += 1
////    
////    setvbuf(thread_stdout, nil, _IONBF, 0)
////    setvbuf(thread_stderr, nil, _IONBF, 0)
//////    setvbuf(thread_stdin, nil, _IONBF, 0)
////    
////    let stdin = thread_stdin
////    let stdout = thread_stdout
////    let stderr = thread_stderr
////    var result: Int32 = 0
////    
////    if (Thread.isMainThread) {
////        return pydeMainInMainIntp(argc, argv)
////    }
////    
////    var isEnd = false
////    let timer = Timer(timeInterval: 0.1, repeats: false) { _ in
////        thread_stdin = stdin
////        thread_stdout = stdout
////        thread_stderr = stderr
////        result = pydeMainInMainIntp(argc, argv)
////        isEnd = true
////    }
////    RunLoop.main.add(timer, forMode: .default)
////    
////    while !isEnd {
////        usleep(100)
////    }
////    return result
//    return 0
//}


@_cdecl("python3Sub")
public func python3Sub(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    return pydeMainInSubIntp(argc, argv)
    return 0
}

@_cdecl("python3Process")
public func python3Process(argc: Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let cmds = __concatenateArgv(argv)
    let cmdStr = String(cString: cmds!)
    return clientReqCommands(commands: [cmdStr])
}

private var _python3SubProcessCount = 0

/// 运行在子线程中，如果已经运行中，只能再开启一个进程
@_cdecl("python3SubProcess")
public func python3SubProcess(argc: Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    if _python3SubProcessCount == 0 {
        _python3SubProcessCount += 1
        return python3_exec(argc: argc, argv: argv)
    }
    
    let cmds = __concatenateArgv(argv)
    let cmdStr = String(cString: cmds!)
    return remoteReqRemoteCommands(commands: [cmdStr])
}

private var _python3MainCount = 0
@_cdecl("python3SubProcessInMain")
public func python3SubProcessInMain(argc: Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    if _python3MainCount > 0 {
        let cmds = __concatenateArgv(argv)
        let cmdStr = String(cString: cmds!)
        return remoteReqRemoteCommands(commands: [cmdStr])
    }
    _python3MainCount += 1
    let stdin = thread_stdin
       let stdout = thread_stdout
       let stderr = thread_stderr
       var result: Int32 = 0
    if Thread.isMainThread {
        result = python3MainNotExit(argc, argv)
//        result = python3Main(argc, argv)
        return result
    }
    
    var isEnd = false
    let endLocker = NSCondition()
    
    let timer = Timer(timeInterval: 0.1, repeats: false) { _ in
        thread_stdin = stdin
        thread_stdout = stdout
        thread_stderr = stderr
        /// 这里之所以python不能退出，是因为toga ui不能退出
//         result = python3Main(argc, argv)
        result = python3MainNotExit(argc, argv)
        
        isEnd = true
        endLocker.signal()
    }
    RunLoop.main.add(timer, forMode: .default)
    
    endLocker.lock()
    while !isEnd {
        usleep(1000 * 100)
        endLocker.wait()
    }
    endLocker.unlock()
    return result
}

@_cdecl("pythonA")
public func pythonA(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    return pythonAMain(argc, argv)
}

@_cdecl("pythonB")
public func pythonB(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    return pythonBMain(argc, argv)
}

@_cdecl("remote")
//@_silgen_name("remote")
public func myremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    return remote(argc: argc, argv: argv)
}

@_cdecl("pyde_open")
public func pyde_open(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let args = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    wmessager.passMessage(message: args, identifier: ConstantManager.PYDE_OPEN_COMMAND_MSG);
    return 0
}

@_cdecl("openurl")
public func pyde_openurl(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    wmessager.passMessage(message: cmds, identifier: ConstantManager.PYDE_OPEN_COMMAND_MSG);
    return 0
}

@_cdecl("readremote")
public func pyde_readremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
    return readRemote()
}

@_cdecl("endremoteui")
public func endremoteui(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
    wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_FORCE_EXIT)
    return 0
}


@_cdecl("clear")
public func clear__(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    vfprintf(thread_stdout, "\u{1B}[2J\u{1B}[0;0H", getVaList([]))
    return 0
}

@_cdecl("plink")
public func plink(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    if cmds.count == 1 || cmds[1] == "-h" || cmds[1] == "--help" {
        vfprintf(thread_stdout, "\nusage: plink content link\nex: plink python3ide https://www.python3ide.com\n", getVaList([]))
        return 0
    }
    let content = cmds[1]
    let link = cmds.count >= 3 ? cmds[2] : content
    vfprintf(thread_stdout, "\u{1B}]8;;\(link)\u{1B}\\\(content)\u{1B}]8;;\u{1B}\\\n", getVaList([]))
    return 0
}

#if IDE_UI
@_cdecl("wish_inmain")
public func wish_inmain(argc: Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let lib = dlopen(Bundle.main.bundlePath.appending("/../../Frameworks/tk.framework/tk"), RTLD_NOW)
    let wish_main_handle = dlsym(lib, "wish_main")
    let wish_main = unsafeBitCast(wish_main_handle, to: __main_t.self)
    
    let stdin = thread_stdin
       let stdout = thread_stdout
       let stderr = thread_stderr
       var result: Int32 = 0
    if Thread.isMainThread {
        result = wish_main(argc, argv)
        return result
    }
    
    var isEnd = false
    
    let timer = Timer(timeInterval: 0.1, repeats: false) { _ in
        thread_stdin = stdin
        thread_stdout = stdout
        thread_stderr = stderr
        result = wish_main(argc, argv)
        isEnd = true
    }
    RunLoop.main.add(timer, forMode: .default)
    
    while !isEnd {
        usleep(1000 * 100)
    }
    return result
}
#endif

//feed(text: "\u{1B}]8;;http://example.com\u{1B}\\This is a link\u{1B}]8;;\u{1B}\\\r\n")

//@_cdecl("remotenode")
//public func clear__(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    vfprintf(thread_stdout, "\u{1B}[2J\u{1B}[0;0H", getVaList([]))
//    return 0
//}

//@_silgen_name("remote")
//public func __remote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32


public func initPyDE() {
    initClientEnv()
    
    replaceCommand("remote", "remote", false)
    replaceCommand("open", "pyde_open", false)
    replaceCommand("openurl", "openurl", false)
    replaceCommand("readremote", "readremote", false)
    replaceCommand("endremoteui", "endremoteui", false)
    replaceCommand("clear", "clear", false)
    replaceCommand("plink", "plink", false)
    
    replaceCommand("node", "ide_node", false)
    replaceCommand("npm", "ide_npm", false)
    replaceCommand("npx", "ide_npx", false)
    replaceCommand("nodeg", "ide_nodeg", false)
    
    replaceCommand("wasm", "idewasm", false)
//    initDESubIntp()
//    replaceCommand("python3", "python3Sub", false)
    
    
    
//    initDEMainIntp()
//    replaceCommand("python3", "python3Main", false)
    
    replaceCommand("pythonA", "python3Process", false)
    replaceCommand("pythonB", "python3Process", false)
    replaceCommand("python3", "python3Process", false)
    replaceCommand("python", "python3Process", false)
    replaceCommand("python3.11", "python3Process", false)
    replaceCommand("lua", "python3Process", false)
    replaceCommand("clang", "python3Process", false)
    replaceCommand("clang++", "python3Process", false)
    replaceCommand("php", "python3Process", false)
    replaceCommand("perl", "python3Process", false)
    replaceCommand("tclsh", "python3Process", false)
//    replaceCommand("node", "python3Process", false)
    replaceCommand("wish", "python3Process", false)
    
//    UIViewController.swizzIt()
    #if IDEUIPREVIEW
    
    #else
    DispatchQueue.main.async {
        wasmWebView.loadFileURL(
            ConstantManager.clanglib.appendingPathComponent("wasm.html"),
            allowingReadAccessTo: ConstantManager.WASM)
    }
    #endif
    
    #if PYTHON3IDE
    replaceCommand("ctagswasm", "ctagswasm", false)
    DispatchQueue.main.async {
        ctagsWebView.loadFileURL(
            ConstantManager.clanglib.appendingPathComponent("wasm.html"),
            allowingReadAccessTo: ConstantManager.WASM)
    }
    #endif
   
}

public func initRemotePython3Sub() {
    initRemoteEnv()
    
    replaceCommand("pythonA", "pythonA", false)
    replaceCommand("pythonB", "pythonB", false)
    replaceCommand("open", "pyde_open", false)
    replaceCommand("openurl", "openurl", false)
    replaceCommand("rremote", "rremote", false)
    replaceCommand("clear", "clear", false)
    replaceCommand("plink", "plink", false)
    
    replaceCommand("python3", "python3SubProcess", false)
    replaceCommand("python", "python3SubProcess", false)
//    replaceCommand("python3", "python3SubProcessInMain", false)
//    replaceCommand("python", "python3SubProcessInMain", false)
    
    replaceCommand("wasm", "idewasm", false)
    
    #if IDEUIPREVIEW
    
    #else
    DispatchQueue.main.async {
        wasmWebView.loadFileURL(
            ConstantManager.clanglib.appendingPathComponent("wasm.html"),
            allowingReadAccessTo: ConstantManager.WASM)
    }
    #endif
    
    
    
//    initDEMainIntp()
//    replaceCommand("python3", "python3Main", false)
    
//    initDESubIntp()
//    replaceCommand("python3", "python3Sub", false)
}

public func initPydeUI() {
    initRemoteUIEnv()
    
    replaceCommand("pythonA", "pythonA", false)
    replaceCommand("pythonB", "pythonB", false)
    replaceCommand("open", "pyde_open", false)
    replaceCommand("openurl", "openurl", false)
    replaceCommand("rremote", "rremote", false)
    replaceCommand("clear", "clear", false)
    replaceCommand("plink", "plink", false)
    
//    replaceCommand("python3", "python3RunInMain", false)
//    initDEMainIntp()
//    replaceCommand("python3", "python3MainInMainThread", false)
    
    replaceCommand("python3", "python3SubProcessInMain", false)
    replaceCommand("python", "python3SubProcessInMain", false)
    replaceCommand("wish", "wish_inmain", false)
}


@_cdecl("rremote")
public func rremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    cmds.removeFirst()
    return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
}


private var _python3RunInMainCount = 0
@_cdecl("python3RunInMain")
public func python3RunInMain(argc: Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    
    if _python3RunInMainCount > 0 {
        let cmds = __concatenateArgv(argv)
        let cmdStr = String(cString: cmds!)
        return remoteReqRemoteCommands(commands: [cmdStr])
    }
    
    _python3RunInMainCount += 1
    
    setvbuf(thread_stdout, nil, _IONBF, 0)
    setvbuf(thread_stderr, nil, _IONBF, 0)
//    setvbuf(thread_stdin, nil, _IONBF, 0)
    
    let stdin = thread_stdin
    let stdout = thread_stdout
    let stderr = thread_stderr
    var result: Int32 = 0
    
    if (Thread.isMainThread) {
        return python3_exec(argc: argc, argv: argv)
    }
    
    var isEnd = false
    let timer = Timer(timeInterval: 0.1, repeats: false) { _ in
        thread_stdin = stdin
        thread_stdout = stdout
        thread_stderr = stderr
        result = python3_exec(argc: argc, argv: argv)
        isEnd = true
    }
    RunLoop.main.add(timer, forMode: .default)
//    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
//        thread_stdin = stdin
//        thread_stdout = stdout
//        thread_stderr = stderr
//        result = Py_BytesMain(argc, argv)
//        isEnd = true
//    }
//    RunLoop.main.schedule {
//        thread_stdin = stdin
//        thread_stdout = stdout
//        thread_stderr = stderr
//        result = Py_BytesMain(argc, argv)
//        isEnd = true
//    }
    
    
    
    while !isEnd {
        usleep(100)
    }
    return result
}


public func python3_exec(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    return python3Main(argc, argv)
}


//import Network
//
//public class SocketServer {
//    private var listener: NWListener?
//    
//    init(port: UInt16) {
//        let parameters = NWParameters.tcp
//        guard let port = NWEndpoint.Port(rawValue: port) else { return }
//        
//        do {
//            listener = try NWListener(using: parameters, on: port)
//        } catch {
//            print("Failed to create listener: \(error)")
//            return
//        }
//        
//        setupListener()
//    }
//    
//    private func setupListener() {
//        listener?.stateUpdateHandler = { newState in
//            switch newState {
//            case .ready:
//                print("Server ready on port \(self.listener?.port?.rawValue ?? 0)")
//            case .failed(let error):
//                print("Server failure: \(error)")
//            default:
//                break
//            }
//        }
//        
//        listener?.newConnectionHandler = { newConnection in
//            print("New connection accepted")
//            self.setupConnection(newConnection)
//            newConnection.start(queue: .main)
//        }
//    }
//    
//    private func setupConnection(_ connection: NWConnection) {
//        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
//            if let data = data, !data.isEmpty {
//                let message = String(data: data, encoding: .utf8)
//                print("Received message: \(message ?? "")")
//            }
//            
//            if isComplete || error != nil {
//                connection.cancel()
//            } else {
//                self?.setupConnection(connection)
//            }
//        }
//    }
//    
//    func start() {
//        listener?.start(queue: .main)
//    }
//}
//
//
//import Network
//
//public class SocketClient {
//    private var connection: NWConnection?
//    
//    init(host: String, port: UInt16) {
//        let host = NWEndpoint.Host(host)
//        let port = NWEndpoint.Port(rawValue: port)!
//        connection = NWConnection(host: host, port: port, using: .tcp)
//    }
//    
//    func connect() {
//        connection?.stateUpdateHandler = { state in
//            switch state {
//            case .ready:
//                print("Client connected")
//            case .failed(let error):
//                print("Connection failed: \(error)")
//            default:
//                break
//            }
//        }
//        connection?.start(queue: .main)
//    }
//    
//    func send(message: String) {
//        guard let data = message.data(using: .utf8) else { return }
//        connection?.send(content: data, completion: .contentProcessed({ error in
//            if let error = error {
//                print("Send error: \(error)")
//                return
//            }
//            print("Message sent: \(message)")
//        }))
//    }
//}



//import Foundation
//import UIKit
//
//final class SharedMemoryManager {
//    private(set) var mappedPtr: UnsafeMutableRawPointer!
//    private var fileHandle: FileHandle!
//    fileprivate let bufferSize: Int
//    private let bufferCount: Int
//    
//    init(bufferSize: Int, bufferCount: Int = 3) {
//        self.bufferSize = bufferSize
//        self.bufferCount = bufferCount
//        setupSharedMemory()
//    }
//    
//    private func setupSharedMemory() {
//        let fileURL = FileManager.default
//            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.app")!
//            .appendingPathComponent("shared_buffer")
//        
//        // 创建或打开共享文件
//        if !FileManager.default.fileExists(atPath: fileURL.path) {
//            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
//        }
//        
//        // 计算总内存大小（帧头 + 三重缓冲）
//        let totalSize = MemoryLayout<Int>.size * 2 + bufferSize * bufferCount
//        let fd = open(fileURL.path, O_RDWR | O_CREAT, 0666)
//        guard fd != -1 else {
//            fatalError("Failed to open shared file")
//        }
//        
//        // 调整文件大小
//        ftruncate(fd, off_t(totalSize))
//        
//        // 内存映射
//        mappedPtr = mmap(nil, totalSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
//        guard mappedPtr != MAP_FAILED else {
//            close(fd)
//            fatalError("Memory mapping failed")
//        }
//        
//        // 初始化帧头
//        let versionPtr = mappedPtr.bindMemory(to: Int.self, capacity: 2)
//        versionPtr[0] = 0  // 当前版本号
//        versionPtr[1] = 0  // 当前写入索引
//    }
//    
//    deinit {
//        let totalSize = MemoryLayout<Int>.size * 2 + bufferSize * bufferCount
//        munmap(mappedPtr, totalSize)
//        close(fileHandle?.fileDescriptor ?? -1)
//    }
//}
//
//
//class RenderProcess {
//    private let manager: SharedMemoryManager
//    private let semaphore = DispatchSemaphore(value: 1)
//    private let bufferSize: Int
//    
//    init(bufferSize: Int) {
//        self.bufferSize = bufferSize
//        self.manager = SharedMemoryManager(bufferSize: bufferSize)
//    }
//    
//    func render(image: UIImage) {
//        guard let cgImage = image.cgImage,
//              let data = image.pngData() else { return }
//        
//        semaphore.wait()
//        defer { semaphore.signal() }
//        
//        // 获取当前写入索引
//        let header = manager.mappedPtr.bindMemory(to: Int.self, capacity: 2)
//        let writeIndex = (header[1] + 1) % 3
//        header[1] = writeIndex
//        
//        // 写入数据
//        let bufferPtr = manager.mappedPtr
//            .advanced(by: MemoryLayout<Int>.size * 2)
//            .advanced(by: bufferSize * writeIndex)
//        
//        data.withUnsafeBytes { bytes in
//            memcpy(bufferPtr, bytes.baseAddress!, min(data.count, bufferSize))
//        }
//        
//        // 更新版本号
//        header[0] += 1
//    }
//}
//
//
//
//class DisplayController {
//    private let manager: SharedMemoryManager
//    private var lastVersion = 0
//    private var displayLink: CADisplayLink!
//    private weak var displayLayer: CALayer!
//    
//    init(layer: CALayer, bufferSize: Int) {
//        self.manager = SharedMemoryManager(bufferSize: bufferSize)
//        self.displayLayer = layer
//        setupDisplayLink()
//    }
//    
//    private func setupDisplayLink() {
//        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
//        displayLink.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
//        displayLink.add(to: .main, forMode: .common)
//    }
//    
//    @objc private func updateFrame() {
//        let header = manager.mappedPtr.bindMemory(to: Int.self, capacity: 2)
//        guard header[0] > lastVersion else { return }
//        
//        // 获取最新数据索引
//        let readIndex = (header[1] + 3 - 1) % 3  // 总比写入索引慢一帧
//        
//        let bufferPtr = manager.mappedPtr
//            .advanced(by: MemoryLayout<Int>.size * 2)
//            .advanced(by: manager.bufferSize * readIndex)
//        
//        let data = Data(bytes: bufferPtr, count: manager.bufferSize)
//        guard let image = UIImage(data: data) else { return }
//        
//        // 更新图层
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        displayLayer.contents = image.cgImage
//        CATransaction.commit()
//        
//        lastVersion = header[0]
//    }
//}
//
////
////// 在渲染进程使用
////let renderer = RenderProcess(bufferSize: 1920 * 1080 * 4)
////let image = UIImage(named: "frame")!
////renderer.render(image: image)
////
////// 在主进程显示
////let displayLayer = CALayer()
////displayLayer.frame = UIScreen.main.bounds
////view.layer.addSublayer(displayLayer)
////
////let displayController = DisplayController(layer: displayLayer, bufferSize: 1920 * 1080 * 4)





import Foundation
import CoreGraphics

final class PixelBufferManager {
    static let bytesPerPixel = 4 // BGRA格式
    let width: Int
    let height: Int
    
    fileprivate var mappedPtr: UnsafeMutableRawPointer!
    fileprivate let bufferSize: Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.bufferSize = width * height * Self.bytesPerPixel
        setupSharedMemory()
    }
    
    private func setupSharedMemory() {
        let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.app")!
            .appendingPathComponent("pixel_buffer")
        
        // 创建内存映射文件
        let fd = open(fileURL.path, O_RDWR | O_CREAT, 0666)
        ftruncate(fd, off_t(bufferSize))
        
        mappedPtr = mmap(nil, bufferSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
        guard mappedPtr != MAP_FAILED else {
            close(fd)
            fatalError("Memory mapping failed")
        }
        
        // 初始化内存为黑色
        memset(mappedPtr, 0, bufferSize)
    }
    
    func writePixelData(_ data: UnsafeRawPointer) {
        memcpy(mappedPtr, data, bufferSize)
        msync(mappedPtr, bufferSize, MS_SYNC)
    }
    
    func readPixelData() -> UnsafeRawPointer {
        return UnsafeRawPointer(mappedPtr)
    }
    
    deinit {
        munmap(mappedPtr, bufferSize)
    }
}



class FrameRenderer {
    private let bufferManager: PixelBufferManager
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    init(width: Int, height: Int) {
        self.bufferManager = PixelBufferManager(width: width, height: height)
    }
    
    func render(image: UIImage) {
        // 转换为BGRA格式
        guard let cgImage = image.cgImage else { return }
        
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGBitmapInfo.byteOrder32Little.rawValue |
            CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        // 创建目标上下文
        guard let context = CGContext(
            data: bufferManager.mappedPtr,
            width: bufferManager.width,
            height: bufferManager.height,
            bitsPerComponent: 8,
            bytesPerRow: bufferManager.width * PixelBufferManager.bytesPerPixel,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return }
        
        // 绘制图像并直接写入共享内存
        context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: bufferManager.width, height: bufferManager.height)))
        
        // 强制同步内存
        bufferManager.writePixelData(context.data!)
    }
}


class DisplayController {
    private let bufferManager: PixelBufferManager
    private let displayLayer: CALayer
    private var displayLink: CADisplayLink!
    private let context = CIContext()
    
    init(layer: CALayer, width: Int, height: Int) {
        self.displayLayer = layer
        self.bufferManager = PixelBufferManager(width: width, height: height)
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrame() {
        // 直接从共享内存创建CIImage
        let pixelData = bufferManager.readPixelData()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGBitmapInfo.byteOrder32Little.rawValue |
            CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        let ciImage = CIImage(
            bitmapData: Data(bytes: pixelData, count: bufferManager.bufferSize),
            bytesPerRow: bufferManager.width * PixelBufferManager.bytesPerPixel,
            size: CGSize(width: bufferManager.width, height: bufferManager.height),
            format: .BGRA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        
        // 转换为CGImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // 更新图层（线程安全）
        DispatchQueue.main.async { [weak self] in
            self?.displayLayer.contents = cgImage
        }
    }
}


//// 初始化渲染器（渲染进程）
//let renderer = FrameRenderer(width: 1920, height: 1080)
//renderer.render(image: UIImage(named: "frame")!)
//
//// 初始化显示控制器（主进程）
//let displayLayer = CALayer()
//displayLayer.frame = UIScreen.main.bounds
//view.layer.addSublayer(displayLayer)
//
//let displayCtrl = DisplayController(layer: displayLayer, width: 1920, height: 1080)
