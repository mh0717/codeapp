//
//  Runner.swift
//  PYUI
//
//  Created by Huima on 2023/5/31.
//

import Foundation
import ios_system


let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mh.Python3IDE")!



class OutputListener {
    /// consumes the messages on STDOUT
    let inputPipe = Pipe()
    
    /// outputs messages back to STDOUT
    let outputPipe = Pipe()
    
    /// consumes the messages on STDERR
    let inputErrorPipe = Pipe()
    
    /// outputs messages back to STDOUT
    let outputErrorPipe = Pipe()
    
    let myinputPipe = Pipe()
    
    
    var stdin_file: UnsafeMutablePointer<FILE>?
    var stdout_file: UnsafeMutablePointer<FILE>?
    var stderr_file: UnsafeMutablePointer<FILE>?
    
    let stdoutFileDescriptor = FileHandle.standardOutput.fileDescriptor
    let stderrFileDescriptor = FileHandle.standardError.fileDescriptor
    
    let coordinator = NSFileCoordinator(filePresenter: nil)
    
    var isClosed = false
    var stdoutBuffer = Data()
    var stdoutIndex = 1
    var stderrBuffer = Data()
    
    init(_ ncidentifier: String) {
        let ncid = ncidentifier
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {[weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if (!self.stdoutBuffer.isEmpty) {
                    let buffer = self.stdoutBuffer
                    self.stdoutBuffer = Data()
//                    let path = FileManager.default.currentDirectoryPath.appendingPathComponent(path: "ext\(self.stdoutIndex).txt")
//                    try? buffer.write(to: URL(fileURLWithPath: path), options: .atomic)
                    binaryWMessager.passMessage(message: buffer, identifier: "\(ncid).\(self.stdoutIndex).stdout")
//                    self.stdoutBuffer = Data()
                    
                    if (self.stdoutIndex == 5) {
                        self.stdoutIndex = 1
                    }
                    else {
                        self.stdoutIndex += 1
                    }
                }
            }
        }
        // Set up a read handler which fires when data is written to our inputPipe
        inputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                print(string)
            }
            DispatchQueue.main.async {
                self.stdoutBuffer.append(data)
            }
            
            
//            if let string = String(data: data, encoding: String.Encoding.utf8) {
//                wmessager.passMessage(message: string, identifier: "\(ncid).stdout")
//            }
            // Write input back to stdout
//            strongSelf.outputPipe.fileHandleForWriting.write(data)
        }
        
        
        
        inputErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let strongSelf = self else { return }
            
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                print(string)
                wmessager.passMessage(message: string, identifier: "\(ncid).stdout")
            }
            
            // Write input back to stdout
//            strongSelf.outputErrorPipe.fileHandleForWriting.write(data)
        }
        
        wmessager.listenForMessage(withIdentifier: "\(ncid).input") { [self] msg in
            let msgstr = (msg as? String) ?? ""
            let msgdata = msgstr.data(using: .utf8)!
            Thread.detachNewThread { [self] in
                myinputPipe.fileHandleForWriting.write(msgdata)
            }
        }
        
        wmessager.listenForMessage(withIdentifier: "\(ncid).winsize") { msg in
            guard let msg = msg as? String, msg.contains(":") else {return}
            let size = msg.split(separator: ":")
            let COLUMNS: String = String(size.first ?? "80")
            let LINES: String = String(size.last ?? "80")
            
            setenv("COLUMNS", COLUMNS, 1)
            setenv("LINES", LINES, 1)
            ios_setWindowSize(Int32(COLUMNS) ?? 80, Int32(LINES) ?? 80, ncid.toCString())
        }
        
        
        
        stdin_file = fdopen(myinputPipe.fileHandleForReading.fileDescriptor, "r")
        stdout_file = fdopen(inputPipe.fileHandleForWriting.fileDescriptor, "w")
        stderr_file = fdopen(inputErrorPipe.fileHandleForWriting.fileDescriptor, "w")
        
        setvbuf(stdin_file, nil, _IOLBF, 1024);
        setvbuf(stdout_file, nil, _IOLBF, 10240);
        setvbuf(stderr_file, nil, _IOLBF, 1024);
    }
    
    /// Sets up the "tee" of piped output, intercepting stdout then passing it through.
    func openConsolePipe() {
        // Copy STDOUT file descriptor to outputPipe for writing strings back to STDOUT
//        dup2(stdoutFileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor)
//        dup2(stderrFileDescriptor, outputErrorPipe.fileHandleForWriting.fileDescriptor)
//
//        // Intercept STDOUT with inputPipe
//        dup2(inputPipe.fileHandleForWriting.fileDescriptor, stdoutFileDescriptor)
//        dup2(inputErrorPipe.fileHandleForWriting.fileDescriptor, stderrFileDescriptor)
//
//
        dup2(myinputPipe.fileHandleForReading.fileDescriptor, FileHandle.standardInput.fileDescriptor)
    }
    
    /// Tears down the "tee" of piped output.
    func closeConsolePipe() {
//        // Restore stdout
//        freopen("/dev/stdout", "a", stdout)
//        freopen("/dev/stderr", "a", stdout)
//
//        [inputPipe.fileHandleForReading, outputPipe.fileHandleForWriting].forEach { file in
//            file.closeFile()
//        }
    }
    
}

func execute(_ config: [String: Any]) {
    numPythonInterpreters = 1
    
    replaceCommand("backgroundCmdQueue", "backgroundCmdQueue", true)
    replaceCommand("python3", "python3", true)
//        replaceCommand("pythonA", "pythonA", true)
//        replaceCommand("pythonB", "pythonB", true)
//    replaceCommand("mhecho", "mhecho", true)
//    replaceCommand("six", "six", true)
    
    joinMainThread = false
    
    guard let ncid: String = config["identifier"] as? String else {return}
    
    setenv("npm_config_prefix", sharedURL.appendingPathComponent("lib").path, 1)
    setenv("npm_config_cache", FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.path, 1)
    setenv("npm_config_userconfig", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(".npmrc").path, 1)
    
    let libraryURL = try! FileManager().url(
        for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    // Main Python install: $APPDIR/Library/lib/python3.x
    let pybundle = URL(fileURLWithPath: Bundle.main.resourcePath!).appendingPathComponent("../../pyhome")
    
    setenv("PYTHONHOME", pybundle.path.toCString(), 1)
    
    let pysite1 = URL(fileURLWithPath: Bundle.main.resourcePath!).appendingPathComponent("../../site-packages1")
    setenv("PYTHONPATH", pysite1.path.toCString(), 1)
    // Compiled files: ~/Library/__pycache__
    setenv(
        "PYTHONPYCACHEPREFIX",
        (libraryURL.appendingPathComponent("__pycache__")).path.toCString(), 1)
    setenv("PYTHONUSERBASE", libraryURL.path.toCString(), 1)
    setenv("APPDIR", pybundle.deletingLastPathComponent().path.toCString(), 1)
    
    // matplotlib backend
    setenv("MPLBACKEND", "module://backend_ios", 1);
    
    // pysdl
    setenv("PYSDL2_DLL_PATH", pybundle.deletingLastPathComponent().path.appendingPathComponent(path: "Frameworks"), 1)
    
    
    
    // Kivy environment to prefer some implementation on iOS platform
    putenv("KIVY_BUILD=ios".utf8CString);
    putenv("KIVY_NO_CONFIG=1".utf8CString);
//    putenv("KIVY_NO_FILELOG=1");
    putenv("KIVY_WINDOW=sdl2".utf8CString);
    putenv("KIVY_IMAGE=imageio,tex,gif".utf8CString);
    putenv("KIVY_AUDIO=sdl2".utf8CString);
    putenv("KIVY_GL_BACKEND=sdl2".utf8CString);
    /// 设为1，避免屏幕放大，可能sdl正确处理了高分屏，不用kivy再次处理
    setenv("KIVY_METRICS_DENSITY", "1", 1);
    setenv("KIVY_DPI", "401", 1)

    // IOS_IS_WINDOWED=True disables fullscreen and then statusbar is shown
    putenv("IOS_IS_WINDOWED=False".utf8CString);

//    #ifndef DEBUG
//    putenv("KIVY_NO_CONSOLELOG=1");
//    #endif
    
    putenv("PYOBJUS_DEBUG=1".utf8CString);
    
    
    wmessager.listenForMessage(withIdentifier: "\(ncid).stop") { msg in
        real_exit(vlaue: 0)
    }
    
    let output = OutputListener(ncid)
    output.openConsolePipe()
    
    
    
    var isStale = true
    
    guard let data = config["workingDirectoryBookmark"] as? Data else {
        return
    }
    
    let url = try! URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
    _ = url.startAccessingSecurityScopedResource()
    FileManager.default.changeCurrentDirectoryPath(url.path)
    

    if let wdata = config["workspace"] as? Data {
        let url = try! URL(resolvingBookmarkData: wdata, bookmarkDataIsStale: &isStale)
        _ = url.startAccessingSecurityScopedResource()
    }
    
    
    ios_setDirectoryURL(url)
//    Thread.current.name = args.joined(separator: " ")
    ios_switchSession(ncid.toCString())
    ios_setContext(UnsafeMutableRawPointer(mutating: ncid.toCString()))
    ios_setStreams(output.stdin_file, output.stdout_file, output.stdout_file)
    thread_stdin = output.stdin_file
    thread_stdout = output.stdout_file
    thread_stderr = output.stderr_file
    if let COLUMNS = config["COLUMNS"] as? String,
        let LINES = config["LINES"] as? String {
        setenv("COLUMNS", COLUMNS, 1)
        setenv("LINES", LINES, 1)
        ios_setWindowSize(Int32(COLUMNS) ?? 80, Int32(LINES) ?? 80, ncid.toCString())
    }
    
    
    guard let args = config["args"] as? [String] else {
        return
    }
//    let pypath = Bundle.main.url(forResource: "mysdl", withExtension: "py")?.path ?? ""
//    let args = ["python3", "-u", pypath]
    let argc = args.count
    let argv = UnsafeMutableBufferPointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: args.count + 1)
    var index = 0;
    while index < args.count {
        argv[index] = args[index].utf8CString
        index += 1
    }
    let margv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>(mutating: argv.baseAddress)
    let ret = Py_BytesMain(Int32(argc), margv)
    argv.deallocate()
//    let ret = run(command: args.joined(separator: " "))
//        sleep(1)
    usleep(1000*100)
    fflush(thread_stdout)
    fflush(thread_stderr)
//        sleep(1)
    usleep(1000*100)
//    output.closeConsolePipe()
    
//    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    
    sleep(1)
//    self.extensionContext = nil
//    real_exit(vlaue: 0)
}


private func run(command: String) -> Int32 {
    NSLog("Running command: \(command)")
    return 0
    
    

    // ios_system requires these to be set to nil before command execution
    thread_stdin = nil
    thread_stdout = nil
    thread_stderr = nil

    let pid = ios_fork()
    let returnCode = ios_system(command)
    ios_waitpid(pid)
    ios_releaseThreadId(pid)

    // Flush pipes to make sure all data is read
    fflush(thread_stdout)
    fflush(thread_stderr)

    return returnCode
}


func real_exit(vlaue: Int) {
    let libsystem_b_handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
    let exit_handle = dlsym(libsystem_b_handle, "exit".toCString())
    let sexit = unsafeBitCast(exit_handle, to: exit_t.self)
    sexit(0)
}


extension String {

    func toCString() -> UnsafePointer<Int8>? {
        let nsSelf: NSString = self as NSString
        return nsSelf.cString(using: String.Encoding.utf8.rawValue)
    }

    var utf8CString: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
    }

}


