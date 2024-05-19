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
import UIKit

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

@_cdecl("python3SubProcessInMain")
public func python3SubProcessInMain(argc: Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let stdin = thread_stdin
       let stdout = thread_stdout
       let stderr = thread_stderr
       var result: Int32 = 0
    if Thread.isMainThread {
        result = python3MainNotExit(argc, argv)
        return result
    }
    
    var isEnd = false
    
    let timer = Timer(timeInterval: 0.1, repeats: false) { _ in
        thread_stdin = stdin
        thread_stdout = stdout
        thread_stderr = stderr
        result = python3MainNotExit(argc, argv)
        isEnd = true
    }
    RunLoop.main.add(timer, forMode: .default)
    
    while !isEnd {
        usleep(1000 * 100)
    }
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
    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    return readRemote()
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

//feed(text: "\u{1B}]8;;http://example.com\u{1B}\\This is a link\u{1B}]8;;\u{1B}\\\r\n")

//@_cdecl("remotenode")
//public func clear__(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    vfprintf(thread_stdout, "\u{1B}[2J\u{1B}[0;0H", getVaList([]))
//    return 0
//}


public func initPyDE() {
    initClientEnv()
    
    replaceCommand("pythonA", "pythonA", false)
    replaceCommand("pythonB", "pythonB", false)
    replaceCommand("remote", "remote", false)
    replaceCommand("open", "pyde_open", false)
    replaceCommand("openurl", "openurl", false)
    replaceCommand("readremote", "readremote", false)
    replaceCommand("clear", "clear", false)
    replaceCommand("plink", "plink", false)
    
    replaceCommand("node", "ide_node", false)
    replaceCommand("npm", "ide_npm", false)
    replaceCommand("npx", "ide_npx", false)
    replaceCommand("nodeg", "ide_nodeg", false)
    
//    replaceCommand("wasm", "idewasm", false)
//    initDESubIntp()
//    replaceCommand("python3", "python3Sub", false)
    
    
    
//    initDEMainIntp()
//    replaceCommand("python3", "python3Main", false)
    
    replaceCommand("python3", "python3Process", false)
    replaceCommand("python", "python3Process", false)
    replaceCommand("python3.11", "python3Process", false)
    
//    UIViewController.swizzIt()
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
