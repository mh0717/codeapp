//
//  node.swift
//  Code
//
//  Created by Huima on 2024/5/12.
//

import Foundation
import ios_system
import pydeCommon

@_cdecl("ide_node")
public func ide_node(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let args = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }
    
    
    if args.count == 1 {
        // \nREPL is unavailable in Code App.\n
        fputs("Welcome to Node.js v18.19.0. ", thread_stderr)
        return 1
    }
    
    let result = clientReqCommands(commands: [args.joined(separator: " ")])
    return result
}

@_cdecl("ide_npm")
public func ide_npm(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard var args = convertCArguments(argc: argc, argv: argv) else {
        return -1
    }

//    if args == ["npm", "init"] {
//        fputs("User input is unavailable, use npm init -y instead\n", thread_stderr)
//        return 1
//    }

    args.removeFirst()  // Remove `npm`
    
    var packagejson = URL(fileURLWithPath: FileManager().currentDirectoryPath)
    
    if let context = ios_getContext() {
        if let lurl = ios_getLogicalPWD(context) {
            let url = URL(fileURLWithPath: lurl)
            packagejson = url
        }
    }
    
    packagejson.appendPathComponent("package.json")

    if !FileManager.default.fileExists(atPath: packagejson.path) {
        try? "{}".write(to: packagejson, atomically: true, encoding: .utf8)
    }

    if ["start", "test", "restart", "stop"].contains(args.first) {
        args = ["run"] + args
    }

    if args.first == "run" {

        guard args.count > 1 else {
            return 1
        }

//        var workingPath = FileManager.default.currentDirectoryPath
//        if !workingPath.hasSuffix("/") {
//            workingPath.append("/")
//        }
//        workingPath.append("package.json")
        var workingPath = packagejson.path

        do {
            let data = try Data(
                contentsOf: URL(fileURLWithPath: workingPath), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let jsonResult = jsonResult as? [String: AnyObject],
                let scripts = jsonResult["scripts"] as? [String: String]
            {
                if var script = scripts[args[1]] {

                    guard let cmd = script.components(separatedBy: " ").first else {
                        return 1
                    }
                    if cmd == "node" {
                        let result = clientReqCommands(commands: [script])
                        return result
                    }

                    script.removeFirst(cmd.count)

                    if script.hasPrefix(" ") {
                        script.removeFirst()
                    }

                    let cmdArgs = script.components(separatedBy: " ")

                    // Checking for globally installed bin
//                    let nodeBinPath = appGroupSharedLibrary.appendingPathComponent("lib/bin").path
                    let nodeBinPath = ConstantManager.HOME.appendingPathComponent("lib/bin").path
                    let nodeBinUrl = ConstantManager.HOME.appendingPathComponent("lib/bin")

                    if let paths = try? FileManager.default.contentsOfDirectory(atPath: nodeBinPath)
                    {
                        print(nodeBinPath)
                        for i in paths {
                            let binCmd = i.replacingOccurrences(of: nodeBinPath, with: "")
                            if cmd == binCmd {
                                let moduleURL = nodeBinUrl.appendingPathComponent(cmd)
                                .resolvingSymlinksInPath()

                                let prettierPath = moduleURL.path

                                if var content = try? String(contentsOf: moduleURL) {
                                    if !content.contains("process.exit = () => {}") {
                                        content = content.replacingOccurrences(
                                            of: "#!/usr/bin/env node",
                                            with: "#!/usr/bin/env node\nprocess.exit = () => {}")
                                        try? content.write(
                                            to: moduleURL, atomically: true, encoding: .utf8)
                                    }
                                }

                                print(["node", prettierPath, script])
                                let result = clientReqCommands(commands: ["node \(prettierPath) \(script)"])
                                return result
//                                return launchCommandInExtension(args: [
//                                    "node", prettierPath, script,
//                                ])
                            }
                        }
                    }

                    // Checking for locally installed bin
//                    var bin = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    var bin = packagejson.deletingLastPathComponent()
                    bin.appendPathComponent("node_modules/.bin/\(cmd)")
                    bin.resolveSymlinksInPath()

                    guard FileManager.default.fileExists(atPath: bin.path) else {
                        fputs(
                            "npm ERR! command doesn't exist or is not supported: \(scripts[args[1]]!)\n",
                            thread_stderr)
                        return 1
                    }

                    if var content = try? String(contentsOf: bin) {
                        if !content.contains("process.exit = () => {}") {
                            content = content.replacingOccurrences(
                                of: "#!/usr/bin/env node",
                                with: "#!/usr/bin/env node\nprocess.exit = () => {}")
                            try? content.write(to: bin, atomically: true, encoding: .utf8)
                        }
                    }

//                    return launchCommandInExtension(args: ["node", bin.path] + cmdArgs)
                    let command = (["node", bin.path] + cmdArgs).joined(separator: " ")
                    let result = clientReqCommands(commands: [command])
                    return result
                } else {
                    fputs("npm ERR! missing script: \(args[1])\n", thread_stderr)
                }
            }
        } catch {
            fputs(error.localizedDescription, thread_stderr)
        }

        return 1
    }

    let npmURL = ConstantManager.NPM_BIN.appendingPathComponent("npm").resolvingSymlinksInPath()
    args = ["node", "--optimize-for-size", npmURL.path] + args

//    return launchCommandInExtension(args: args)
    let result = clientReqCommands(commands: [args.joined(separator: " ")])
    return result
}

@_cdecl("ide_npx")
public func ide_npx(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {

    var args = convertCArguments(argc: argc, argv: argv)!

    guard args.count > 1 else {
        return 1
    }

    args.removeFirst()  // Remove `npx`

    let cmd = args.first!
   
    
    var bin = URL(fileURLWithPath: FileManager().currentDirectoryPath)
    
    if let context = ios_getContext() {
        if let lurl = ios_getLogicalPWD(context) {
            let url = URL(fileURLWithPath: lurl)
            bin = url
        }
    }
    
    bin.appendPathComponent("node_modules/.bin/\(cmd)")

    guard FileManager.default.fileExists(atPath: bin.path) else {
        fputs(
            "npm ERR! command doesn't exist or is not supported: \(args.joined(separator: " "))\n",
            thread_stderr)
        return 1
    }

    bin.resolveSymlinksInPath()

    if var content = try? String(contentsOf: bin) {
        if !content.contains("process.exit = () => {}") {
            content = content.replacingOccurrences(
                of: "#!/usr/bin/env node", with: "#!/usr/bin/env node\nprocess.exit = () => {}")
            try? content.write(to: bin, atomically: true, encoding: .utf8)
        }
    }

    args.removeFirst()
    
    let command = (["node", bin.path] + args).joined(separator: " ")
    let result = clientReqCommands(commands: [command])
    return result
}

@_cdecl("ide_nodeg")
public func ide_nodeg(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    var args = convertCArguments(argc: argc, argv: argv)!

    let moduleURL = ConstantManager.HOME.appendingPathComponent("lib/bin/\(args.removeFirst())")
        .resolvingSymlinksInPath()

    let prettierPath = moduleURL.path

    if var content = try? String(contentsOf: moduleURL) {
        if !content.contains("process.exit = () => {}") {
            content = content.replacingOccurrences(
                of: "#!/usr/bin/env node", with: "#!/usr/bin/env node\nprocess.exit = () => {}")
            try? content.write(to: moduleURL, atomically: true, encoding: .utf8)
        }
    }

    args = ["node", prettierPath] + args  // + ["--prefix", workingPath]

    let result = clientReqCommands(commands: [args.joined(separator: " ")])
    return result
}

