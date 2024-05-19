//
//  Download.swift
//  Code
//
//  Created by Huima on 2024/5/16.
//

import Foundation
import ios_system
import pydeCommon


@_cdecl("dlfile")
public func dlfile(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let cmds = convertCArguments(argc: argc, argv: argv), cmds.count >= 2 else {
        return -1
    }
    
    guard let url = URL(string: cmds[1]) else {
        return -1
    }
    
    _ = DownloadManager.instance.download(url)
    return 0
}

@_cdecl("dlpath")
public func dlpath(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let cmds = convertCArguments(argc: argc, argv: argv), cmds.count >= 2 else {
        return -1
    }
    
    guard let url = URL(string: cmds[1]) else {
        return -1
    }
    
    guard let path = DownloadManager.instance.downloadedFilePath(url) else {
        return -1
    }
    
    vfprintf(thread_stdout, "\(path)\n", getVaList([]))
    return 0
}

