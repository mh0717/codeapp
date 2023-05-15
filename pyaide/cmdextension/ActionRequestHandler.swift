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
    
    /// Buffers strings written to stdout
    var contents = ""
    
    let stdoutFileDescriptor = FileHandle.standardOutput.fileDescriptor
    let stderrFileDescriptor = FileHandle.standardError.fileDescriptor
    
    let coordinator = NSFileCoordinator(filePresenter: nil)
    
    init(context: NSExtensionContext) {
        let ncid = (context.inputItems.first as? NSExtensionItem)?.userInfo?["identifier"] as! String
        
        // Set up a read handler which fires when data is written to our inputPipe
        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let strongSelf = self else { return }
            
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                wmessager.passMessage(message: string, identifier: "\(ncid).stdout")
            }
            // Write input back to stdout
            strongSelf.outputPipe.fileHandleForWriting.write(data)
        }
        
        
        
        inputErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let strongSelf = self else { return }
            
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                wmessager.passMessage(message: string, identifier: "\(ncid).stdout")
            }
            
            // Write input back to stdout
            strongSelf.outputErrorPipe.fileHandleForWriting.write(data)
        }
        
        wmessager.listenForMessage(withIdentifier: "\(ncid).input") { [self] msg in
            var msgstr = (msg as? String) ?? ""
            let msgdata = msgstr.data(using: .utf8)!
            myinputPipe.fileHandleForWriting.write(msgdata)
        }
        
        stdin_file = fdopen(myinputPipe.fileHandleForReading.fileDescriptor, "r")
        stdout_file = fdopen(inputPipe.fileHandleForWriting.fileDescriptor, "w")
        stderr_file = fdopen(inputErrorPipe.fileHandleForWriting.fileDescriptor, "w")
        
        setvbuf(stdin_file, nil, _IONBF, 1024);
        setvbuf(stdout_file, nil, _IONBF, 1024);
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
        
        numPythonInterpreters = 3
        
        replaceCommand("backgroundCmdQueue", "backgroundCmdQueue", true)
        replaceCommand("python3", "python3", true)
        replaceCommand("pythonA", "pythonA", true)
        replaceCommand("pythonB", "pythonB", true)
        replaceCommand("mhecho", "mhecho", true)
        
//        joinMainThread = false
        
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
        
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        wmessager.listenForMessage(withIdentifier: "\(ncid).stop") { msg in
            real_exit(vlaue: 0)
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
        
        
        guard let args = item.userInfo?["args"] as? [String] else {
            return
        }
        
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            let str = readLine()
//            print("cmdextension echo main: \(str ?? "")\n")
//            sleep(3)
//        }
        
//        let str = readLine()
//        print("cmdextension ec: \(str ?? "")\n")
//        wmessager.passMessage(message: "cmdextension echo: \(str ?? "")", identifier: "\(ncid).stdout")
        
        print("pid: \(getpid())")
        
        ios_setDirectoryURL(url)
        Thread.current.name = args.joined(separator: " ")
        ios_switchSession(ncid.toCString())
        ios_setContext(UnsafeMutableRawPointer(mutating: ncid.toCString()))
        ios_setStreams(output.stdin_file, output.stdout_file, output.stdout_file)
        
        
        let ret = run(command: args.joined(separator: " "))
        sleep(1)
        
        
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        
        sleep(5)
        output.closeConsolePipe()
        self.extensionContext = nil
        
        real_exit(vlaue: 0)
        
//        DispatchQueue.global(qos: .default).async {
////            NodeRunner.startEngine(withArguments: args)
//
//            let str = readLine()
//
//
//            sleep(5)
//
//            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                output.closeConsolePipe()
//                self.extensionContext = nil
//                exit(0)
//            }
//
//        }
    }
    
    private func run(command: String) -> Int32 {
        NSLog("Running command: \(command)")

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
