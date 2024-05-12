//
//  ActionViewController.swift
//  pydeUI
//
//  Created by Huima on 2023/10/29.
//

import UIKit

import pydeCommon
import ios_system


// com.apple.app.ui-extension.multiple-instances
// com.apple.ui-services

var isRunning = false

func randomInt(_ min: UInt32, _ max: UInt32) -> UInt32 {
    return min + arc4random() % (max - min + 1)
}

class ActionViewController: UITabBarController {
    
    private var shouldExit = false
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        object_setClass(self.tabBar, WeiTabBar.self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        object_setClass(self.tabBar, WeiTabBar.self)
    }
    
//    private var consoleVC: ConsoleViewContrller?
    
    private var vcs: [UIViewController] = []
    private var activityView: UIActivityIndicatorView?
    
    var ntidentifier: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.isHidden = true
        tabBar.isTranslucent = true
        
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
        
        
        setupView()
        
        ConstantManager.pydeEnv = .remoteUI
        
        if isRunning {
            let alertController = UIAlertController(
                    title: "",
                    message: "Python3 run with UI is alread running, please quit the running instance",
                    preferredStyle: .alert)
            let okAction = UIAlertAction(
                    title: "Exit",
                    style: .destructive,
                    handler: {
                    (action: UIAlertAction!) -> Void in
                        real_exit(vlaue: -1)
                })
                alertController.addAction(okAction)
            present(alertController, animated: true)
            return
        }
        isRunning = true
        shouldExit = true
        
        NotificationCenter.default.addObserver(forName: .init("UI_SHOW_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
            if self.vcs.contains(vc) {
                DispatchQueue.main.async {
                    self.selectedViewController = vc
                }
                return
            }
            
            DispatchQueue.main.async {
                if let activityView = self.activityView {
                    activityView.removeFromSuperview()
                    self.activityView = nil
                }
                vc.title = "test"
                self.vcs.append(vc)
                self.viewControllers = self.vcs
                self.selectedViewController = vc
                self.tabBar.isHidden = self.vcs.count <= 1
                self.preferredContentSize = vc.preferredContentSize;
                
                self.selectedViewController?.addObserver(self, forKeyPath: "preferredContentSize", context: nil)
                
                print(vc.self)
                if NSStringFromClass(type(of: vc)) == "FlutterViewController" {
                    NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
                    vc.perform(Selector("surfaceUpdated:"), with: true)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: .init("UI_HIDE_VC_IN_TAB"), object: nil, queue: nil) { notify in
            guard let vc = notify.userInfo?["vc"] as? UIViewController else {return}
            DispatchQueue.main.async {
                vc.removeObserver(self, forKeyPath: "preferredContentSize")
                self.vcs.removeAll(where: {$0==vc})
                self.viewControllers = self.vcs
                if self.selectedIndex >= self.viewControllers!.count {
                    self.selectedIndex = self.viewControllers!.count - 1
                }
                self.tabBar.isHidden = self.vcs.count <= 1
            }
        }
        
        if let item = extensionContext!.inputItems.first(where: { item in
            if let eitem = item as? NSExtensionItem,
               let userInfo = eitem.userInfo as? [String: Any],
               let _ = userInfo["commands"] as? [String] {
                return true
            }
            return false
        }) as? NSExtensionItem,
           let requestInfo = item.userInfo as? [String: Any] {
            pydeReqInfo = requestInfo
            
            if let ntid = requestInfo["identifier"] as? String {
                self.ntidentifier = ntid
            }
            if let env = requestInfo["env"] as? [String], !env.isEmpty {
                env.forEach { item in
                    putenv(item.utf8CString)
                }
            }
            
            
            
            if let commands = requestInfo["commands"] as? [String] {
                print(commands)
            }
        }
        
//        initRemotePython3Sub()
//        replaceCommand("python3", "python3RunInMain", false)
        initPydeUI()
        
        Thread.detachNewThread {
            remoteExeCommands(context: self.extensionContext!, exit: false)
        }
        
        var watchedDate = Date()
        _ = RunLoop.main.schedule(after: RunLoop.main.now.advanced(by: .seconds(1)), interval: .seconds(3), tolerance: .seconds(1)) {
            watchedDate = Date()
        }
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            watchedDate = Date()
        }
        let watchQueue = DispatchQueue(label: "watch_dog")
        watchQueue.async {
            while true {
                if Date().timeIntervalSince(watchedDate) > 30 {
                    real_exit(vlaue: -1)
                }
                sleep(3)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        handleExit()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let vc = selectedViewController, let ovc = object as? UIViewController, vc == ovc {
            self.preferredContentSize = vc.preferredContentSize
        }
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.systemBackground
        
        let activityView = UIActivityIndicatorView(style: .large)
        activityView.startAnimating()
        self.view.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item: activityView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: activityView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraint(centerX)
        view.addConstraint(centerY)
        self.activityView = activityView
        
        
        let exitBtn = UIButton(type: .close)
//        exitBtn.setTitleColor(UIColor.red, for: .normal)
//        exitBtn.setTitleShadowColor(UIColor.black, for: .normal)
        exitBtn.addTarget(self, action: #selector(handleExit), for: .touchUpInside)
        self.view.addSubview(exitBtn)
        
        exitBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exitBtn.widthAnchor.constraint(equalToConstant: 30),
            exitBtn.heightAnchor.constraint(equalToConstant: 30),
            exitBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            exitBtn.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
        
//        self.preferredContentSize = CGSize(width: 10000, height: 10000)
        
//        self.extensionContext.
        
//        consoleVC = ConsoleViewContrller(root: Bundle.main.bundleURL)
//        consoleVC?.title = "控制台"
//        self.vcs.append(consoleVC!)
//        self.viewControllers = self.vcs
        
//        let flutterEngine = FlutterEngine(name: "/", project: nil, allowHeadlessExecution: false)
//        flutterEngine.run(withEntrypoint: "main", libraryURI: nil, initialRoute: "/", entrypointArgs: ["/", ""])
//        GeneratedPluginRegistrant.register(with: flutterEngine)
//        let vc = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
//        vc.view.backgroundColor = UIColor.red
//        vc.title = "First"
//        self.vcs.append(vc)
//        self.viewControllers = self.vcs
//        self.selectedViewController = vc
    }
    
    
    
    override func viewDidLayoutSubviews() {
        setenv("SDL_SCREEN_SIZE", "\(Int(self.view.bounds.width)):\(Int(self.view.bounds.height))", 1)
    }
    
    @objc func handleExit() {
        if !shouldExit {
            if let ntid = self.ntidentifier {
                wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
            }
            self.extensionContext?.completeRequest(returningItems: nil) {_ in
                
            }
            return
        }
        
        if let ntid = self.ntidentifier {
            wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_DONE_EXIT(ntid))
        }
        wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_UI_DONE_EXIT)
        
        
        Thread.detachNewThread {
            sleep(1)
            real_exit(vlaue: 0)
        }
        self.extensionContext?.completeRequest(returningItems: nil) {_ in
            real_exit(vlaue: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            real_exit(vlaue: 0)
        }
        
    }
    
    
    class WeiTabBar: UITabBar {
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var sizeThatFits = super.sizeThatFits(size)
            sizeThatFits.height = 40
            return sizeThatFits
            
        }
        
    }

}

//
//import UIKit
//import CoreLocation
//
//class LocationManager: NSObject {
//    
//    static let shared = LocationManager()
//    
//    var getLocationHandle: ((_ success: Bool, _ latitude: Double, _ longitude: Double) -> Void)?
//    
//    var getAuthHandle: ((_ success: Bool) -> Void)?
//    
//    private var locationManager: CLLocationManager!
//    
//    override init() {
//        super.init()
//        locationManager = CLLocationManager()
//        //设置了精度最差的 3公里内 kCLLocationAccuracyThreeKilometers
//        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
//        locationManager.delegate = self
//        
//    }
//    /// 设备是否开启了定位服务
//    func hasLocationService() -> Bool {
//        
//        return CLLocationManager.locationServicesEnabled()
//        
//    }
//    /// APP是否有定位权限
//    func hasLocationPermission() -> Bool {
//        
//        switch locationPermission() {
//        case .notDetermined, .restricted, .denied:
//            return false
//        case .authorizedWhenInUse, .authorizedAlways:
//            return true
//        default:
//            break
//        }
//        return false
//    }
//    
//    /// 定位的权限
//    func locationPermission() -> CLAuthorizationStatus {
//        if #available(iOS 14.0, *) {
//            let status: CLAuthorizationStatus = locationManager.authorizationStatus
//            print("location authorizationStatus is \(status.rawValue)")
//            return status
//        } else {
//            let status = CLLocationManager.authorizationStatus()
//            print("location authorizationStatus is \(status.rawValue)")
//            return status
//        }
//    }
//    
//    
//    //MARK: - 获取权限，在代理‘didChangeAuthorization’中拿到结果
//    func requestLocationAuthorizaiton() {
//        locationManager.requestWhenInUseAuthorization()
//        
//    }
//    //MARK: - 获取位置
//    func requestLocation() {
////        locationManager.requestLocation()
//        locationManager.startUpdatingLocation()
//    }
//    
//}
//
//extension LocationManager: CLLocationManagerDelegate {
//   //MARK: - ios 14.0 之前，获取权限结果的方法
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        handleChangedAuthorization()
//    }
//    
//    //MARK: - ios 14.0，获取权限结果的方法
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        handleChangedAuthorization()
//    }
//    
//    private func handleChangedAuthorization() {
//        if let block = getAuthHandle, locationPermission() != .notDetermined {
//            if hasLocationPermission() {
//                block(true)
//            } else {
//                block(false)
//            }
//        }
//    }
//    //MARK: - 获取定位后的经纬度
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let loction = locations.last {
//            
//            print("latitude: \(loction.coordinate.latitude)   longitude:\(loction.coordinate.longitude)")
//            
//            if let block = getLocationHandle {
//                block(true, loction.coordinate.latitude, loction.coordinate.longitude)
//            }
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        
//        if let block = getLocationHandle {
//            block(false, 0, 0)
//        }
//        print("get location failed. error:\(error.localizedDescription)")
//    }
//}
