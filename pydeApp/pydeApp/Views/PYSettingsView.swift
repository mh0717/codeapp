//
//  PYSettingsView.swift
//  pydeApp
//
//  Created by Huima on 2024/3/2.
//

import SwiftUI

struct PYSettingsView: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager
    
    @AppStorage("editorLightTheme") var selectedLightTheme: String = "Light+"
    @AppStorage("editorDarkTheme") var selectedDarkTheme: String = "Dark+"
    @AppStorage("preferredColorScheme") var preferredColorScheme: Int = 0
    
    @AppStorage("editorFontSize") var fontSize: Int = 14
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14
    
    @AppStorage("explorer.showHiddenFiles") var showHiddenFiles: Bool = false
    
    @AppStorage("communityTemplatesEnabled") var communityTemplatesEnabled = true

    @State var showsEraseAlert: Bool = false
    @State var showReceiptInformation: Bool = false

    let colorSchemes = ["Automatic", "Dark", "Light"]
    

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    
    func setTheme(_ name: String) {
        var item = SettingsThemeConfiguration.defaultLightPlusTheme
        if name == "Dark+" {
            item = SettingsThemeConfiguration.defaultDarkPlusTheme
        } else if name == "Light+" {
            item = SettingsThemeConfiguration.defaultLightPlusTheme
        } else {
            item = themeManager.themes.first(where: {$0.name == name}) ?? item
        }
        
        if item.url.scheme == "https" {
            themeManager.currentTheme = nil

            if item.isDark {
                globalDarkTheme = nil
                selectedDarkTheme = item.name
            } else {
                globalLightTheme = nil
                selectedLightTheme = item.name
            }
            let notification = Notification(
                name: Notification.Name("theme.updated"),
                userInfo: ["isDark": item.isDark]
            )
            NotificationCenter.default.post(notification)
            return
        }
        var theItem = item
        if item.isDark {
            globalDarkTheme = theItem.dictionary
            selectedDarkTheme = item.name
        } else {
            globalLightTheme = theItem.dictionary
            selectedLightTheme = item.name
        }

        themeManager.currentTheme = item

        let notification = Notification(
            name: Notification.Name("theme.updated")
        )
        NotificationCenter.default.post(notification)
    }

    var body: some View {
        NavigationView {
            Form {
                // TODO: Rework Editor / Terminal settings to support multiple scenes
                
                Group {
                    Section(header: Text("General")) {
                        
                        
                        DisclosureGroup("Themes") {
                            Picker(selection: Binding(get: {
                                selectedLightTheme
                            }, set: { value in
                                selectedLightTheme = value
                                setTheme(value)
                            }), label: Text("Light Themes")) {
                                ForEach(
                                    ([SettingsThemeConfiguration.defaultLightPlusTheme]
                                     + themeManager.themes.sorted { $0.name < $1.name }.filter {
                                         !$0.isDark
                                     }).map({$0.name}),
                                    id: \.self
                                ) { item in
                                    Text(item)
                                }
                            }
                            
                            Picker(selection: Binding(get: {
                                selectedDarkTheme
                            }, set: { value in
                                selectedDarkTheme = value
                                setTheme(value)
                            }), label: Text("Dark Themes")) {
                                ForEach(
                                    ([SettingsThemeConfiguration.defaultDarkPlusTheme]
                                     + themeManager.themes.sorted { $0.name < $1.name }.filter {
                                         $0.isDark
                                     }).map({$0.name}),
                                    id: \.self
                                ) { item in
                                    Text(item)
                                }
                            }
                        }
                        
                        Picker(selection: $preferredColorScheme, label: Text("Color Scheme")) {
                            ForEach(0..<colorSchemes.count, id: \.self) {
                                Text(self.colorSchemes[$0])
                            }
                        }
                        
                        
                        Stepper(
                            "\(NSLocalizedString("Editor Font Size", comment: "")) (\(fontSize))",
                            value: $fontSize, in: 10...30
                        ).onChange(of: fontSize) { value in
                            App.monacoInstance.executeJavascript(
                                command: "editor.updateOptions({fontSize: \(String(value))})")
                        }
                        
                        Stepper(
                            "\(NSLocalizedString("Console Font Size", comment: "")) (\(consoleFontSize))",
                            value: $consoleFontSize, in: 8...24)
                        
                    }
                    
                    Section(header: Text(NSLocalizedString("Version Control", comment: ""))) {
                        NavigationLink(destination: SourceControlIdentityConfiguration()) {
                            Text("Author Identity")
                        }
                        NavigationLink(destination: SourceControlAuthenticationConfiguration()) {
                            Text("Authentication")
                        }
//                        Toggle(
//                            "source_control.community_templates", isOn: $communityTemplatesEnabled)
                    }
                    
                    Section(header: Text(NSLocalizedString("EXPLORER", comment: ""))) {
                        Toggle(
                            NSLocalizedString("Show hidden files", comment: ""),
                            isOn: $showHiddenFiles)
                    }
                    
                    EditorSetting()
                        
                    
                    TerminalSetting()
                    
                    
                    Section(header: Text(NSLocalizedString("About", comment: ""))) {
                        
//                        NavigationLink(
//                            destination: SimpleMarkDownView(
//                                text: NSLocalizedString("Changelog.message", comment: ""))
//                        ) {
//                            Text(NSLocalizedString("Release Notes", comment: ""))
//                        }
                        Link(
                            "Terms of Use",
                            destination: URL(string:"https://www.jianshu.com/p/8ee503e0ae6f")!
                        )
                        Link(
                            "Privacy Agreement",
                            destination: URL(string: "https://www.jianshu.com/p/3fe837f0abbe")!)
                        
                        Button(action: {
                            showsEraseAlert.toggle()
                        }) {
                            Text(NSLocalizedString("Erase all settings", comment: ""))
                                .foregroundColor(
                                    .red)
                        }
                        .alert(isPresented: $showsEraseAlert) {
                            Alert(
                                title: Text(NSLocalizedString("Erase all settings", comment: "")),
                                message: Text(
                                    NSLocalizedString(
                                        "This will erase all user settings, including author identity and credentials.",
                                        comment: "")),
                                primaryButton: .destructive(
                                    Text(NSLocalizedString("Erase", comment: ""))
                                ) {
                                    UserDefaults.standard.dictionaryRepresentation().keys.forEach {
                                        key in
                                        UserDefaults.standard.removeObject(forKey: key)
                                    }
                                    KeychainWrapper.standard.set("", forKey: "git-username")
                                    KeychainWrapper.standard.set("", forKey: "git-password")
                                    NSUserActivity.deleteAllSavedUserActivities {}
                                    App.notificationManager.showInformationMessage(
                                        "All settings erased")
                                }, secondaryButton: .cancel())
                        }
                        //                    Link(
                        //                        "terms_of_use",
                        //                        destination: URL(
                        //                            string:
                        //                                "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                        //                        )!
                        //                    )
                        //                    Link(
                        //                        "code.and.privacy",
                        //                        destination: URL(string: "https://thebaselab.com/privacypolicies/")!)
                        //
                        //                    NavigationLink(
                        //                        destination: SimpleMarkDownView(
                        //                            text: NSLocalizedString("licenses", comment: ""))
                        //                    ) {
                        //                        Text("Licenses")
                        //                    }
                        HStack {
                            Text(NSLocalizedString("Version", comment: ""))
                            Spacer()
                            Text(
                                (Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                                 as? String
                                 ?? "0.0") + " Build "
                                + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                                   ?? "0")
                            )
                        }
                        
                        //                    Text("Code App by thebaselab").font(.footnote).foregroundColor(.gray)
                        //                        .onTapGesture(
                        //                            count: 2,
                        //                            perform: {
                        //                                showReceiptInformation = true
                        //                            })
                    }
                    
                }
                .listRowBackground(Color.init(id: "list.inactiveSelectionBackground"))
            }
            .navigationTitle(Text("Settings"))
            .configureToolbarBackground()
            .preferredColorScheme(themeManager.colorSchemePreference)
        }
    }
}

fileprivate struct EditorSetting: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager
    
    let renderWhitespaceOptions = ["None", "Boundary", "Selection", "Trailing", "All"]
    let wordWrapOptions = ["off", "on", "wordWrapColumn", "bounded"]
    
    
    @AppStorage("editorFontFamily") var fontFamily: String = "Menlo"
    @AppStorage("fontLigatures") var fontLigatures: Bool = false
    @AppStorage("quoteAutoCompletionEnabled") var quoteAutoCompleteEnabled: Bool = true
    @AppStorage("suggestionEnabled") var suggestionEnabled: Bool = true
    @AppStorage("editorMiniMapEnabled") var miniMapEnabled: Bool = true
    @AppStorage("editorLineNumberEnabled") var editorLineNumberEnabled: Bool = true
    @AppStorage("editorShowKeyboardButtonEnabled") var editorShowKeyboardButtonEnabled: Bool = true
    @AppStorage("editorTabSize") var edtorTabSize: Int = 4
    
    @AppStorage("editorRenderWhitespace") var renderWhitespace: Int = 0
    @AppStorage("editorWordWrap") var editorWordWrap: String = "off"
    
    @AppStorage("toolBarEnabled") var toolBarEnabled: Bool = true
    @AppStorage("alwaysOpenInNewTab") var alwaysOpenInNewTab: Bool = false
    @AppStorage("editorSmoothScrolling") var editorSmoothScrolling: Bool = false
    @AppStorage("editorReadOnly") var editorReadOnly = false
    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    
    @AppStorage("editorSpellCheckEnabled") var editorSpellCheckEnabled = false
    @AppStorage("editorSpellCheckOnContentChanged") var editorSpellCheckOnContentChanged = true
    
    @AppStorage("showAllFonts") var showAllFonts = false
    @AppStorage("remoteShouldResolveHomePath") var remoteShouldResolveHomePath = false
    
    let editors = ["Monaco Editor", "PYCode Editor"]
    @AppStorage("codeEditor") var codeEditor = "PYCode Editor"
    
    var body: some View {
        Section(header: Text(NSLocalizedString("Editor", comment: ""))) {
            
            VStack(alignment: .leading, spacing: 0) {
                Picker(
                    selection: $codeEditor,
                    label: Text(localizedString(forKey:"Editor Selection"))
                ) {
                    ForEach(
                        editors,
                        id: \.self
                    ) { item in
                        Text(localizedString(forKey: item))
                    }
                }
                Text(localizedString(forKey:"Monaco Editor is more suitable for hardware keyboard\nPYCode Editor is more suitable for software keyboard")).font(.system(size: 13)).opacity(0.5)
            }
            
            Stepper(
                "\(NSLocalizedString("Tab Size", comment: "")) (\(edtorTabSize))",
                value: $edtorTabSize, in: 1...8
            ).onChange(of: edtorTabSize) { value in
                App.monacoInstance.executeJavascript(
                    command: "editor.updateOptions({tabSize: \(String(value))})")
            }
            
            Toggle("Read-only Mode", isOn: self.$editorReadOnly).onChange(
                of: editorReadOnly
            ) { value in
                App.monacoInstance.executeJavascript(
                    command: "editor.updateOptions({ readOnly: \(String(value)) })")
            }
            Toggle("UI State Restoration", isOn: self.$stateRestorationEnabled)
            
            Toggle(
                NSLocalizedString("Bracket Completion", comment: ""),
                isOn: self.$quoteAutoCompleteEnabled
            ).onChange(of: quoteAutoCompleteEnabled) { value in
                App.monacoInstance.executeJavascript(
                    command:
                        "editor.updateOptions({ autoClosingBrackets: \(String(value)) })"
                )
            }
            
            Toggle(
                NSLocalizedString("Monaco Editor Mini Map", comment: ""),
                isOn: self.$miniMapEnabled
            ).onChange(of: miniMapEnabled) { value in
                App.monacoInstance.executeJavascript(
                    command:
                        "editor.updateOptions({minimap: {enabled: \(String(value))}})"
                )
            }
            
            Toggle(
                NSLocalizedString("Line Numbers", comment: ""),
                isOn: self.$editorLineNumberEnabled
            ).onChange(of: editorLineNumberEnabled) { value in
                App.monacoInstance.executeJavascript(
                    command:
                        "editor.updateOptions({ lineNumbers: \(String(value)) })")
            }
            
            Toggle("Text Wrap", isOn: Binding(get: {
                editorWordWrap != "off"
            }, set: { value in
                editorWordWrap = value ? "on" : "off"
                App.monacoInstance.executeJavascript(
                    command: "editor.updateOptions({wordWrap: '\(editorWordWrap)'})"
                )
            }))
            
            Toggle("Render Whitespace", isOn: Binding(get: {
                renderWhitespace != 0
            }, set: { value in
                renderWhitespace = value ? 4 : 0
                App.monacoInstance.executeJavascript(
                    command:
                        "editor.updateOptions({renderWhitespace: '\(String(renderWhitespaceOptions[renderWhitespace]).lowercased())'})"
                )
            }))
        }
    }
}

fileprivate struct TerminalSetting: View {
    @AppStorage("compilerShowPath") var compilerShowPath = false
    @AppStorage("setting.panel.global.show") var showGlobalPanel = true
    
#if DEBUG
    @AppStorage("runUIInPreview") var runUIInPreview = false
#endif
    
    var body: some View {
        Section(header: Text("local.execution.title")) {
            Toggle("Show Command in Terminal", isOn: $compilerShowPath)
            Toggle("Global Terminal", isOn: $showGlobalPanel)
#if DEBUG
            Toggle("runUIInPreview", isOn: $runUIInPreview)
#endif
        }
    }
}

//extension View {
//    @ViewBuilder
//    func configureToolbarBackground() -> some View {
//        if #available(iOS 16.4, *) {
//            self
//                .toolbarBackground(
//                    Color.init(id: "activityBar.background"), for: .navigationBar
//                )
//        } else {
//            self
//        }
//    }
//}
