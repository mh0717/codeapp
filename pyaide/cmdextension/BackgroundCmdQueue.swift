//
//  BackgroundCmdQueue.swift
//  Code
//
//  Created by Huima on 2023/5/11.
//

import Foundation
import ios_system

private func run(command: String) -> Int32 {
    NSLog("Running command: \(command)")

    // ios_system requires these to be set to nil before command execution
//    thread_stdin = nil
//    thread_stdout = nil
//    thread_stderr = nil

    let pid = ios_fork()
    let returnCode = ios_system(command)
    ios_waitpid(pid)
    ios_releaseThreadId(pid)

    // Flush pipes to make sure all data is read
    fflush(thread_stdout)
    fflush(thread_stderr)

    return returnCode
}

@_cdecl("backgroundCmdQueue")
public func backgroundCmdQueue(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    
    while (true) {
        let line = readLine()
        if (line == nil || line!.isEmpty) {return 0}
        run(command: line!)
    }
    
    return 0
}


@_cdecl("six")
public func six(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let sixel: [UInt8] = [27,  80,  113,  34,  49,  59,  49,  59,  49,  48,  48,  59,  49,  48,  48,  35,  48,  59,  49,  59,  49,  50,  48,  59,  52,  57,  59,  49,  48,  48,  35,  49,  59,  49,  59,  49,  56,  48,  59,  54,  55,  59,  57,  49,  35,  50,  59,  49,  59,  49,  56,  48,  59,  52,  57,  59,  49,  48,  48,  35,  51,  59,  49,  59,  48,  59,  52,  57,  59,  49,  48,  48,  35,  52,  59,  49,  59,  50,  52,  48,  59,  52,  57,  59,  49,  48,  48,  35,  53,  59,  49,  59,  50,  49,  50,  59,  53,  50,  59,  57,  52,  35,  54,  59,  49,  59,  57,  48,  59,  52,  55,  59,  54,  54,  35,  55,  59,  49,  59,  50,  57,  52,  59,  51,  51,  59,  49,  48,  48,  35,  56,  59,  49,  59,  51,  50,  50,  59,  54,  48,  59,  56,  53,  35,  57,  59,  49,  59,  48,  59,  57,  55,  59,  48,  35,  48,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  48,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  48,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  48,  33,  57,  48,  66,  35,  49,  33,  49,  48,  64,  36,  35,  51,  33,  57,  48,  123,  35,  50,  33,  49,  48,  125,  45,  35,  51,  33,  57,  48,  126,  35,  50,  33,  49,  48,  126,  45,  35,  51,  33,  57,  48,  126,  35,  50,  33,  49,  48,  126,  45,  35,  51,  33,  57,  48,  78,  35,  50,  33,  49,  48,  126,  36,  35,  52,  33,  57,  48,  111,  45,  33,  57,  48,  126,  35,  50,  33,  49,  48,  126,  45,  35,  52,  33,  57,  48,  126,  35,  49,  33,  49,  48,  125,  36,  35,  50,  33,  57,  48,  63,  33,  49,  48,  64,  45,  35,  52,  33,  57,  48,  78,  35,  49,  33,  49,  48,  126,  36,  35,  53,  33,  57,  48,  111,  45,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  53,  33,  57,  48,  66,  35,  49,  33,  49,  48,  126,  36,  35,  54,  33,  57,  48,  123,  45,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  55,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  55,  33,  57,  48,  78,  35,  49,  33,  49,  48,  126,  36,  35,  56,  33,  57,  48,  111,  45,  33,  57,  48,  126,  35,  49,  33,  49,  48,  126,  45,  35,  56,  33,  57,  48,  66,  35,  49,  33,  49,  48,  78,  36,  35,  57,  33,  57,  48,  75,  27,  92, 0]
    
    let f = FileHandle(fileDescriptor: fileno(thread_stdout))
    try? f.write(contentsOf: sixel)
    
    return 0
}
