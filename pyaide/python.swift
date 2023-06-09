import Dynamic
import Foundation
import MobileCoreServices
import ios_system


//typealias RequestCancellationBlock = @convention(block) (_ uuid: UUID?, _ error: Error?) -> Void
//typealias RequestInterruptionBlock = @convention(block) (_ uuid: UUID?) -> Void
//typealias RequestCompletionBlock = @convention(block) (_ uuid: UUID?, _ extensionItems: [Any]?) ->
//    Void
//typealias RequestBeginBlock = @convention(block) (_ uuid: UUID?) -> Void
//

private func command(args: [String]) -> Int32 {
    let ntidentifier = String.init(cString: ios_getContext().assumingMemoryBound(to: Int8.self), encoding: .utf8)!


    var ended = false

    // We use a private API here to launch an extension programatically
    let BLE: AnyClass = (NSClassFromString("TlNFeHRlbnNpb24=".base64Decoded()!)!)
    let ext = Dynamic(BLE).extensionWithIdentifier("baobaowang.pyaide.cmdextension", error: nil)

    ext.setRequestCancellationBlock(
        { uuid, error in
            if let uuid = uuid, let error = error {
                print("Request \(uuid) cancelled. \(error)")
                ended = true
            }
        } as RequestCancellationBlock)

    ext.setRequestInterruptionBlock(
        { uuid in
            if let uuid = uuid {
                print("Request \(uuid) interrupted.")
                wmessager.passMessage(message: "Program interrupted. This could be caused by a memory limit or an error in your code.\n", identifier: "\(ntidentifier).stdout")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    ended = true
                }
            }
        } as RequestInterruptionBlock)

    ext.setRequestCompletionBlock(
        { uuid, extensionItems in
            if let uuid = uuid {
                print(
                    "Request \(uuid) completed. Extension items: \(String(describing: extensionItems))"
                )
            }

            if let item = extensionItems?.first as? NSExtensionItem {
                if let data = item.userInfo?["result"] as? String {
                    wmessager.passMessage(message: data, identifier: "\(ntidentifier).stdout")
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                ended = true
            }
        } as RequestCompletionBlock)

    let workingDir = ios_getLogicalPWD(ntidentifier.utf8CString) ?? FileManager.default.currentDirectoryPath
    let workspace = String.init(cString: ios_getenv("WORKSPACE"), encoding: .utf8) ?? workingDir
    guard let bookmark = try? URL(fileURLWithPath: workingDir).bookmarkData() else {
        return 0
    }
    guard let wbookmark = try? URL(fileURLWithPath: workspace).bookmarkData() else {
        return 0
    }

    let item = NSExtensionItem()

    item.userInfo = [
        "workingDirectoryBookmark": bookmark,
        "args": args,
        "identifier": ntidentifier,
        "workspace": wbookmark,
        "COLUMNS": String(cString: ios_getenv("COLUMNS"), encoding: .utf8) ?? "80",
        "LINES": String(cString: ios_getenv("LINES"), encoding: .utf8) ?? "80",
    ]
    
    setvbuf(thread_stdout, nil, _IONBF, 0)
    setvbuf(thread_stderr, nil, _IONBF, 0)
    setvbuf(thread_stdin, nil, _IONBF, 0)
    let inputPath = ConstantManager.appGroupContainer.appendingPathComponent("\(ntidentifier).input").path
    let outputPath = ConstantManager.appGroupContainer.appendingPathComponent("\(ntidentifier).output").path
    let inputQueue = DispatchQueue(label: "\(ntidentifier).input")
    let outputQueue = DispatchQueue(label: "\(ntidentifier).output")
    let inputHandle = FileHandle(fileDescriptor: fileno(thread_stdin))
    let outputHandle = FileHandle(fileDescriptor: fileno(thread_stdout))
    var remoteInputHandle: FileHandle? = nil
    var remoteOutputHandle: FileHandle? = nil
    inputQueue.async {
        mkfifo(inputPath, 0x1FF)
        remoteInputHandle = FileHandle(forWritingAtPath: inputPath)
        inputHandle.readabilityHandler = {[weak remoteInputHandle] hd in
            let data = hd.availableData
            /// 分割发送，避免一次写入太大数据块错误
            var index = 0
            let bufferSize = 1024*4
            while index <= data.count {
                if (index + bufferSize <= data.count) {
                    try? remoteInputHandle?.write(contentsOf: data[index..<index+bufferSize])
                } else {
                    try? remoteInputHandle?.write(contentsOf: data[index...])
                }
                index += bufferSize
            }
        }
    }
    outputQueue.async {
        mkfifo(outputPath, 0x1FF)
        remoteOutputHandle = FileHandle(forReadingAtPath: outputPath)!
        remoteOutputHandle?.readabilityHandler = { hd in
            let data = hd.availableData
            try?  outputHandle.write(contentsOf: data)
        }
    }
    
    ext.beginExtensionRequestWithInputItems(
        [item],
        completion: { uuid in
            let pid = ext.pid(forRequestIdentifier: uuid)
            if let uuid = uuid {
                print("Started extension request: \(uuid). Extension PID is \(pid)")
            }
        } as RequestBeginBlock)

    while ended != true {
        usleep(1000*50)
    }
    
    try? remoteInputHandle?.close()
    try? remoteOutputHandle?.close()
    try? FileManager.default.removeItem(atPath: inputPath)
    try? FileManager.default.removeItem(atPath: outputPath)
    
    return 0
}

@_cdecl("python3")
public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    return Py_BytesMain(argc, argv)
//    let args = convertCArguments(argc: argc, argv: argv)!
//
//    return command(args: args)
    
    python3_run(argc, argv)
}

@_cdecl("pro")
public func pro(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    var args = convertCArguments(argc: argc, argv: argv)!
    args.removeFirst()
    return command(args: args)
    let session = ios_getContext()
    setvbuf(thread_stdout, nil, _IONBF, 0)
    setvbuf(thread_stderr, nil, _IONBF, 0)
    setvbuf(thread_stdin, nil, _IONBF, 0)
    let uuid = args[1]
    let inputPath = ConstantManager.appGroupContainer.appendingPathComponent("\(uuid).input").path
    let outputPath = ConstantManager.appGroupContainer.appendingPathComponent("\(uuid).output").path
    let inputQueue = DispatchQueue(label: "\(uuid).input")
    let outputQueue = DispatchQueue(label: "\(uuid).output")
    let inputFile = thread_stdin
    let outputFile = thread_stdout
    let outputHandle = FileHandle(fileDescriptor: fileno(outputFile))
    var remoteInputHandle: FileHandle? = nil
    var remoteOutputHandle: FileHandle? = nil
    /*inputQueue.async {
        mkfifo(inputPath, 0x1FF)
//        let buffer = UnsafeMutableRawPointer.allocate(byteCount: 1024, alignment: 8)
//        let file = fopen(inputPath, "rw")
        remoteInputHandle = FileHandle(forWritingAtPath: inputPath)
        let inHandle = FileHandle(fileDescriptor: fileno(inputFile))
        inHandle.readabilityHandler = {[weak remoteInputHandle] hd in
            let data = hd.availableData
            try? remoteInputHandle?.write(contentsOf: data)
        }
        
//        var rlen = fread(buffer, 1, 10, inputFile)
//        while rlen > 0 {
//            fileHandle?.write(Data(bytes: buffer, count: rlen))
//            rlen = fread(buffer, 1, 10, inputFile)
//        }
//        buffer.deallocate()
//        try? fileHandle?.close()
//        try? FileManager.default.removeItem(atPath: inputPath)
    }*/
    outputQueue.async {
        mkfifo(outputPath, 0x1FF)
        remoteOutputHandle = FileHandle(forReadingAtPath: outputPath)!
        let len = fpathconf(remoteOutputHandle!.fileDescriptor, _PC_PIPE_BUF)
        print("pipe buffer is: \(len)")
        remoteOutputHandle?.readabilityHandler = { hd in
            let data = Data(hd.availableData)
//            data.withUnsafeBytes { buffer in
////                fwrite(buffer, 1, data.count, outputFile)
////                fflush(outputFile)
//                outputHandle.write(contentsOf: data)
//            }
//            try?  outputHandle.write(contentsOf: data)
//            outputQueue.async {
////                try?  outputHandle.write(contentsOf: data)
//
////                try? outputHandle.write(contentsOf: "u".data(using: .utf8)!)
//            }
            ios_switchSession(session)
//            print(data)
//            print("data: \([UInt8](data[(data.count - 6)...]))")
            try?  outputHandle.write(contentsOf: data)
            
            if (data.count < 5) {
                for m: UInt8 in data {
                    print(m)
                }
            }
        }
//        var data = try? fileHandler?.read(upToCount: 10)
//        while let ndata = data, !ndata.isEmpty {
//            _ = ndata.withUnsafeBytes { buffer in
//                fwrite(buffer, 1, ndata.count, outputFile)
//                fflush(outputFile)
//            }
//            data = try? fileHandler?.read(upToCount: 10)
//        }
//        try? fileHandler?.close()
//        try? FileManager.default.removeItem(atPath: outputPath)
    }
    
    let result = command(args: args)
    try? remoteInputHandle?.close()
    try? remoteOutputHandle?.close()
    try? FileManager.default.removeItem(atPath: inputPath)
    try? FileManager.default.removeItem(atPath: outputPath)
    return result
}

//private var runed = false
//@_cdecl("pythonA")
//public func pythonA(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    if (!runed) {
//        runed = true
//        return Py_BytesMain(argc, argv)
//    }
//
//    let args = convertCArguments(argc: argc, argv: argv)!
//
//    return command(args: args)
//}
//
//@_cdecl("pythonB")
//public func pythonB(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    let args = convertCArguments(argc: argc, argv: argv)!
//
//    return command(args: args)
//}


@_cdecl("backgroundCmdQueue")
public func backgroundCmdQueue(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    
    return command(args: ["backgroundCmdQueue"])
}


private func uicommand(args: [String]) -> Int32 {
    let ntidentifier = String.init(cString: ios_getContext().assumingMemoryBound(to: Int8.self), encoding: .utf8)!
    
    
    var ended = false
    
    let workingDir = ios_getLogicalPWD(ntidentifier.utf8CString) ?? FileManager.default.currentDirectoryPath
    let workspace = String.init(cString: ios_getenv("WORKSPACE"), encoding: .utf8) ?? workingDir
    guard let bookmark = try? URL(fileURLWithPath: workingDir).bookmarkData() else {
        return 0
    }
    guard let wbookmark = try? URL(fileURLWithPath: workspace).bookmarkData() else {
        return 0
    }

    let userInfo: [String: Any] = [
        "workingDirectoryBookmark": bookmark,
        "args": args,
        "identifier": ntidentifier,
        "workspace": wbookmark,
        "COLUMNS": String(cString: ios_getenv("COLUMNS"), encoding: .utf8) ?? "80",
        "LINES": String(cString: ios_getenv("LINES"), encoding: .utf8) ?? "80",
    ]
    let item = NSKeyedArchiver.archivedData(withRootObject: userInfo)
    
    let toVC = UIActivityViewController(activityItems: [item], applicationActivities: nil)
//    present(toVC, animated: true, completion: nil)
    return 0
}
