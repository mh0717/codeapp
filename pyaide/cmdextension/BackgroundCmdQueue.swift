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
