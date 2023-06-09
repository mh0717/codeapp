import Dynamic
import Foundation
import MobileCoreServices
import ios_system


typealias RequestCancellationBlock = @convention(block) (_ uuid: UUID?, _ error: Error?) -> Void
typealias RequestInterruptionBlock = @convention(block) (_ uuid: UUID?) -> Void
typealias RequestCompletionBlock = @convention(block) (_ uuid: UUID?, _ extensionItems: [Any]?) ->
    Void
typealias RequestBeginBlock = @convention(block) (_ uuid: UUID?) -> Void


private func convertCArguments(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?)
    -> [String]?
{

    var args = [String]()

    for i in 0..<Int(argc) {

        guard let argC = argv?[i] else {
            return nil
        }

        let arg = String(cString: argC)

        args.append(arg)

    }

    return args
}

extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}



private func command(args: [String]) -> Int32 {
//    let ntidentifier = String.init(cString: ios_getContext().assumingMemoryBound(to: Int8.self), encoding: .utf8)!
    let ntidentifier = "ntidentifier"
    
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

    let workingDir = FileManager.default.currentDirectoryPath
    guard let bookmark = try? URL(fileURLWithPath: workingDir).bookmarkData() else {
        return 0
    }

    let item = NSExtensionItem()

    item.userInfo = ["workingDirectoryBookmark": bookmark, "args": args, "identifier": ntidentifier]
    
    ext.beginExtensionRequestWithInputItems(
        [item],
        completion: { uuid in
            let pid = ext.pid(forRequestIdentifier: uuid)
            if let uuid = uuid {
                print("Started extension request: \(uuid). Extension PID is \(pid)")
            }
        } as RequestBeginBlock)

    while ended != true {
        sleep(UInt32(1))
    }
    
    return 0
}

private var isrunning = false

@_cdecl("python3")
public func python3(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    if (!isrunning) {
        isrunning = true
        return Py_BytesMain(argc, argv)
    }
    
    initIntepreters()
    return python3_run(argc, argv)
}

@_cdecl("pythonA")
public func pythonA(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    initIntepreters()
    
    if (!isrunning) {
        isrunning = true
//        return Py_BytesMain(argc, argv)
        return python3_run(argc, argv)
    }
    
    
    return python3_run(argc, argv)
}

@_cdecl("pythonB")
public func pythonB(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    if (!isrunning) {
        isrunning = true
        return Py_BytesMain(argc, argv)
    }
    
    initIntepreters()
    return python3_run(argc, argv)
}

//@_cdecl("mhecho")
//public func mhecho(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//    return command(args: ["echo", "hahahahahahahehehehe"])
//}


//@_cdecl("backgroundCmdQueue")
//public func backgroundCmdQueue(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
//
//    return command(args: ["backgroundCmdQueue"])
//}
//

