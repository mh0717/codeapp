//
//  main.swift
//  ideRemoteCata
//
//  Created by huima on 2025/4/10.
//

import Foundation
import pydeCommon
import CCommon
import UIKit



//
//import UIKit
//
//// 1. 自定义 AppDelegate
//class AppDelegate: UIResponder, UIApplicationDelegate {
//    var window: UIWindow?
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        // 创建窗口
//        window = UIWindow(frame: CGRectMake(0, 0, 800, 800))
//        
//        // 设置根视图控制器（空视图）
//        window?.rootViewController = UIViewController()
//        window?.backgroundColor = UIColor.red
//        window?.rootViewController?.view.backgroundColor = UIColor.blue
//        
//        // 显示窗口
//        window?.makeKeyAndVisible()
//        return true
//    }
//}
//
//// 2. 手动启动应用
//UIApplicationMain(
//    CommandLine.argc,
//    CommandLine.unsafeArgv,
//    nil,
//    NSStringFromClass(AppDelegate.self)
//)



let args = CommandLine.arguments.dropFirst()
if args.isEmpty {
    real_exit(vlaue: 1)
}

let path = args.first!
let url = URL(fileURLWithPath: path)
print(url)
guard let data = try? Data(contentsOf: url),
      let requestInfo = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
    print("requestInfo nil!!!!!")
    real_exit(vlaue: 1)
    exit(1)
}
ConstantManager.pydeEnv = .remote

if let env = requestInfo["env"] as? [String], !env.isEmpty {
        env.forEach { item in
            ios_putenv(item.utf8CString)
            putenv(item.utf8CString)
        }
    }

/// 如果有这个环境变量，jupyter kernel会检测父进程，ios应该检测不了，kernel就直接退出
unsetenv("JPY_PARENT_PID")

initRemotePython3Sub()
let result = remoteExe(requestInfo: requestInfo)
print("result: ", result)
real_exit(vlaue: Int(result))
exit(result)


