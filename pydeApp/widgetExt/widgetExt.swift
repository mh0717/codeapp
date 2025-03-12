//
//  widgetExt.swift
//  widgetExt
//
//  Created by Huima on 2024/6/11.
//

import WidgetKit
import SwiftUI
import UniformTypeIdentifiers
import ios_system
import CCommon
import pydeCommon
import JSONDrivenUI
import Kingfisher

enum ExecutorError: Error {
    case failed
}

private let regex = try! NSRegularExpression(pattern: "\"imageUrl\"\\s*:\\s*\"([^\"]+)\"", options:[])
private func regexGetSub(str:String) -> [String] {
    let nsstr = str as NSString
    var subStr = [String]()
    let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))
    //解析出子串
    for  match in matches {
        let range = match.range(at: 1)
        let urlstr = nsstr.substring(with: range)
        subStr.append(urlstr)
    }
    return subStr
}
//private func fetchImage(_ url: URL) async {
//    return await withUnsafeContinuation {con in
//        KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: url)) { result in
//            con.resume()
//        }
//    }
//}

struct PYProvider: IntentTimelineProvider {
    
    typealias Intent = ScriptIntent
    
    typealias Entry = ScriptEntry
    
    func getSnapshot(for configuration: ScriptIntent, in context: Context, completion: @escaping (ScriptEntry) -> Void) {
        var entry = ScriptEntry(date: Date(), output: "")
        entry.isPlaceholder = true
        completion(entry)
    }
    
    func placeholder(in context: Context) -> ScriptEntry {
        return ScriptEntry(date: Date(), output: NSLocalizedString("noSelectedScript", comment: ""))
    }
    
    func getTimeline(for configuration: ScriptIntent, in context: Context, completion: @escaping (Timeline<ScriptEntry>) -> Void) {
        
//        if configuration.script != nil {
//            
//            do {
//            } catch {
//                print(error.localizedDescription)
//                completion(Timeline(entries: [], policy: .never))
//            }
//        } else {
//            completion(Timeline(entries: [ScriptEntry(date: Date(), output: NSLocalizedString("noSelectedScript", comment: ""))], policy: .never))
//        }
        completion(Timeline(entries: [], policy: .never))
    }
}

//struct Provider: AppIntentTimelineProvider {
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), wdjson: nil, status: "idle")
//    }
//
//    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: configuration, wdjson: nil, status: "idle")
//    }
//    
//    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
//        
//        if KingfisherManager.shared.defaultOptions.isEmpty {
//            if let originCache = try? ImageCache(name: "pyoriginCache", cacheDirectoryURL: ConstantManager.appGroupContainer.appendingPathComponent("originCache")),
//               let targetCache = try? ImageCache(name: "pytargetCache", cacheDirectoryURL: ConstantManager.appGroupContainer.appendingPathComponent("targetCache")) {
//                originCache.memoryStorage.config.countLimit = 5
//                originCache.memoryStorage.config.totalCostLimit = 5 * 1024 * 1024
//                targetCache.memoryStorage.config.countLimit = 5
//                targetCache.memoryStorage.config.totalCostLimit = 5 * 1024 * 1024
//                ImageCache.default.memoryStorage.config.countLimit = 5
//                ImageCache.default.memoryStorage.config.totalCostLimit = 5 * 1024 * 1024
//                KingfisherManager.shared.defaultOptions = [
//                    .targetCache(targetCache),
//                    .originalCache(originCache),
//                    .processor(DownsamplingImageProcessor(size: CGSize(width: 250, height: 250))),
//                ]
//            }
//        }
//        
//        if let script = configuration.script, let url = script.fileURL, url.pathExtension.lowercased() == "wdui" {
//            do {
//                _ = url.startAccessingSecurityScopedResource()
//                let content = try String(contentsOf: url)
//                for url in regexGetSub(str: content) {
//                    if let url = URL(string: url), url.scheme != "file" {
//                        await fetchImage(url)
//                    }
//                }
//                
//                let entry = SimpleEntry(date: Date(), configuration: configuration, wdjson: content, status: "sucess")
//                return Timeline(entries: [entry], policy: .atEnd)
//            } catch {
//                let entry = SimpleEntry(date: Date(), configuration: configuration, wdjson: nil, status: "failed")
//                configuration.favoriteEmoji = "error"
//                return Timeline(entries: [entry], policy: .atEnd)
//            }
//        }
//        
//        if let script = configuration.script, script.filename.hasSuffix(".py"), let url = script.fileURL {
//            initRemotePython3Sub()
//            configuration.favoriteEmoji = configuration.script?.filename ?? "python"
//            var isStale = false
//            do {
//                _ = url.startAccessingSecurityScopedResource()
//                let output = await executeCommand("pythonA \(url.path) \(configuration.args ?? "")", input: configuration.input)
//                if output == nil {
//                    throw ExecutorError.failed
//                }
//                print(output)
//                let md5 = url.path.md5
//                let mdpath = ConstantManager.WIDGETS.appendingPathComponent("\(md5).wdui")
//                let content = try String(contentsOf: mdpath)
//                print(content)
//                let entry = SimpleEntry(date: Date(), configuration: configuration, wdjson: content, status: "sucess")
//                return Timeline(entries: [entry], policy: .atEnd)
//            } catch {
//                let entry = SimpleEntry(date: Date(), configuration: configuration, wdjson: nil, status: "failed")
//                configuration.favoriteEmoji = "error"
//                return Timeline(entries: [entry], policy: .atEnd)
//            }
//            
//        } else {
//            let entry = SimpleEntry(date: Date(), configuration: configuration, wdjson: nil, status: "no script")
//            return Timeline(entries: [entry], policy: .never)
//        }
//    }
//}

//struct SimpleEntry: TimelineEntry {
//    let date: Date
//    let configuration: ConfigurationAppIntent
//    let wdjson: String?
//    let status: String
//}

struct ScriptEntry: TimelineEntry {
    let date: Date
    var output: String
    var isPlaceholder: Bool = false
//    let configuration: ConfigurationAppIntent
//    let wdjson: String?
//    let status: String
}

struct PlaceholderView: View {
    
    var body: some View {
        ZStack {
            Color.blue
            
            Image(systemName: "play.fill")
                .font(.system(size: 80))
                .foregroundColor(.black)
        }
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
            return AnyView(PlaceholderView())
        } else {
            return AnyView(Color.black)
        }
    }
}

struct RunScriptWidget: Widget {
    let kind = "script"
    
    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ScriptIntent.self, provider: PYProvider(), content: { entry in
            WidgetEntryView(entry: entry)
        })
        .configurationDisplayName("runScript")
        .description("widgetDescriptionRunScript")
    }
}

//struct widgetExtEntryView : View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        if let json = entry.wdjson {
//            let data = Data(json.utf8)
//            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let props = json["properties"] as? [String: Any], let backgroundColor = props["backgroundColor"] as? String {
////                JSONDataView(json: data).background(Color(hex: backgroundColor))
//                if #available(iOS 17.0, *) {
//                    JSONDataView(json: data)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .containerBackground(Color(hex: backgroundColor), for: .widget)
//                } else {
//                    ZStack {
//                        Color(hex: backgroundColor).ignoresSafeArea()
//                        JSONDataView(json: data)
//                    }
//                }
//                
//            } else {
//                JSONDataView(json: data)
//            }
//            
//        } else {
//            VStack {
//                Text("Time:")
//                Text(entry.date, style: .time)
//
//                Text("Favorite Emoji:")
//                Text(entry.configuration.favoriteEmoji)
//            }
//        }
//        
//    }
//}

//struct widgetExt: Widget {
//    let kind: String = "widgetExt"
//
//    var body: some WidgetConfiguration {
//        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
//            widgetExtEntryView(entry: entry)
//        }
//    }
//}

//extension ConfigurationAppIntent {
//    fileprivate static var smiley: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "😀"
//        return intent
//    }
//    
//    fileprivate static var starEyes: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "🤩"
//        return intent
//    }
//}

//#Preview(as: .systemSmall) {
//    widgetExt()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley, wdjson: nil)
//    SimpleEntry(date: .now, configuration: .starEyes, wdjson: nil)
//}

import CommonCrypto
extension String {
  /// 原生md5
  public var md5: String {
    guard let data = data(using: .utf8) else {
      return self
    }
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

    #if swift(>=5.0)
        
    _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
      return CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
    }
        
    #else
        
    _ = data.withUnsafeBytes { bytes in
      return CC_MD5(bytes, CC_LONG(data.count), &digest)
    }

    #endif

    return digest.map { String(format: "%02x", $0) }.joined()

  }
}


extension Color {
    
    init(hex string: String) {
        var string: String = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }

        // Double the last value if incomplete hex
        if !string.count.isMultiple(of: 2), let last = string.last {
            string.append(last)
        }

        // Fix invalid values
        if string.count > 8 {
            string = String(string.prefix(8))
        }

        // Scanner creation
        let scanner = Scanner(string: string)

        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        if string.count == 2 {
            let mask = 0xFF

            let g = Int(color) & mask

            let gray = Double(g) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)

        } else if string.count == 4 {
            let mask = 0x00FF

            let g = Int(color >> 8) & mask
            let a = Int(color) & mask

            let gray = Double(g) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)

        } else if string.count == 6 {
            let mask = 0x0000FF
            let r = Int(color >> 16) & mask
            let g = Int(color >> 8) & mask
            let b = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)

        } else if string.count == 8 {
            let mask = 0x000000FF
            let r = Int(color >> 24) & mask
            let g = Int(color >> 16) & mask
            let b = Int(color >> 8) & mask
            let a = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)

        } else {
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        }
    }
}
