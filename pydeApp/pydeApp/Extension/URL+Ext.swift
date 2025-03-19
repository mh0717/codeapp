//
//  URL+Ext.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import Foundation


extension URL {
    func isInBundle() -> Bool {
        
        // 获取应用 bundle 的标准化根路径（处理符号链接）
        let bundleRoot = Bundle.main.bundleURL
            .resolvingSymlinksInPath() // 解析符号链接
            .standardizedFileURL // 标准化路径格式
        
        let bpath = bundleRoot.path.contains(".app/PlugIns/") ? bundleRoot.deletingLastPathComponent().deletingLastPathComponent().path : bundleRoot.path
        
        print(FileManager.default.isWritableFile(atPath: bpath))
        print(FileManager.default.isWritableFile(atPath: self.path))
        
        // 标准化目标 URL
        let standardizedSelf = self
            .resolvingSymlinksInPath()
            .standardizedFileURL
        
        // 判断标准化后的路径是否包含在 bundle 路径中
        return standardizedSelf.path.hasPrefix(bpath + "/")
    }
}
