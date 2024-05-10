//
//  SubIapManager.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import SwiftUI
import RMStore
import pydeCommon
import RevenueCat

class IAPExtension: CodeAppExtension {
    
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(5))) {
            #if PYTHON3IDE
            
            let im = SubIapManager.instance
            #if DEBUG
            #else
            if im.runCout >= 5, !im.isPro {
                im.showIap = true
            }
            #endif
            
            #else
            let im = IapManager.instance
            if !im.isPurchased && !im.isTrialing && im.runCout >= 5 {
                #if DEBUG
                #else
                im.showIap = true
                #endif
            }
            #endif
        }
    }
    
//    override func onWorkSpaceStorageChanged(newUrl: URL) {
//
//    }
}

class SubIapManager: ObservableObject {
    @Published var showIap: Bool = false
    @Published var isTrialing: Bool = false
    @Published var purchasing: Bool = false
    @Published var restoring: Bool = false
    
    
    @Published var offering: Offering?
    @Published var customerInfo: CustomerInfo?
    @Published var selectedPackage: Package?
    
    var monthly: Package? {
        offering?.monthly
    }
    var sixMonth: Package? {
        offering?.sixMonth
    }
    var annual: Package? {
        offering?.annual
    }
    var unlockPackage: Package? {
        offering?.lifetime
    }
    var entitlementInfos: EntitlementInfos? {
        customerInfo?.entitlements
    }
    var proEntitlement: EntitlementInfo? {
        entitlementInfos?.all["pro"]
    }
    var unlockEntitlement: EntitlementInfo? {
        entitlementInfos?.all["unlock"]
    }
    var isPro: Bool {
        proEntitlement?.isActive ?? false
    }
    var isOldUnlock: Bool {
        unlockEntitlement?.isActive ?? false
    }
    
    var errorMsg: String = ""
    
    func initRevenucat() {
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: "HZQrQMJwHIYaPwErZrCVUOJHpOVSoLsa")
//                .with(usesStoreKit2IfAvailable: true)
                .build()
        )
        /// - Set the delegate to this instance of AppDelegate. Scroll down to see this implementation.
//        Purchases.shared.delegate = self
        updateRevenucat()
    }
    func updateRevenucat() {
        Purchases.shared.getOfferings {[self] (offerings, error)  in
            if let error = error {
                print(error.localizedDescription)
            }
            if let offerings {
                self.offering = offerings.current
            }
            if self.selectedPackage == nil {
                if self.isPro {
                    if proEntitlement?.productIdentifier == monthly?.storeProduct.productIdentifier {
                        selectedPackage = monthly
                    } else if proEntitlement?.productIdentifier == sixMonth?.storeProduct.productIdentifier {
                        selectedPackage = sixMonth
                    }else if proEntitlement?.productIdentifier == annual?.storeProduct.productIdentifier {
                        selectedPackage = annual
                    }
                } else {
                    self.selectedPackage = self.annual
                }
            }
        }
        Purchases.shared.getCustomerInfo { customerInfo, error in
            if let error = error {
                print(error.localizedDescription)
            }
            if let customerInfo {
                self.customerInfo = customerInfo
            }
        }
    }
    
    var runCout:Int = 0
    
    private let persistor = RMStoreKeychainPersistence()
    
    init() {
        if let countData = RMKeychainGetValue("python3ide.runcount"),
           let countStr = String(data: countData, encoding: .utf8),
           let count = Int(countStr, radix: 10) {
            runCout = count + 1
        } else {
            runCout = 1
        }
        if let data = String(format: "%d", runCout).data(using: .utf8) {
            RMKeychainSetValue(data, "python3ide.runcount")
        }
        
        initRevenucat()
    }
    
    @MainActor func purchase() async -> Bool {
        guard !purchasing, !restoring, let selectedPackage else {
            return false
        }
        
        purchasing = true
        
        do {
            let result = try await Purchases.shared.purchase(package: selectedPackage)
            customerInfo = result.customerInfo
            purchasing = false
            if !result.userCancelled, isPro {
                return true
            }
        } catch {
            errorMsg = error.localizedDescription
        }
        purchasing = false
        
        return false
    }
    
    @MainActor func restore() async -> Bool {
        guard !purchasing, !restoring else {
            return false
        }
        
        restoring = true
        
        do {
            let result = try await Purchases.shared.restorePurchases()
            customerInfo = result
            restoring = false
            
            if isPro {
                return true
            }
        } catch {
            errorMsg = error.localizedDescription
        }
        restoring = false
        
        return false
    }
    
    
    
    
    
    
    static let instance = SubIapManager()
}
