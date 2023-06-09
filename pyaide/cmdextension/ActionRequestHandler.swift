//
//  ActionRequestHandler.swift
//  cmdextension
//
//  Created by Huima on 2023/5/5.
//

import Foundation
import UIKit
import MobileCoreServices
import Darwin
import ios_system


let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mh.Python3IDE")!


@propertyWrapper
struct Atomic<Value> {

    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}


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
    
    init(context: NSExtensionContext) {
        stdin_file = fdopen(myinputPipe.fileHandleForReading.fileDescriptor, "r")
        stdout_file = fdopen(inputPipe.fileHandleForWriting.fileDescriptor, "w")
        stderr_file = fdopen(inputErrorPipe.fileHandleForWriting.fileDescriptor, "w")
        
        setvbuf(stdin_file, nil, _IONBF, 1024);
        setvbuf(stdout_file, nil, _IONBF, 10240);
        setvbuf(stderr_file, nil, _IONBF, 1024);
    }
    
    /// Sets up the "tee" of piped output, intercepting stdout then passing it through.
    func openConsolePipe() {
//        // Copy STDOUT file descriptor to outputPipe for writing strings back to STDOUT
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

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    
    var extensionContext: NSExtensionContext?
    
    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem else {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        numPythonInterpreters = 1
        
        replaceCommand("backgroundCmdQueue", "backgroundCmdQueue", true)
        replaceCommand("python3", "python3", true)
//        replaceCommand("pythonA", "pythonA", true)
//        replaceCommand("pythonB", "pythonB", true)
        replaceCommand("mhecho", "mhecho", true)
        replaceCommand("six", "six", true)
        
        joinMainThread = true
        
        let ncid: String = item.userInfo?["identifier"] as! String
        
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
        
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        wmessager.listenForMessage(withIdentifier: "\(ncid).stop") { msg in
            real_exit(vlaue: 0)
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
        
        let output = OutputListener(context: context)
        output.openConsolePipe()
        
        
        
        var isStale = true
        
        guard let data = item.userInfo?["workingDirectoryBookmark"] as? Data else {
            return
        }
        
        let url = try! URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        _ = url.startAccessingSecurityScopedResource()
        FileManager.default.changeCurrentDirectoryPath(url.path)

        if let wdata = item.userInfo?["workspace"] as? Data {
            let url = try! URL(resolvingBookmarkData: wdata, bookmarkDataIsStale: &isStale)
            _ = url.startAccessingSecurityScopedResource()
        }
        
        
        guard let args = item.userInfo?["args"] as? [String] else {
            return
        }
        
        let END_OF_TRANSMISSION:UInt8 = 4
        var isEnd = false
        var shouldEnd = false
        
        ios_setDirectoryURL(url)
        Thread.current.name = args.joined(separator: " ")
        ios_switchSession(ncid.toCString())
        ios_setContext(UnsafeMutableRawPointer(mutating: ncid.toCString()))
        ios_setStreams(output.stdin_file, output.stdout_file, output.stdout_file)
        if let COLUMNS = item.userInfo?["COLUMNS"] as? String,
            let LINES = item.userInfo?["LINES"] as? String {
            setenv("COLUMNS", COLUMNS, 1)
            setenv("LINES", LINES, 1)
            ios_setWindowSize(Int32(COLUMNS) ?? 80, Int32(LINES) ?? 80, ncid.toCString())
        }
        
        var remoteInputHandle: FileHandle? = nil
        var remoteOutputHandle: FileHandle? = nil
        
        let inputPath = ConstantManager.appGroupContainer.appendingPathComponent("\(ncid).input").path
        let outputPath = ConstantManager.appGroupContainer.appendingPathComponent("\(ncid).output").path
        let inputQueue = DispatchQueue(label: "\(ncid).input")
        let outputQueue = DispatchQueue(label: "\(ncid).output")
        let inputHandle = output.myinputPipe.fileHandleForWriting
        let outputHandle = output.inputPipe.fileHandleForReading
        
        inputQueue.async {
            remoteInputHandle = FileHandle(forReadingAtPath: inputPath)
            remoteInputHandle?.readabilityHandler = {hd in
                let data = hd.availableData
                try? inputHandle.write(contentsOf: data)
            }
        }
        outputQueue.async {
            remoteOutputHandle = FileHandle(forWritingAtPath: outputPath)
            
            outputHandle.readabilityHandler = {hd in
                var data = [UInt8](hd.availableData)[...]
                var eof = false
                if shouldEnd && data.last == END_OF_TRANSMISSION {
                    if data.count == 1 {
                        isEnd = true
                        return
                    }
                    data = data[0...(data.count - 2)]
                    eof = true
                }

                var index = 0
                let bufferSize = 1024*4
                while index <= data.count {
                    
                    if (index + bufferSize <= data.count) {
                        try? remoteOutputHandle?.write(contentsOf: data[index..<index+bufferSize])
                    } else {
                        try? remoteOutputHandle?.write(contentsOf: data[index...])
                    }
                    index += bufferSize
                }
                if eof {
                    isEnd = true
                }
            }
        }
            
        
        _ = run(command: args.joined(separator: " "))
        shouldEnd = true
        try? output.inputPipe.fileHandleForWriting.write(contentsOf: Data([END_OF_TRANSMISSION]))
        while !isEnd {
            fflush(thread_stdout)
            fflush(thread_stderr)
            usleep(1000*50)
        }
        usleep(1000*100)
        
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        
        output.closeConsolePipe()
        remoteInputHandle = nil
        remoteOutputHandle = nil
        
        sleep(1)
        self.extensionContext = nil
        real_exit(vlaue: 0)
        
    }
    
    private func run(command: String) -> Int32 {
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
}


func real_exit(vlaue: Int) {
    let libsystem_b_handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
    let exit_handle = dlsym(libsystem_b_handle, "exit".toCString())
    let sexit = unsafeBitCast(exit_handle, to: exit_t.self)
//    sexit(0)
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






////
////  ActionRequestHandler.swift
////  ActionExt
////
////  Created by Huima on 2022/11/9.
////
//
//import UIKit
//import MobileCoreServices
//import UniformTypeIdentifiers
//
//class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
//
//    var extensionContext: NSExtensionContext?
//
//    func beginRequest(with context: NSExtensionContext) {
//        // Do not call super in an Action extension with no user interface
//        self.extensionContext = context
//
//        var found = false
//
//        // Find the item containing the results from the JavaScript preprocessing.
//        outer:
//            for item in context.inputItems as! [NSExtensionItem] {
//                if let attachments = item.attachments {
//                    for itemProvider in attachments {
//                        if itemProvider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
//                            itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil, completionHandler: { (item, error) in
//                                let dictionary = item as! [String: Any]
//                                OperationQueue.main.addOperation {
//                                    self.itemLoadCompletedWithPreprocessingResults(dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! [String: Any]? ?? [:])
//                                }
//                            })
//                            found = true
//                            break outer
//                        }
//                    }
//                }
//        }
//
//        if !found {
//            self.doneWithResults(nil)
//        }
//    }
//
//    func itemLoadCompletedWithPreprocessingResults(_ javaScriptPreprocessingResults: [String: Any]) {
//        // Here, do something, potentially asynchronously, with the preprocessing
//        // results.
//
//        // In this very simple example, the JavaScript will have passed us the
//        // current background color style, if there is one. We will construct a
//        // dictionary to send back with a desired new background color style.
//        let bgColor: Any? = javaScriptPreprocessingResults["currentBackgroundColor"]
//        if bgColor == nil ||  bgColor! as! String == "" {
//            // No specific background color? Request setting the background to red.
//            self.doneWithResults(["newBackgroundColor": "red"])
//        } else {
//            // Specific background color is set? Request replacing it with green.
//            self.doneWithResults(["newBackgroundColor": "green"])
//        }
//    }
//
//    func doneWithResults(_ resultsForJavaScriptFinalizeArg: [String: Any]?) {
//        if let resultsForJavaScriptFinalize = resultsForJavaScriptFinalizeArg {
//            // Construct an NSExtensionItem of the appropriate type to return our
//            // results dictionary in.
//
//            // These will be used as the arguments to the JavaScript finalize()
//            // method.
//
//            let resultsDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize]
//
//            let resultsProvider = NSItemProvider(item: resultsDictionary as NSDictionary, typeIdentifier: UTType.propertyList.identifier)
//
//            let resultsItem = NSExtensionItem()
//            resultsItem.attachments = [resultsProvider]
//
//            // Signal that we're complete, returning our results.
//            self.extensionContext!.completeRequest(returningItems: [resultsItem], completionHandler: nil)
//        } else {
//            // We still need to signal that we're done even if we have nothing to
//            // pass back.
//            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//        }
//
//        // Don't hold on to this after we finished with it.
//        self.extensionContext = nil
//    }
//
//}

