//
//  ActionRequestHandler.swift
//  pydeRemote
//
//  Created by Huima on 2023/11/1.
//

import UIKit
import ios_system
import python3_objc
import pydeCommon

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    
    func beginRequest(with context: NSExtensionContext) {
        DispatchQueue.main.async {
            print(RunLoop.current)
        }
        
        replaceCommand("python3", "python3", true)
        replaceCommand("rremote", "rremote", true)
        
        initRemoteEnv()
        
        remoteExeCommands(context: context)
    }

}

var python3_count = 0

@_cdecl("python3")
public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    python3_count += 1
    if python3_count == 1 {
        if (argc == 1) {
            return python3_exec(argc: argc, argv: argv)
        } else {
            return python3_inmain(argc: argc, argv: argv)
        }
    } else {
        guard let cmds = convertCArguments(argc: argc, argv: argv) else {
            return -1
        }
        return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
    }
    
    
}


@_cdecl("rremote")
public func rremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    cmds.removeFirst()
    return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
}
