//
//  SceneReader.swift
//  Code
//
//  Created by huima on 2025/3/21.
//

import SwiftUI
import UIKit

// 定义环境键
struct WindowSceneKey: EnvironmentKey {
    static let defaultValue: UIWindowScene? = nil
}

extension EnvironmentValues {
    var windowScene: UIWindowScene? {
        get { self[WindowSceneKey.self] }
        set { self[WindowSceneKey.self] = newValue }
    }
}


// 场景读取器（用于注入环境）
struct SceneReader<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var windowScene: UIWindowScene?
    
    var body: some View {
        content
            .environment(\.windowScene, windowScene) // 注入环境
            .background(
                ControllerReader { controller in
                    
                    // 通过 Controller 捕获 Scene
                    if let controller {
                        DispatchQueue.main.async {
                            windowScene = controller.view.window?.windowScene
                            print(windowScene)
                            if windowScene == nil {
                                CATransaction.begin()
                                CATransaction.setCompletionBlock {
                                    windowScene = controller.view.window?.windowScene
                                }
                                // 在此添加动画或其他事务
                                CATransaction.commit()
                            }
                            
                        }
                    }
                    
                    return Color.clear
                }
            )
    }
}

// UIKit 控制器读取器（用于获取 UIViewController）
struct ControllerReader<Content: View>: UIViewControllerRepresentable {
    let content: (UIViewController?) -> Content
    
    func makeUIViewController(context: Context) -> UIViewController {
        let fakeView = content(nil)
        let controller = UIHostingController(rootView: fakeView)
        let contentView = content(controller)
        controller.rootView = contentView;
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    class Coordinator {
//        weak var controller: UIViewController?
//    }
}
