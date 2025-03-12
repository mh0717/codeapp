//
//  Widget.swift
//  widgetExtExtension
//
//  Created by Huima on 2024/6/16.
//

import WidgetKit
import SwiftUI
import Intents

//struct PYProvider: IntentTimelineProvider {
//    func getSnapshot(for configuration: ScriptIntent, in context: Context, completion: @escaping (ScriptEntry) -> Void) {
//        var entry = ScriptEntry(date: Date(), output: "")
//        entry.isPlaceholder = true
//        completion(entry)
//    }
//    
//    func placeholder(in context: Context) -> ScriptEntry {
//        return ScriptEntry(date: Date(), output: NSLocalizedString("noSelectedScript", comment: ""))
//    }
//    
//    func getTimeline(for configuration: ScriptIntent, in context: Context, completion: @escaping (Timeline<ScriptEntry>) -> Void) {
//        completion(Timeline(entries: [ScriptEntry(date: Date(), output:"")], policy: .atEnd))
//    }
//}
//
//struct ScriptEntry: TimelineEntry {
//    let date: Date
//    var output: String
//    var isPlaceholder = false
////    let configuration: ScriptIntent
//}
//
//struct WidgetEntryView : View {
//    var entry: PYProvider.Entry
//
//    var body: some View {
//        VStack {
//            Text("Time:")
//            Text(entry.date, style: .time)
//
//            Text("Favorite Emoji:")
//        }
//    }
//}
//
//struct PYWidget: Widget {
//    private let kind: String = "Script"
//
//    public var body: some WidgetConfiguration {
//        IntentConfiguration(kind: kind, intent: ScriptIntent.self, provider: PYProvider(), content: { entry in
//            WidgetEntryView(entry: entry)
//        })
//        .configurationDisplayName("runScript")
//        .description("widgetDescriptionRunScript")
//    }
//}
//


struct PYProvider: IntentTimelineProvider {
    func getSnapshot(for configuration: ScriptIntent, in context: Context, completion: @escaping (ScriptEntry) -> Void) {
        var entry = ScriptEntry(date: Date(), output: "")
        entry.isPlaceholder = true
        completion(entry)
    }
    
    func placeholder(in context: Context) -> ScriptEntry {
        return ScriptEntry(date: Date(), output: "")
    }
    
    func getTimeline(for configuration: ScriptIntent, in context: Context, completion: @escaping (Timeline<ScriptEntry>) -> Void) {
        completion(Timeline(entries: [ScriptEntry(date: Date(), output:"")], policy: .atEnd))
    }
}

struct ScriptEntry: TimelineEntry {
    let date: Date
    var output: String
    var isPlaceholder = false
//    let configuration: ScriptIntent
}

struct WidgetEntryView : View {
    var entry: PYProvider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Favorite Emoji:")
        }
    }
}

struct PYWidget: Widget {
    private let kind: String = "Run PYScript"

    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ScriptIntent.self, provider: PYProvider(), content: { entry in
            WidgetEntryView(entry: entry)
        })
        .configurationDisplayName("runpyScript")
        .description("widgetDescriptionRunScriptpy")
    }
}

