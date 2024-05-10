//
//  DownloadManager.swift
//  iPyDE
//
//  Created by Huima on 2024/4/24.
//

import Foundation
import Tiercel

class DownloadManager: ObservableObject {
    var onTaskCompletion: (() -> Void)?
    var started: Bool = false
    
    let sessionManager = SessionManager("default", configuration: SessionConfiguration())
    
    func start(_ url: URLConvertible) {
        self.started = true
        sessionManager.start(url) {[weak self] task in
            self?.objectWillChange.send()
            task.objectWillChange.send()
        }
    }
    
    func suspend(_ url: URLConvertible) {
        sessionManager.suspend(url) {[weak self] task in
            self?.objectWillChange.send()
            task.objectWillChange.send()
        }
    }
    
    func remove(_ url: URLConvertible, _ delete: Bool = false) {
        sessionManager.remove(url, completely: delete) { [weak self] task in
            self?.objectWillChange.send()
            task.objectWillChange.send()
        }
    }
    
    func download(_ url: URLConvertible) -> DownloadTask? {
        self.started = true
        return sessionManager.download(url)
    }
    
    func totalStart() {
        self.started = true
        sessionManager.totalStart { [weak self] _ in
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
        }
    }
    
    func totalSuspend() {
        sessionManager.totalSuspend { [weak self] _ in
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
        }
    }
    
    func totalCancel() {
        sessionManager.totalCancel { [weak self] _ in
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
        }
    }
    
    func totalRemove(delete: Bool = false) {
        sessionManager.totalRemove { [weak self]  _ in
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
        }
    }
    
    func totalDelete() {
        sessionManager.totalRemove { [weak self]  _ in
            self?.sessionManager.cache.clearDiskCache()
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
        }
    }
    
    func clearDisk() {
        sessionManager.cache.clearDiskCache()
        self.objectWillChange.send()
        self.sessionManager.tasks.forEach({$0.objectWillChange.send()})
    }
    
    func totalCount() -> Int {
        return sessionManager.tasks.count
    }
    
    func totalRunningCount() -> Int {
        return sessionManager.runningTasks.count
    }
    
    func totalSucceedCount() -> Int {
        return sessionManager.succeededTasks.count
    }
    
    func downloadedFilePath(_ url: URL) -> String? {
        if let task = sessionManager.fetchTask(url), task.status == .succeeded {
            return task.filePath
        }
        return nil
    }
    
    var isCompleted: Bool {
        return totalSucceedCount() == totalCount()
    }
    
    
    func setup() {
        sessionManager.progress { [weak self] (manager) in
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
        }.completion { [weak self] manager in
            self?.objectWillChange.send()
            self?.sessionManager.tasks.forEach({$0.objectWillChange.send()})
            if manager.status == .succeeded {
                // 下载成功
                if self?.started == true, let call = self?.onTaskCompletion {
                    call()
                }
            } else {
                // 其他状态
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .init("MainAppForeceUpdate"), object: nil)
            }
        }
    }
    
    static let instance = DownloadManager()
}
