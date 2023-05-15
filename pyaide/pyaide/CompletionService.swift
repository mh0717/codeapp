//
//  CompletionService.swift
//  Code
//
//  Created by Huima on 2023/5/12.
//

import Foundation
import ios_system

class CompletionResult {
    let vid: Int
    let suggestions: [String]
    let completions: [String]
    let suggestionsType: [String: String]
    let signatures: [String: String]
    let signature: String?
    
    init(vid: Int, suggestions: [String], completions: [String], suggestionsType: [String : String], signatures: [String : String], signature: String?) {
        self.vid = vid
        self.suggestions = suggestions
        self.completions = completions
        self.suggestionsType = suggestionsType
        self.signatures = signatures
        self.signature = signature
    }
}

private class RequestItem {
    let uid: String
    let requestCmd: String
    var requestedDate: Date?
    let continuation: UnsafeContinuation<CompletionResult?, Never>
    
    init(uid: String, requestCmd: String, requestedDate: Date? = nil, continuation: UnsafeContinuation<CompletionResult?, Never>) {
        self.uid = uid
        self.requestCmd = requestCmd
        self.requestedDate = requestedDate
        self.continuation = continuation
    }
}


class CompletionService {
    public static let instance = CompletionService()
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.checkQueue()
        }
    }
    
    private var _serviceRunning = false
    private var requestQueue: [RequestItem] = []
    
    public var serviceRunning: Bool {
        get {
            return _serviceRunning
        }
    }
    public lazy var CompletionServiceId: String = {
        return "CompletionService\(UUID().uuidString)"
    }()
    
    func startService(){
        if (_serviceRunning) {return}
        _serviceRunning = true
        
        wmessager.listenForMessage(withIdentifier: "\(CompletionServiceId).stdout") { msg in
            guard let msg = msg as? String, let json = try? JSONSerialization.jsonObject(with: msg.data(using: .utf8)!) as? [String: Any] else {return}
            
            let vid = Int(json["vid"] as? String ?? "0") ?? 0
            let suggestions = json["suggestions"] as? [String] ?? []
            let completions = json["completions"] as? [String] ?? []
            let suggestionsType = json["suggestionsType"] as? [String: String] ?? [:]
            let signatures = json["signatures"] as? [String: String] ?? [:]
            let signature = json["signature"] as? String ?? ""
            let uid = json["uid"] as? String ?? ""
            
            let result = CompletionResult(
                vid: vid,
                suggestions: suggestions,
                completions: completions,
                suggestionsType: suggestionsType,
                signatures: signatures,
                signature: signature
            )
            
            self.requestQueue.removeAll { item in
                if item.uid == uid {
                    item.continuation.resume(returning: result)
                    return true
                }
                return false
            }
        }
        
        Task.init {
            ios_switchSession(CompletionServiceId.toCString())
            ios_setContext(CompletionServiceId.toCString())
            let pid = ios_fork()
            ios_system("backgroundCmdQueue")
            ios_waitpid(pid)
            ios_releaseThreadId(pid)
            ios_closeSession(CompletionServiceId.toCString())
            
            wmessager.stopListeningForMessage(withIdentifier: "\(CompletionServiceId).stdout")
            _serviceRunning = false
        }
    }
    
    private func checkQueue() {
        if (!_serviceRunning) {
            self.startService()
            return
        }
        
        var requesting = false
        requestQueue.removeAll { item in
            if let date = item.requestedDate {
                if (date.timeIntervalSinceNow < -5) {
                    /// timeout
                    item.continuation.resume(returning: nil)
                    return true
                }
                else {
                    requesting = true
                }
            }
            return false
        }
        if (requesting) {return}
        
        
        while requestQueue.count > 1 {
            let req = requestQueue.removeFirst()
            req.continuation.resume(returning: nil)
        }
        
        if var req = requestQueue.first {
            wmessager.passMessage(message: req.requestCmd + "\n", identifier: "\(CompletionServiceId).input")
            req.requestedDate = Date()
        }
    }
    
    
    func requestCompletion(vid: Int, path: String, index: Int, getDefinition: Bool = false) async -> CompletionResult? {
        return await withUnsafeContinuation({ continuation in
            let uid = UUID().uuidString
            let reqCmd = "python3 -m _ccmp \(vid) \(path) \(index) \(getDefinition ? "True" : "False") \(uid)"
            let item = RequestItem(
                uid: uid,
                requestCmd: reqCmd,
                requestedDate: nil,
                continuation: continuation
            )
            requestQueue.append(item)
        })
        
    }
}
