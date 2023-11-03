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
        replaceCommand("python3", "python3", true)
        replaceCommand("rremote", "rremote", true)
        
        initRemoteEnv()
        
        remoteExeCommands(context: context)
    }

}


@_cdecl("python3")
public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    return python3_inmain(argc: argc, argv: argv)
}


@_cdecl("rremote")
public func rremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    cmds.removeFirst()
    return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
}
