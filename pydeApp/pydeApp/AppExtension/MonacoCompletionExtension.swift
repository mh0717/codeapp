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
