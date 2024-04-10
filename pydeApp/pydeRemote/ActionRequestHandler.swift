//
//  ActionRequestHandler.swift
//  pydeRemote
//
//  Created by Huima on 2023/11/1.
//

import UIKit
import ios_system
import python3Objc
import pydeCommon

fileprivate let USING_MULTI_INTERPRETERS = true

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    
    func beginRequest(with context: NSExtensionContext) {
        ConstantManager.pydeEnv = .remote
//        replaceCommand("flet", "flet", false)
        
        if let item = context.inputItems.first as? NSExtensionItem,
           let requestInfo = item.userInfo as? [String: Any] {
            pydeReqInfo = requestInfo
            
            if let env = requestInfo["env"] as? [String], !env.isEmpty {
                env.forEach { item in
                    ios_putenv(item.utf8CString)
                }
            }
            
            if let commands = requestInfo["commands"] as? [String] {
                
                NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notify in
                    wmessager.passMessage(message: commands, identifier: ConstantManager.PYDE_ASK_RUN_IN_UI)
                }
            }
        }
        
        
        
        initRemotePython3Sub()
        remoteExeCommands(context: context)
    }

}

//@_cdecl("flet")
//public func flet(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
//    wmessager.passMessage(message: ["open", "-a"] + cmds, identifier: ConstantManager.PYDE_OPEN_COMMAND_MSG)
//    return 0;
//}

//var python3_count = 0
//
//var python3_inited = false

//@_cdecl("python3")
//public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    python3_count += 1
//    if python3_count == 1 {
//        return python3_exec(argc: argc, argv: argv)
//    } else {
//        return pythonAMain(argc, argv)
//    }
////    return python3_exec(argc: argc, argv: argv)
////    return pydeMain(argc, argv)
//    
////    if !python3_inited {
//////        DispatchQueue.main.async {
////            
////            
////            
////            
////            initIntepreters()
////            python3_inited = true
//////        }
////        
////        while !python3_inited {
////            sleep(1)
////        }
////    }
//    
////    return python3_run(argc, argv)
////    return pydeMain(argc, argv)
////    if USING_MULTI_INTERPRETERS {
////        initIntepreters()
////        return python3_run(argc, argv)
////    }
//    
//    python3_count += 1
//    if python3_count == 1 {
//        if (argc == 1) {
//            return python3_exec(argc: argc, argv: argv)
//        } else {
////            return python3_inmain(argc: argc, argv: argv)
//            return pythonAMain(argc, argv)
//        }
//        /// 如果跑到主线程，主线程退出后收不到通知，造成无法退出，这里先跑到其它线程
//        return python3_exec(argc: argc, argv: argv)
//    } else {
//        guard let cmds = convertCArguments(argc: argc, argv: argv) else {
//            return -1
//        }
//        return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
//    }
//    
//    
//}
//
//@_cdecl("pythonA")
//public func pythonA(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    return pythonAMain(argc, argv)
//}
//
//
//@_cdecl("rremote")
//public func rremote(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard var cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
//    cmds.removeFirst()
//    return remoteReqRemoteCommands(commands: [cmds.joined(separator: " ")])
//}


//@_cdecl("open")
//public func pyde_open(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
//    wmessager.passMessage(message: cmds, identifier: ConstantManager.PYDE_OPEN_COMMAND_MSG);
//    return 1
//}
//
//@_cdecl("openurl")
//public func pyde_openurl(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    guard let cmds = convertCArguments(argc: argc, argv: argv) else {
//        return -1
//    }
//    wmessager.passMessage(message: cmds, identifier: ConstantManager.PYDE_OPEN_COMMAND_MSG);
//    return 1
//}
