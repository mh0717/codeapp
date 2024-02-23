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

class MonacoCompletionExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(5))) {
            
            
            let contentManager = app.monacoInstance.monacoWebView.configuration.userContentController
            contentManager.addScriptMessageHandler(Coordinator(), contentWorld: .page, name: "replyMessageHandler")
            
            app.monacoInstance.executeJavascript(
                command: completionJS, printResponse: true
            )
        }
        
    }
    
    override func onWorkSpaceStorageChanged(newUrl: URL) {
        
    }
    
    class Coordinator: NSObject, WKScriptMessageHandlerWithReply {
//        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
//
//        }
        
        func toKind(_ kind: String) -> String {
//            Class
//            Function
//            Keyword
//            Statement
//            Instance
//
//            Module
            switch kind {
            case "class":
                return "monaco.languages.CompletionItemKind.Class"
            case "instance":
                return "monaco.languages.CompletionItemKind.Reference"
            case "keyword":
                return "monaco.languages.CompletionItemKind.Keyword"
            case "function":
                return "monaco.languages.CompletionItemKind.Function"
            case "module":
                return "monaco.languages.CompletionItemKind.Module"
            case "statement":
                return "monaco.languages.CompletionItemKind.Reference"
            default:
                return "monaco.languages.CompletionItemKind.Text"
                
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
            guard let result = message.body as? [String: AnyObject] else {
                return (nil, message.name)
            }
            guard let event = result["Event"] as? String else {
                return (nil, message.name)
            }
            
            if event == "PythonCompletion" {
                if let uri = result["Uri"] as? String,
                   let content = result["Content"] as? String,
                   let index = result["Index"] as? Int,
                   let vid = result["Vid"] as? Int,
                   let lineNumber = result["lineNumber"] as? Int,
                   let Column = result["Column"] as? Int {
                    let completionResult = await requestCCompletionService(vid: vid, path: URL(string: uri)?.path ?? "", content: content, index: index)
                    let items = completionResult?.suggestions.enumerated().map({ (index, item) in
                        [
                            "label": item,
//                            "kind": toKind(completionResult?.suggestionsType[item] ?? ""),
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

monaco.languages.registerCompletionItemProvider("python", {
    provideCompletionItems: function (model, position) {
        let result = window.webkit.messageHandlers.replyMessageHandler.postMessage({
            Event: "PythonCompletion",
            Column: position.column,
            lineNumber: position.lineNumber,
            Index: model.getOffsetAt(position),
            Vid: model.getVersionId(),
            Content: model.getValue(),
            Uri: model.uri._formatted
        });
        var word = model.getWordUntilPosition(position);
        var range = {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: word.startColumn,
            endColumn: word.endColumn,
        };
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

