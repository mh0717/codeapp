//
//  JsonUIPreview.swift
//  Code
//
//  Created by Huima on 2024/6/1.
//

import Foundation
import SwiftUI
import JSONDrivenUI




class JsonUIPreviewExtension: CodeAppExtension {
    
    static func previewWidget(app: MainApp, url: URL) {
        guard url.pathExtension.lowercased() == "wdui" else {
            return
        }
        
        if let json = try? Data(contentsOf: url) {
            DispatchQueue.main.async {
                let view = WidgetUIPreview(jsonData: json)
                let editor = EditorInstanceWithURL(view: AnyView(view), title: "Preview: \(url.lastPathComponent)", url: url)
                app.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
            }
        }
    }

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        let preview = ToolbarItem(
            extenionID: "JSON_UI_PREVIEW",
            icon: "newspaper",
            onClick: {
                guard let textEditor = app.activeTextEditor, textEditor.url.pathExtension.lowercased() == "wdui" else{
                    return
                }
                
                JsonUIPreviewExtension.previewWidget(app: app, url: textEditor.url)
                
//                var entry = ScriptEntry(date: Date(), output: "")
//                entry.view = [
//                    .systemSmall: textEditor.content
//                ]
//                
////                let editor = EditorInstanceWithURL(view: AnyView(WidgetPreview(entry: entry)), title: "Preview: \(textEditor.url.lastPathComponent)", url: textEditor.url)
////                DispatchQueue.main.async {
////                    app.appendAndFocusNewEditor(editor: editor, alwaysInNewTab: true)
////                }
//                let view = AnyView(WidgetPreview(entry: entry))
//                app.popupManager.showSheet(content: view)
            },
            shouldDisplay: {
                if let editor = app.activeTextEditor, editor.url.pathExtension.lowercased() == "wdui" {
                    return true
                }
                return false
            }
        )
        
        contribution.toolBar.registerItem(item: preview)
    }
}


import WidgetKit
import UIKit

func size(for mode: WidgetFamily, size: UserInterfaceSizeClass = .regular) -> CGSize {
    if size == .regular {
        switch mode {
        case .systemSmall:
            return CGSize(width: 169, height: 169)
        case .systemMedium:
            return CGSize(width: 360, height: 169)
        case .systemLarge:
            return CGSize(width: 360, height: 379)
        case .systemExtraLarge:
            return CGSize(width: 540, height: 260)
        default:
            return CGSize(width: 169, height: 379)
        }
    } else {
        switch mode {
        case .systemSmall:
            return CGSize(width: 141, height: 141)
        case .systemMedium:
            return CGSize(width: 292, height: 141)
        case .systemLarge:
            return CGSize(width: 292, height: 311)
        case .systemExtraLarge:
            return CGSize(width: 540, height: 260)
        default:
            return CGSize(width: 141, height: 141)
        }
    }
}


func sizeForFamily(_ family: Int) -> CGSize {
    return size(for: WidgetFamily(rawValue: family) ?? .systemSmall)
}


fileprivate struct ScriptSnapshot: Codable {
    
    var family: Int
    
    var image: Data
    
    var backgroundColor: Data
}

/// A widget entry.
@available(iOS 14.0, *)
struct ScriptEntry: TimelineEntry, Codable {
    
    var date: Date
    
    /// The output of the script.
    var output: String
    
//    #if !os(macOS)
//    /// The snapshots.
//    var snapshots: [WidgetFamily:(UIImage, UIColor)]
//    
//    /// A view contained in the widget.
//    var view: [WidgetFamily:WidgetView]?
//    #endif
    var view: [WidgetFamily: String]?
    
    /// The code of the executed script.
    var code: String
    
    /// The bookmark data of the script running the widget.
    var bookmarkData: Data?
    
    /// A boolean indicating whether the console should be rendered as a placeholder.
    var isPlaceholder = false
    
    /// For widgets handled in app, the update interval.
    var updateInterval: TimeInterval?
    
    /// A boolean indicating whether the script content is set in app.
    var inApp = false
    
    /// Returns the URL to open the script.
    ///
    /// - Parameters:
    ///     - viewID: The ID of the view.
    ///
    /// - Returns: A deep link to Pyto.
    func url(viewID: String?) -> URL? {
        
        do {
            if let data = bookmarkData {
                var isStale = false
                let fileURL = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
                
                if !fileURL.pathComponents.contains("PluginKitPlugin") {
                    let url = URL(string: "pyto://widget?bookmark=\(data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")\(viewID != nil ? "&link=\(viewID!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? viewID!)" : "")")
                    return url
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        let _code = self.code
        
        let code = """
        __name__ = "widget"

        \(viewID != nil ? "import widgets; widgets.link = \"\(viewID!.replacingOccurrences(of: "\"", with: "\\\""))\"; del widgets;" : "")

        \(_code)

        import widgets
        widgets.link = None
        """
        
        let url = URL(string: "pyto://x-callback/?code=\(code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        return url
    }
    
    enum Key: CodingKey {
        case snapshots
        case view
        case bookmarkData
        case updateInterval
        case output
        case date
        case code
    }
    
    init(date: Date, output: String, code: String = "", bookmarkData: Data? = nil) {
        self.date = date
        self.output = output
        self.code = code
        self.bookmarkData = bookmarkData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do {
            let _view = try container.decode([Int:String].self, forKey: .view)
            
            var view = [WidgetFamily:String]()
            
            for __view in _view {
                view[WidgetFamily(rawValue: __view.key) ?? .systemSmall] = __view.value
            }
            
            self.view = view
        } catch {
            self.view = nil
        }
        
        
        do {
            bookmarkData = try container.decode(Data.self, forKey: .bookmarkData)
        } catch {
            bookmarkData = nil
        }
        
        do {
            updateInterval = try container.decode(Double.self, forKey: .updateInterval)
        } catch {
            updateInterval = nil
        }
                
        output = try container.decode(String.self, forKey: .output)
        
        date = try container.decode(Date.self, forKey: .date)
       
        code = try container.decode(String.self, forKey: .code)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        
        var views = [Int:String]()
        for view in self.view ?? [:] {
            views[view.key.rawValue] = view.value
        }
        
        try container.encode(views, forKey: .view)
        
        try container.encode(bookmarkData, forKey: .bookmarkData)
        try container.encode(updateInterval, forKey: .updateInterval)
        try container.encode(output, forKey: .output)
        try container.encode(date, forKey: .date)
        try container.encode(code, forKey: .code)
    }
}


struct WidgetEntryView : View {
    
    @Environment(\.widgetFamily) var family
    
    var entry: ScriptEntry
        
    var customFamily: WidgetFamily?
    
    init(entry: ScriptEntry, customFamily: WidgetFamily? = nil) {
        self.entry = entry
        self.customFamily = customFamily
    }
    
    var body: some View {
        
        if entry.isPlaceholder {
            return AnyView(PlaceholderView(inApp: entry.inApp))
        } else {
            let family = customFamily ?? self.family
            
            if let json = entry.view?[family] ?? entry.view?.first?.value {
                let data = Data(json.utf8)
                if let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let backgroundColor = dictionary["backgroundColor"] as? String {
                    return AnyView(JSONDataView(json: data).background(Color.init(hexString: backgroundColor)))
                } else {
                    return AnyView(JSONDataView(json: data).background(Color.blue))
                }
                
            } else {
                return AnyView(ZStack {
                    Text("no script")
                })
            }
        }
    }
}

@available(iOS 14.0, *)
struct PlaceholderView: View {
    
    var inApp: Bool
    
    var body: some View {
        ZStack {
//            backgroundGradient
            
            Image(systemName: inApp ? "app.badge.fill" : "play.fill")
                .font(.system(size: 80))
                .foregroundColor(.black)
        }
    }
}

struct WidgetUIPreview: View {
    let jsonData: Data
    
    @Environment(\.horizontalSizeClass) var horizontalSize
    
    func widget(family: WidgetFamily) -> some View {
        var color = Color.init(id: "statusBar.background")
        if let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any], let props = json["properties"] as? [String: Any], let backgroundColor = props["backgroundColor"] as? String {
            color = Color(hexString: backgroundColor)
        }
        return JSONDataView(json: jsonData)
            .frame(width: size(for: family, size: horizontalSize ?? .compact).width, height: size(for: family, size: horizontalSize ?? .compact).height)
            .background(color)
            .cornerRadius(16)
            .padding()
    }
    
    var body: some View {
        ScrollView([.vertical, .horizontal]) {
                VStack {
                    if horizontalSize == .compact {
                        widget(family: .systemSmall)
                        widget(family: .systemMedium)
                        widget(family: .systemLarge)
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            widget(family: .systemExtraLarge)
                        }
                    } else {
                        HStack {
                            widget(family: .systemSmall)
                            widget(family: .systemMedium)
                            Spacer()
                        }
                        HStack {
                            widget(family: .systemLarge)
                            Spacer()
                        }
                        HStack {
                            widget(family: .systemExtraLarge)
                            Spacer()
                        }
                    }
                }
                .padding()
        }
    }
}


struct WidgetPreview: View {
    
    var entry: ScriptEntry
        
    @Environment(\.horizontalSizeClass) var horizontalSize
    @Environment(\.presentationMode) var presentationMode
    
    func widget(family: WidgetFamily) -> some View {
        WidgetEntryView(entry: entry, customFamily: family)
            .frame(width: size(for: family, size: horizontalSize ?? .compact).width, height: size(for: family, size: horizontalSize ?? .compact).height)
            .cornerRadius(16)
            .padding()
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Image("Wallpaper").resizable().aspectRatio(contentMode: ContentMode.fill).ignoresSafeArea()
                
            ScrollView([.vertical, .horizontal]) {
                    VStack {
                        if horizontalSize == .compact {
                            widget(family: .systemSmall)
                            widget(family: .systemMedium)
                            widget(family: .systemLarge)
                        } else {
                            HStack {
                                widget(family: .systemSmall)
                                widget(family: .systemMedium)
                                Spacer()
                            }
                            HStack {
                                widget(family: .systemLarge)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .navigationBarItems(trailing: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done").fontWeight(.bold)
            }).hoverEffect())
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
