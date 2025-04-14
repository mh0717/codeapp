//
//  IosPlugin.swift
//  Code
//
//  Created by huima on 2025/4/10.
//

func runIdeCataPlugin() {
    /// 1. Form the plugin's bundle URL
    let bundleFileName = "ideCata.bundle"
    guard let bundleURL = Bundle.main.builtInPlugInsURL?
                                .appendingPathComponent(bundleFileName) else { return }

    /// 2. Create a bundle instance with the plugin URL
    guard let bundle = Bundle(url: bundleURL) else { return }

    /// 3. Load the bundle and our plugin class
    let className = "ideCata.MacPlugin"
    guard let pluginClass = bundle.classNamed(className) as? Plugin.Type else { return }

    /// 4. Create an instance of the plugin class
    let plugin = pluginClass.init()
    plugin.sayHello()
}


//func runIdeCataRemote(_ requestInfo: [String: Any]) -> Int {
//    let bundleFileName = "ideCata.bundle"
//    guard let bundleURL = Bundle.main.builtInPlugInsURL?
//                                .appendingPathComponent(bundleFileName) else { return 1}
//
//    /// 2. Create a bundle instance with the plugin URL
//    guard let bundle = Bundle(url: bundleURL) else { return 1}
//
//    /// 3. Load the bundle and our plugin class
//    let className = "ideCata.MacPlugin"
//    guard let pluginClass = bundle.classNamed(className) as? Plugin.Type else { return 1}
//
//    /// 4. Create an instance of the plugin class
//    let plugin = pluginClass.init()
//    
//    let result = plugin.runRemote(requestInfo)
//    return result
//}
