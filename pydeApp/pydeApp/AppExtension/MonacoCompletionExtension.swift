//
//  MonacoCompletionExtension.swift
//  pydeApp
//
//  Created by Huima on 2024/2/21.
//

import SwiftUI
import SwiftTerm
import ios_system
import pydeCommon
import pyde

class MonacoCompletionExtension: CodeAppExtension {
    
    private weak var App: MainApp!
    
    private var inputView: InputCompletionView!
    private var completionRange: [String: Any]?
    
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        self.App = app
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(5))) {
            
            self.inputView = InputCompletionView(hasSuggestion: false)
            self.inputView.delegate = self
            app.monacoInstance.monacoWebView.addInputAccessoryView(toolbar: self.inputView)
            
            let coordinator = Coordinator()
            coordinator.onCompletionResult = {[weak self] (result, range) in
                if let self {
                    DispatchQueue.main.async {
                        self.inputView.reloadCompletion(result: result)
                    }
                }
            }
            let contentManager = app.monacoInstance.monacoWebView.configuration.userContentController
            contentManager.addScriptMessageHandler(coordinator, contentWorld: .page, name: "replyMessageHandler")
            
            app.monacoInstance.executeJavascript(
                command: completionJS, printResponse: true
            )
            
//            let wshandler = WebSocketHandler(webView: app.monacoInstance.monacoWebView, adapter: LSPFrameAdaptor())
//            wshandler.onSavedFile = {
//                await app.saveCurrentFile(true)
//            }
            
//            let lsphandler = LSPHandler(webView: app.monacoInstance.monacoWebView, adapter: LSPFrameAdaptor())
//            lsphandler.onSavedFile = {
//                await app.saveCurrentFile(true)
//            }
            
//            app.monacoInstance.executeJavascript(command: injectWS + completionJS, printResponse: true)
            
           
            
            
        }
        
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        
    }
    
    class Coordinator: NSObject, WKScriptMessageHandlerWithReply {
        var onCompletionResult: ((_ result: CompletionResult?, _ range: [String: Any]) -> Void)?
//        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
//
//        }
        
        func toKind(_ kind: String) -> Int {
//            Class
//            Function
//            Keyword
//            Statement
//            Instance
//
//            Module
            switch kind {
            case "class":
//                return "monaco.languages.CompletionItemKind.Class"
                return 5
            case "instance":
//                return "monaco.languages.CompletionItemKind.Reference"
                return 21
            case "keyword":
//                return "monaco.languages.CompletionItemKind.Keyword"
                return 17
            case "function":
//                return "monaco.languages.CompletionItemKind.Function"
                return 1
            case "module":
//                return "monaco.languages.CompletionItemKind.Module"
                return 8
            case "statement":
//                return "monaco.languages.CompletionItemKind.Reference"
                return 21
            default:
//                return "monaco.languages.CompletionItemKind.Text"
                return 18
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
            guard let result = message.body as? [String: AnyObject] else {
                return (nil, message.name)
            }
            guard let event = result["Event"] as? String else {
                return (nil, message.name)
            }
            
            if ["PythonCompletion", "CCompletion", "CPPCompletion"].contains(event) {
                if let uri = result["Uri"] as? String,
                   let content = result["Content"] as? String,
                   let index = result["Index"] as? Int,
                   let vid = result["Vid"] as? Int,
                   let range = result["Range"] as? [String: Any],
                   let lineNumber = result["lineNumber"] as? Int,
                   let Column = result["Column"] as? Int {
                    let completionResult = await requestCCompletionService(vid: vid, path: URL(string: uri)?.path ?? "", content: content, index: index)
                    onCompletionResult?(completionResult, range)
                    let items = completionResult?.suggestions.enumerated().map({ (index, item) in
                        [
                            "label": item,
                            "kind": toKind(completionResult?.suggestionsType[item] ?? ""),
                            "insertText": item,
//                            "documentation": ""
                        ]
                    })
                    return (items, nil)
                }
            }
            
            return (nil, message.name)
        }
    }
}

extension MonacoCompletionExtension: InputCompletionViewDelegate {
    func inputCompletionView(_ inputCompletionView: pyde.InputCompletionView, didSelectSuggestionAtIndex index: Int) {
        guard let result = inputCompletionView.completionResult,
              result.suggestions.count > index,
              let range = self.completionRange else {
            return
        }
        guard let sl = range["startLineNumber"] as? Int,
              let el = range["endLineNumber"] as? Int,
              let sc = range["startColumn"] as? Int,
              let ec = range["endColumn"] as? Int else {
            return
        }
        let rangeStr = "{startLineNumber: \(sl), startColumn: \(sc), endLineNumber: \(el), endColumn: \(ec),}"
        let text = result.suggestions[index]
        App.monacoInstance.executeJavascript(
            command:
                "editor.executeEdits('source',[{identifier: {major: 1, minor: 1}, range: \(rangeStr), text: decodeURIComponent(escape(window.atob('\(text.base64Encoded() ?? "")'))), forceMoveMarkers: true}])"
        )
    }
    
    func inputCompletionView(_ inputCompletionView: pyde.InputCompletionView, didInsertText text: String) {
        if text.count == 1 {
            App.monacoInstance.executeJavascript(
                command: "editor.trigger('keyboard', 'type', {text: '\(text)'})")
        } else {
            App.monacoInstance.executeJavascript(
                command:
                    "editor.executeEdits('source',[{identifier: {major: 1, minor: 1}, range: editor.getSelection(), text: decodeURIComponent(escape(window.atob('\(text.base64Encoded() ?? "")'))), forceMoveMarkers: true}])"
            )
        }
    }
    
    func inputCompletionViewDidInsertIndent(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(
            command: "editor.trigger('keyboard', 'type', {text: '\t'})")
    }
    
    func inputCompletionViewDidRevertIndent(_ inputCompletionView: pyde.InputCompletionView) {
        
    }
    
    func inputCompletionViewRedo(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(command: "editor.getModel().redo()")
    }
    
    func inputCompletionViewUndo(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(command: "editor.getModel().undo()")
    }
    
    func inputCompletionViewCursorBackward(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(
            command:
                "editor.setPosition({lineNumber: editor.getPosition().lineNumber, column: editor.getPosition().column - 1})"
        )
    }
    
    func inputCompletionViewCursorForward(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(
            command:
                "editor.setPosition({lineNumber: editor.getPosition().lineNumber, column: editor.getPosition().column + 1})"
        )
    }
    
    func inputCompletionViewCursorUpward(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(
            command:
                "editor.setPosition({lineNumber: editor.getPosition().lineNumber - 1, column: editor.getPosition().column})"
        )
        App.monacoInstance.executeJavascript(
            command: "editor.trigger('', 'selectNextSuggestion')")
    }
    
    func inputCompletionViewCursorDownward(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(
            command:
                "editor.setPosition({lineNumber: editor.getPosition().lineNumber + 1, column: editor.getPosition().column})"
        )
        App.monacoInstance.executeJavascript(
            command: "editor.trigger('', 'selectNextSuggestion')")
    }
    
    func inputCompletionViewDidComment(_ inputCompletionView: pyde.InputCompletionView) {
        
    }
    
    func inputCompletionDismissKeyboard(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(
            command: "document.getElementById('overlay').focus()")
        App.saveCurrentFile()
    }
    
    func inputCompletionPresentFind(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.executeJavascript(command: "editor.focus()")
        App.monacoInstance.executeJavascript(
            command: "editor.getAction('actions.find').run()")
    }
    
    func inputCompletionViewCopy(_ inputCompletionView: pyde.InputCompletionView) {
        App.monacoInstance.monacoWebView.evaluateJavaScript(
            "editor.getModel().getValueInRange(editor.getSelection())",
            completionHandler: { result, error in
                if let result = result as? String, !result.isEmpty {
                    UIPasteboard.general.string = result
                }
            })
    }
    
    func inputCompletionViewPaste(_ inputCompletionView: pyde.InputCompletionView) {
        if let string = UIPasteboard.general.string?.base64Encoded() {
           App.monacoInstance.executeJavascript(
               command:
                   "editor.executeEdits('source',[{identifier: {major: 1, minor: 1}, range: editor.getSelection(), text: decodeURIComponent(escape(window.atob('\(string)'))), forceMoveMarkers: true}])"
           )
       }
    }
    
    
}

private let completionJS =
"""
function createDependencyProposals(range) {
    // returning a static list of proposals, not even looking at the prefix (filtering is done by the Monaco editor),
    // here you could do a server side lookup
    return [
        {
            label: '"lodash"',
            kind: monaco.languages.CompletionItemKind.Function,
            documentation: "The Lodash library exported as Node.js modules.",
            insertText: '"lodash": "*"',
            range: range,
        },
        {
            label: '"express"',
            kind: monaco.languages.CompletionItemKind.Function,
            documentation: "Fast, unopinionated, minimalist web framework",
            insertText: '"express": "*"',
            range: range,
        },
        {
            label: '"mkdirp"',
            kind: monaco.languages.CompletionItemKind.Function,
            documentation: "Recursively mkdir, like <code>mkdir -p</code>",
            insertText: '"mkdirp": "*"',
            range: range,
        },
        {
            label: '"my-third-party-library"',
            kind: monaco.languages.CompletionItemKind.Function,
            documentation: "Describe your library here",
            insertText: '"${1:my-third-party-library}": "${2:1.2.3}"',
            insertTextRules:
                monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            range: range,
        },
    ];
}

monaco.languages.registerCompletionItemProvider("json", {
    provideCompletionItems: function (model, position) {
        // find out if we are completing a property in the 'dependencies' object.
        var textUntilPosition = model.getValueInRange({
            startLineNumber: 1,
            startColumn: 1,
            endLineNumber: position.lineNumber,
            endColumn: position.column,
        });
        var match = textUntilPosition.match(
            /"dependencies"\\s*:\\s*\\{\\s*("[^"]*"\\s*:\\s*"[^"]*"\\s*,\\s*)*([^"]*)?$/
        );
        if (!match) {
            return { suggestions: [] };
        }
        var word = model.getWordUntilPosition(position);
        var range = {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: word.startColumn,
            endColumn: word.endColumn,
        };
        return {
            suggestions: createDependencyProposals(range),
        };
    },
});

monaco.languages.registerCompletionItemProvider(["python", "c", "cpp"], {
    provideCompletionItems: function (model, position) {
        var word = model.getWordUntilPosition(position);
        var range = {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: word.startColumn,
            endColumn: word.endColumn,
        };

        let result = window.webkit.messageHandlers.replyMessageHandler.postMessage({
            Event: "PythonCompletion",
            Column: position.column,
            lineNumber: position.lineNumber,
            Index: model.getOffsetAt(position),
            Vid: model.getVersionId(),
            Content: model.getValue(),
            Uri: model.uri._formatted,
            Range: range
        });
        
        var suggestions = {
            "suggestions": []
        };
        return result.then((value) => {
            //console.log(value);
            suggestions = {
                "suggestions": value.map(function(item) {
                    item["range"] = range;
                    return item;
                })
            };
            //console.log(suggestions);
            return suggestions;
        })
        .catch((error) => {
            console.log("error:", error)
        })

        return suggestions;
        
        
        
    },
});


"""

//// WebSocket版本示例
//const ws = new WebSocket('ws://1270.0.01:2087');
//
//let currentRequestId = 1;
//
//function sendRequest(sock, method, params, requestId = currentRequestId++) {
//    // 构造JSON-RPC请求
//    const request = {
//      jsonrpc: "2.0",
//      id: requestId,
//      method: method,
//      params: params || null // 允许params为undefined
//    };
//
//    // 序列化并计算内容长度
//    const body = JSON.stringify(request);
//    const headers = `Content-Length: ${body.length}\r\n\r\n`;
//
//    sock.send(/*headers + */body);
//}
//
//monaco.languages.registerCompletionItemProvider('python', {
////    triggerCharacters: ['.', ' '],
//
//    provideCompletionItems(model, position) {
//        var word = model.getWordUntilPosition(position);
//        var range = {
//            startLineNumber: position.lineNumber,
//            endLineNumber: position.lineNumber,
//            startColumn: word.startColumn,
//            endColumn: word.endColumn,
//        };
//
//        return new Promise((resolve) => {
//            const requestId = Date.now().toString();
//
////            const requestData = {
////                id: requestId,
////                code: model.getValue(),
////                line: position.lineNumber,
////                column: position.column
////            };
////            const requestData = {
////                "jsonrpc": "2.0",
////                "id": requestId,
////                "method": "textDocument/completion",
////                "params": {
////                    "textDocument": {
////                        "uri": model.uri._formatted
////                    },
////                    "position": {
////                        "line": position.lineNumber,
////                        "character": model.getOffsetAt(position)
////                    }
////                }
////            }
//            currentRequestId += 1
//            let params = {
//                "textDocument": {
//                    "uri": model.uri._formatted
//                },
//                "position": {
//                    "line": position.lineNumber - 1,
//                    "character": position.column - 1
//                }
//            }
//
//            const handler = (event) => {
//                const response = JSON.parse(event.data);
//                if (true || response.id === requestId) {
//                    ws.removeEventListener('message', handler);
//                    console.log(response);
//                    resolve({
//                        suggestions: response.result.items.map(function(item) {
//                            item["range"] = range;
//                            return item;
//                        })
//                    });
//                }
//            };
//
//            ws.addEventListener('message', handler);
//            sendRequest(ws, "textDocument/completion", params, currentRequestId);
//        });
//    }
//});




//HStack(spacing: horizontalSizeClass == .compact ? 8 : 14) {
//    Group {
//        Button(
//            action: {
//                App.monacoInstance.executeJavascript(command: "editor.getModel().undo()")
//            },
//            label: {
//                Image(systemName: "arrow.uturn.left")
//            })
//        Button(
//            action: {
//                App.monacoInstance.executeJavascript(command: "editor.getModel().redo()")
//            },
//            label: {
//                Image(systemName: "arrow.uturn.right")
//            })
//        Button(
//            action: {
//                App.monacoInstance.monacoWebView.evaluateJavaScript(
//                    "editor.getModel().getValueInRange(editor.getSelection())",
//                    completionHandler: { result, error in
//                        if let result = result as? String, !result.isEmpty {
//                            UIPasteboard.general.string = result
//                        }
//                    })
//            },
//            label: {
//                Image(systemName: "doc.on.doc")
//            })
//        if UIPasteboard.general.hasStrings || pasteBoardHasContent {
//            Button(
//                action: {
//                    if let string = UIPasteboard.general.string?.base64Encoded() {
//                        App.monacoInstance.executeJavascript(
//                            command:
//                                "editor.executeEdits('source',[{identifier: {major: 1, minor: 1}, range: editor.getSelection(), text: decodeURIComponent(escape(window.atob('\(string)'))), forceMoveMarkers: true}])"
//                        )
//                    }
//                },
//                label: {
//                    Image(systemName: "doc.on.clipboard")
//                })
//        }
//        if needTabKey {
//            Button(
//                action: {
//                    App.monacoInstance.executeJavascript(
//                        command: "editor.trigger('keyboard', 'type', {text: '\t'})")
//                },
//                label: {
//                    Text("↹")
//                })
//        }
//
//    }
//
//    Spacer()
//
//    Group {
//        ForEach(["{", "}", "[", "]", "(", ")"], id: \.self) { char in
//            Button(
//                action: {
//                    App.monacoInstance.executeJavascript(
//                        command: "editor.trigger('keyboard', 'type', {text: '\(char)'})")
//                },
//                label: {
//                    Text(char).padding(.horizontal, 2)
//                })
//        }
//        if horizontalSizeClass != .compact {
//            Button(
//                action: {
//                    App.monacoInstance.executeJavascript(
//                        command:
//                            "editor.setPosition({lineNumber: editor.getPosition().lineNumber - 1, column: editor.getPosition().column})"
//                    )
//                },
//                label: {
//                    Image(systemName: "arrow.up")
//                })
//            Button(
//                action: {
//                    App.monacoInstance.executeJavascript(
//                        command:
//                            "editor.setPosition({lineNumber: editor.getPosition().lineNumber + 1, column: editor.getPosition().column})"
//                    )
//                    App.monacoInstance.executeJavascript(
//                        command: "editor.trigger('', 'selectNextSuggestion')")
//                },
//                label: {
//                    Image(systemName: "arrow.down")
//                })
//        }
//
//        Button(
//            action: {
//                App.monacoInstance.executeJavascript(
//                    command:
//                        "editor.setPosition({lineNumber: editor.getPosition().lineNumber, column: editor.getPosition().column - 1})"
//                )
//            },
//            label: {
//                Image(systemName: "arrow.left")
//            })
//        Button(
//            action: {
//                App.monacoInstance.executeJavascript(
//                    command:
//                        "editor.setPosition({lineNumber: editor.getPosition().lineNumber, column: editor.getPosition().column + 1})"
//                )
//            },
//            label: {
//                Image(systemName: "arrow.right")
//            })
//        Button(
//            action: {
//                App.monacoInstance.executeJavascript(
//                    command: "document.getElementById('overlay').focus()")
//                App.saveCurrentFile()
//            },
//            label: {
//                Image(systemName: "keyboard.chevron.compact.down")
//            })
//    }



let injectWS = """
// 注入的脚本，覆盖原生 WebSocket
(function() {
    const OriginalWebSocket = window.WebSocket;
    var context = this;
    window.WebSocket = function(url, protocols) {
        this.url = url;
        this.originalWebSocket = null;
        this.listeners = {
            open: [],
            message: [],
            error: [],
            close: []
        };
        
        // 通知 Native 层创建连接
        window.webkit.messageHandlers.webSocketHandler.postMessage({
            type: 'create',
            url: url
        });
        context = this;
        return this;
    };

    WebSocket.prototype.send = function(data) {
        window.webkit.messageHandlers.webSocketHandler.postMessage({
            type: 'send',
            data: data
        });
    };

    WebSocket.prototype.close = function() {
        window.webkit.messageHandlers.webSocketHandler.postMessage({
            type: 'close'
        });
    };

    // 添加事件监听
    WebSocket.prototype.addEventListener = function(type, listener) {
        if (this.listeners[type]) {
            this.listeners[type].push(listener);
        }
    };

    WebSocket.prototype.removeEventListener = function(type, listener) {
        if (this.listeners[type]) {
            var listeners = this.listeners[type]
            const index = listeners.indexOf(listener);

            // 如果存在则删除
            if (index > -1) {
                listeners.splice(index, 1);
            }
        }
    };

    // 触发事件（由 Native 层调用）
    window.__triggerWebSocketEvent = function(eventName, eventData) {
        const event = new Event(eventName);
        Object.assign(event, eventData);
        console.log(context)
        console.log(context.listeners)
        context.listeners[eventName].forEach(listener => listener.call(this, event));
    };
})();
"""


//class LSPHandler: NSObject, WKScriptMessageHandlerWithReply {
//    private var domainSocket: Int32 = -1 // Socket 文件描述符
//    private weak var webView: WKWebView?
//    
//    private var frameAdapter: WSFrameAdaptor
//    
//    fileprivate var onSavedFile: (()async -> Void)?
//    fileprivate var onLSPResponse: ((_ res: String) -> Void)?
//    
//    init(webView: WKWebView, adapter: WSFrameAdaptor) {
//        self.webView = webView
//        self.frameAdapter = adapter
//        super.init()
//        
//        self.frameAdapter.onSendToWebSocket = { [self] data in
//            DispatchQueue.main.async {
//                if let onLSPResponse = self.onLSPResponse {
//                    onLSPResponse(data)
//                }
//            }
//        }
//        
//        self.frameAdapter.onWriteToServerSocket = { [self] data in
//            _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
//        }
//        
//        // 添加消息处理器
//        webView.configuration.userContentController.add(self, name: "LSPHandler")
//    }
//    
//    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
//        guard let result = message.body as? [String: AnyObject] else {
//            return (nil, message.name)
//        }
//        guard let event = result["Event"] as? String else {
//            return (nil, message.name)
//        }
//        
//        if ["PythonCompletion", "CCompletion", "CPPCompletion"].contains(event) {
//            if let uri = result["Uri"] as? String,
//               let content = result["Content"] as? String,
//               let index = result["Index"] as? Int,
//               let vid = result["Vid"] as? Int,
//               let range = result["Range"] as? [String: Any],
//               let lineNumber = result["lineNumber"] as? Int,
//               let Column = result["Column"] as? Int {
//                let completionResult = await requestCCompletionService(vid: vid, path: URL(string: uri)?.path ?? "", content: content, index: index)
//                onCompletionResult?(completionResult, range)
//                let items = completionResult?.suggestions.enumerated().map({ (index, item) in
//                    [
//                        "label": item,
//                        "kind": toKind(completionResult?.suggestionsType[item] ?? ""),
//                        "insertText": item,
////                            "documentation": ""
//                    ]
//                })
//                return (items, nil)
//            }
//        }
//        
//        return (nil, message.name)
//    }
//}
//    
////    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
////        guard let body = message.body as? [String: Any] else { return }
////        
////        switch body["type"] as? String {
////        case "create":
////            connectToDomainSocket(url: body["url"] as? String ?? "")
////        case "send":
////            if let onSavedFile {
////                Task {
////                    await onSavedFile()
////                    frameAdapter.receiveWebSocket(data: body["data"] as? String ?? "")
////                }
////            } else {
////                frameAdapter.receiveWebSocket(data: body["data"] as? String ?? "")
////            }
////            
////        case "close":
////            closeSocket()
////        default: break
////        }
////    }
//    
//    // 连接到 Unix Domain Socket
//    private func connectToDomainSocket(url: String) {
////        let socketPath = ConstantManager.appGroupContainer.appendingPathComponent("pylsp.sock").path // 你的 Socket 路径
//        let socketPath = "/Volumes/Python/Python3IDEGroup/pylsp.sock"
//        
//        domainSocket = socket(AF_UNIX, SOCK_STREAM, 0)
//        guard domainSocket != -1 else { return }
//        
//        var addr = sockaddr_un()
//        addr.sun_family = sa_family_t(AF_UNIX)
//        strncpy(&addr.sun_path, socketPath, socketPath.count)
//        
//        let result = withUnsafePointer(to: &addr) {
//            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
//                connect(domainSocket, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
//            }
//        }
//        
//        if result == 0 {
//            // 通知 JS 连接成功
////            webView?.evaluateJavaScript("window.__triggerWebSocketEvent('open')")
//            startReceiving()
//            _sendInitializeMsg()
//        } else {
//            // 触发错误
////            webView?.evaluateJavaScript("window.__triggerWebSocketEvent('error', { error: 'Connection failed' })")
//        }
//    }
//    
//
//    private func _sendInitializeMsg() {
//        let data1: [String: Any] = [
//            "jsonrpc": "2.0",
//            "id": 1,
//            "method": "initialize",
//            "params": [
//                "processId": nil,
//                "rootUri": "file:///tmp",
//                "capabilities": [String: Any]()
//            ]
//        ]
//        let req1 = try! JSONSerialization.data(withJSONObject: data1)
//        let str1 = String(data: req1, encoding: .utf8)!
//        print(str1)
//        let data = "Content-Length: \(str1.utf8.count)\r\n\r\n" + str1
//        _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
//    }
//    private func __sendMsg(method: String, params: [String: Any]) {
//        let data1: [String: Any] = [
//            "jsonrpc": "2.0",
//            "id": 1,
//            "method": method,
//            "params": params
//        ]
//        let req1 = try! JSONSerialization.data(withJSONObject: data1)
//        let str1 = String(data: req1, encoding: .utf8)!
//        print(str1)
//        let data = "Content-Length: \(str1.utf8.count)\r\n\r\n" + str1
//        _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
//    }
//    
//    // 发送数据到 Socket
//    private func sendDataToSocket(data: String) {
//        guard domainSocket != -1 else { return }
////        _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
//        let msg = [
//            "textDocument": ["uri": "file:///tmp/test.py"],
//            "position": ["line": 0, "character": 1]
//        ]
//        __sendMsg(method: "textDocument/completion", params: msg)
//    }
//    
//    // 关闭 Socket
//    private func closeSocket() {
//        guard domainSocket != -1 else { return }
//        close(domainSocket)
//        domainSocket = -1
//    }
//    
//    // 从 Socket 接收数据（需在后台线程运行）
//    func startReceiving() {
//        DispatchQueue.global().async { [weak self] in
//            guard let self = self else { return }
//            var buffer = [UInt8](repeating: 0, count: 4096)
//            while self.domainSocket != -1 {
//                let bytesRead = recv(self.domainSocket, &buffer, buffer.count, 0)
//                
//                guard bytesRead > 0 else { continue }
//                
//
//                
//                
//                // 正确转换字节数组为字符串
//                let data = Data(bytes: buffer, count: bytesRead)
//                guard let str = String(data: data, encoding: .utf8) else { continue }
//                
////                self.frameAdapter.receiveWebSocket(data: str)
//                self.frameAdapter.receiveServerSocket(data: str)
//                continue
//                
//                let body = String(str.trimmingPrefix(while: {$0 != "{"}))
//                
//                DispatchQueue.main.async {
//                    // 将数据传回 JS
//                    let script = "window.__triggerWebSocketEvent('message', { data: '\(body)' })"
//                    self.webView?.evaluateJavaScript(script)
//                }
//            }
//        }
//    }
//}




class WebSocketHandler: NSObject, WKScriptMessageHandler {
    private var domainSocket: Int32 = -1 // Socket 文件描述符
    private weak var webView: WKWebView?
    
    private var frameAdapter: WSFrameAdaptor
    
    fileprivate var onSavedFile: (()async -> Void)?
    
    init(webView: WKWebView, adapter: WSFrameAdaptor) {
        self.webView = webView
        self.frameAdapter = adapter
        super.init()
        
        self.frameAdapter.onSendToWebSocket = { [self] data in
            DispatchQueue.main.async {
                // 将数据传回 JS
                let script = "window.__triggerWebSocketEvent('message', { data: '\(data)' })"
                self.webView?.evaluateJavaScript(script)
            }
        }
        
        self.frameAdapter.onWriteToServerSocket = { [self] data in
            _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
        }
        
        // 添加消息处理器
        webView.configuration.userContentController.add(self, name: "webSocketHandler")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        
        switch body["type"] as? String {
        case "create":
            connectToDomainSocket(url: body["url"] as? String ?? "")
        case "send":
//            sendDataToSocket(data: body["data"] as? String ?? "")
            if let onSavedFile {
                Task {
                    await onSavedFile()
                    frameAdapter.receiveWebSocket(data: body["data"] as? String ?? "")
                }
            } else {
                frameAdapter.receiveWebSocket(data: body["data"] as? String ?? "")
            }
            
        case "close":
            closeSocket()
        default: break
        }
    }
    
    // 连接到 Unix Domain Socket
    private func connectToDomainSocket(url: String) {
//        let socketPath = ConstantManager.appGroupContainer.appendingPathComponent("pylsp.sock").path // 你的 Socket 路径
        let socketPath = "/Volumes/Python/Python3IDEGroup/pylsp.sock"
        
        domainSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard domainSocket != -1 else { return }
        
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        strncpy(&addr.sun_path, socketPath, socketPath.count)
        
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(domainSocket, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        if result == 0 {
            // 通知 JS 连接成功
            webView?.evaluateJavaScript("window.__triggerWebSocketEvent('open')")
            startReceiving()
            _sendMsg()
        } else {
            // 触发错误
            webView?.evaluateJavaScript("window.__triggerWebSocketEvent('error', { error: 'Connection failed' })")
        }
    }
    
//    request = {
//        "jsonrpc": "2.0",
//        "id": request_id,
//        "method": method,
//        "params": params
//    }
//    body = json.dumps(request).encode()
//    headers = f"Content-Length: {len(body)}\r\n\r\n".encode()
    private func _sendMsg() {
        let data1: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": [
                "processId": nil,
                "rootUri": "file:///tmp",
                "capabilities": [String: Any]()
            ]
        ]
        let req1 = try! JSONSerialization.data(withJSONObject: data1)
        let str1 = String(data: req1, encoding: .utf8)!
        print(str1)
        let data = "Content-Length: \(str1.utf8.count)\r\n\r\n" + str1
        _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
    }
    private func __sendMsg(method: String, params: [String: Any]) {
        let data1: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        ]
        let req1 = try! JSONSerialization.data(withJSONObject: data1)
        let str1 = String(data: req1, encoding: .utf8)!
        print(str1)
        let data = "Content-Length: \(str1.utf8.count)\r\n\r\n" + str1
        _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
    }
    
    // 发送数据到 Socket
    private func sendDataToSocket(data: String) {
        guard domainSocket != -1 else { return }
//        _ = data.withCString { send(domainSocket, $0, data.utf8.count, 0) }
        let msg = [
            "textDocument": ["uri": "file:///tmp/test.py"],
            "position": ["line": 0, "character": 1]
        ]
        __sendMsg(method: "textDocument/completion", params: msg)
    }
    
    // 关闭 Socket
    private func closeSocket() {
        guard domainSocket != -1 else { return }
        close(domainSocket)
        domainSocket = -1
    }
    
    // 从 Socket 接收数据（需在后台线程运行）
    func startReceiving() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while self.domainSocket != -1 {
                let bytesRead = recv(self.domainSocket, &buffer, buffer.count, 0)
                
                guard bytesRead > 0 else { continue }
                

                
                
                // 正确转换字节数组为字符串
                let data = Data(bytes: buffer, count: bytesRead)
                guard let str = String(data: data, encoding: .utf8) else { continue }
                
//                self.frameAdapter.receiveWebSocket(data: str)
                self.frameAdapter.receiveServerSocket(data: str)
                continue
                
                let body = String(str.trimmingPrefix(while: {$0 != "{"}))
                
                DispatchQueue.main.async {
                    // 将数据传回 JS
                    let script = "window.__triggerWebSocketEvent('message', { data: '\(body)' })"
                    self.webView?.evaluateJavaScript(script)
                }
            }
        }
    }
}



//class ViewController: UIViewController {
//    var webView: WKWebView!
//    var socketHandler: WebSocketHandler!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let config = WKWebViewConfiguration()
//        webView = WKWebView(frame: view.bounds, configuration: config)
//        view.addSubview(webView)
//        
//        socketHandler = WebSocketHandler(webView: webView, adapter: LSPFrameAdaptor())
//        socketHandler.startReceiving() // 开始接收数据
//        
//        // 加载页面
//        let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
//        webView.load(URLRequest(url: URL(fileURLWithPath: htmlPath!)))
//    }
//}

protocol WSFrameAdaptor {
    var onSendToWebSocket: ((String) -> Void)? { get set }
    var onWriteToServerSocket: ((String) -> Void)? {get set}
    
    func receiveWebSocket(data: String)
    func receiveServerSocket(data: String)
}

class LSPFrameAdaptor: WSFrameAdaptor {
    
    var onSendToWebSocket: ((String) -> Void)?
    var onWriteToServerSocket: ((String) -> Void)?
    private var contentLength: Int = 0
    private var buffer: String = ""

    func receiveWebSocket(data: String){
        let message = "Content-Length: \(String(data.utf8.count))\r\n\r\n\(data)"
        onWriteToServerSocket?(message)
    }

    private func getContentLength(data: String) -> Int? {
        if !data.hasPrefix("Content-Length") { return nil }
        let contentLength = data.split(separator: "\r\n", maxSplits: 1).first
        return Int(contentLength?.split(separator: " ").last ?? "")
    }

    private func removeHeader(data: String) -> String {
        return String(data.trimmingPrefix(while: {$0 != "{"}))
    }
    
    func receiveServerSocket(data: String){
        if let contentLength = getContentLength(data: data) {
            self.contentLength = contentLength
            buffer = removeHeader(data: data)
        } else {
            buffer += removeHeader(data: data)
        }

        if buffer.utf8.count >= contentLength {
            onSendToWebSocket?(buffer)
            buffer = ""
            contentLength = 0
        }
    }
}
