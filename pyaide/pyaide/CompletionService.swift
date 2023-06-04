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
    
    static func parseJson(jsonstr: String?) -> CompletionResult? {
        guard let jsonstr = jsonstr, !jsonstr.isEmpty else {return nil}
        guard let json = try? JSONSerialization.jsonObject(with: jsonstr.data(using: .utf8)!) as? [String: Any] else {
            print("completion result error: \(jsonstr)")
            return nil
        }
        
        if (json.keys.contains("exception")) {
            print("completion result error: \(json["exception"] ?? "")")
            return nil
        }
        
        let vid = json["vid"] as? Int ?? Int(json["vid"] as? String ?? "0") ?? 0
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
        
        return result
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
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
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
    
    private func onReceiveMsg(msg: String) {
        guard let json = try? JSONSerialization.jsonObject(with: msg.data(using: .utf8)!) as? [String: Any] else {
            print("completion result error: \(msg)")
            return
        }
        
        if (json.keys.contains("exception")) {
            print("completion result error: \(json["exception"] ?? "")")
            let uid = json["uid"] as? String ?? ""
            self.requestQueue.removeAll { item in
                if item.uid == uid {
                    item.continuation.resume(returning: nil)
                    return true
                }
                return false
            }
            return
        }
        
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
    
    func startService(){
        return
        if (_serviceRunning) {return}
        _serviceRunning = true
        
        var msgBuffer = ""
        wmessager.listenForMessage(withIdentifier: "\(CompletionServiceId).stdout") { [weak self] msg in
            guard let self = self else {return}
            guard let msg = msg as? String else {return}
            if (!msg.contains("\n")) {
                msgBuffer += msg
                return
            }else {
                var msgitems = (msgBuffer + msg).components(separatedBy: "\n")
                msgBuffer = msgitems.popLast()!
                for msg in msgitems {
                    self.onReceiveMsg(msg: msg)
                }
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

private let _completionQueue = DispatchQueue(label: "completion.queue")
//private var _nextRequest: (UnsafeContinuation<CompletionResult?, Never>, ()->CompletionResult?)? = nil
func completeCode(code: String, path: String, index: Int, getdef: Bool, vid: Int) async -> CompletionResult? {
    return nil
    let result = await withUnsafeContinuation({ continuation in
        _completionQueue.async {
            let str = pycompleteCode(code, path, Int32(index), getdef, Int32(vid), UUID().uuidString)
            let result = CompletionResult.parseJson(jsonstr: str)
            continuation.resume(returning: result)
        }
    })
    
    return result
}
