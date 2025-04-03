//
//  Notify.swift
//  Code
//
//  Created by huima on 2025/4/1.
//

class NotificationExtension: CodeAppExtension {
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        NotificationCenter.default.addObserver(forName: .NOTIFY_SHOW_INFOMATION, object: nil, queue: nil) { [weak app] notify in
            guard let app, app.sceneIdentifier.uuidString == (notify.userInfo?["sceneid"] as? String ?? "") else {
                return
            }
            DispatchQueue.main.async {
                app.notificationManager.showInformationMessage(notify.userInfo?["message"] as? String ?? "")
            }
        }
        
        NotificationCenter.default.addObserver(forName: .NOTIFY_SHOW_WARNING, object: nil, queue: nil) { [weak app] notify in
            guard let app, app.sceneIdentifier.uuidString == (notify.userInfo?["sceneid"] as? String ?? "") else {
                return
            }
            DispatchQueue.main.async {
                app.notificationManager.showWarningMessage(notify.userInfo?["message"] as? String ?? "")
            }
        }
        
        NotificationCenter.default.addObserver(forName: .NOTIFY_SHOW_ERROR, object: nil, queue: nil) { [weak app] notify in
            guard let app, app.sceneIdentifier.uuidString == (notify.userInfo?["sceneid"] as? String ?? "") else {
                return
            }
            DispatchQueue.main.async {
                app.notificationManager.showErrorMessage(notify.userInfo?["message"] as? String ?? "")
            }
        }
        
        NotificationCenter.default.addObserver(forName: .NOTIFY_SHOW_SUCESS, object: nil, queue: nil) { [weak app] notify in
            guard let app, app.sceneIdentifier.uuidString == (notify.userInfo?["sceneid"] as? String ?? "") else {
                return
            }
            DispatchQueue.main.async {
                app.notificationManager.showSucessMessage(notify.userInfo?["message"] as? String ?? "")
            }
        }
    }
}


extension Notification.Name {
    static let NOTIFY_SHOW_INFOMATION = Notification.Name("NOTIFY_SHOW_INFOMATION")
    static let NOTIFY_SHOW_WARNING = Notification.Name("NOTIFY_SHOW_WARNING")
    static let NOTIFY_SHOW_ERROR = Notification.Name("NOTIFY_SHOW_ERROR")
    static let NOTIFY_SHOW_SUCESS = Notification.Name("NOTIFY_SHOW_SUCESS")
}
