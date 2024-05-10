//
//  IapManager.swift
//  Code
//
//  Created by Huima on 2024/5/10.
//

import SwiftUI
import RMStore
import pydeCommon


class IapManager: ObservableObject {
    @Published var isPurchased: Bool = false
    @Published var isTrialing: Bool = false
    @Published var showIap: Bool = false
    @Published var isTrialed: Bool = false
    @Published var purchasing: Bool = false
    @Published var product: SKProduct? = nil
    @Published var restoring: Bool = false
    
    var runCout:Int = 0
    
    private let persistor = RMStoreKeychainPersistence()
    
    init() {
        RMStore.default().transactionPersistor = persistor
        
        if let countData = RMKeychainGetValue("ipyde.runcount"),
           let countStr = String(data: countData, encoding: .utf8),
           let count = Int(countStr, radix: 10) {
            runCout = count + 1
        } else {
            runCout = 1
        }
        if let data = String(format: "%d", runCout).data(using: .utf8) {
            RMKeychainSetValue(data, "ipyde.runcount")
        }
        
        if let trialData = RMKeychainGetValue("ipyde.trialDate"),
           let trialStr = String(data: trialData, encoding: .utf8),
           let trialInterval = Double(trialStr) {
            let now = Date.now.timeIntervalSince1970
            if now - trialInterval <= 3 * 24 * 60 * 60 {
                isTrialing = true
                isTrialed = false
            } else {
                isTrialing = false
                isTrialed = true
            }
        }
        
        
        isPurchased = persistor.isPurchasedProduct(ofIdentifier: ConstantManager.IAP_UNLOCK_ID)
        
        if let product = RMStore.default().product(forIdentifier: ConstantManager.IAP_UNLOCK_ID) {
            self.product = product
        }
        
        RMStore.default().requestProducts([ConstantManager.IAP_UNLOCK_ID]) { products, _ in
            if let product = RMStore.default().product(forIdentifier: ConstantManager.IAP_UNLOCK_ID) {
                DispatchQueue.main.async {
                    self.product = product
                }
            }
        } failure: { err in
            
        }
    }
    
//    func tryPurchase() {
//        if product == nil {
//            RMStore.default().requestProducts([ConstantManager.IAP_UNLOCK_ID]) { products, _ in
//                if let product = RMStore.default().product(forIdentifier: ConstantManager.IAP_UNLOCK_ID) {
//                    self.product = product
//                    self.purchase()
//                }
//            } failure: { err in
//
//            }
//        } else {
//            purchase()
//        }
//    }
    
    func trial() {
        if isTrialed || isTrialing {
            return
        }
        
        let interval = Date.now.timeIntervalSince1970
        let str = String(format: "%lf", interval)
        if let data = str.data(using: .utf8) {
            RMKeychainSetValue(data, "ipyde.trialDate")
            isTrialing = true
            isTrialed = false
            showIap = false
        }
    }
    
    func purchase() async -> Bool {
        await MainActor.run {
            self.purchasing = true
        }
        
        if product == nil {
            let pd = try? await withUnsafeThrowingContinuation({ continuation in
                RMStore.default().requestProducts([ConstantManager.IAP_UNLOCK_ID]) { products, _ in
                    if let product = RMStore.default().product(forIdentifier: ConstantManager.IAP_UNLOCK_ID) {
                        continuation.resume(returning: product)
                    }
                    continuation.resume(returning: nil)
                } failure: { err in
                    continuation.resume(returning: nil)
                }
            })
            if let pd {
                await MainActor.run {
                    self.product = pd
                }
            }
        }
        
        
        if product == nil {
            return false
        }
        
        
        let result = try? await withUnsafeThrowingContinuation({ continuation in
            RMStore.default().addPayment(ConstantManager.IAP_UNLOCK_ID) {[self] _ in
                if persistor.isPurchasedProduct(ofIdentifier: ConstantManager.IAP_UNLOCK_ID) {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            } failure: { _, err in
                continuation.resume(returning: false)
            }
        })
        await MainActor.run {
            self.purchasing = false
            if self.persistor.isPurchasedProduct(ofIdentifier: ConstantManager.IAP_UNLOCK_ID) {
                self.isPurchased = true
                self.showIap = false
            }
        }
        
        if let result {
            return result
        }
        return false
    }
    
    func restore() async -> Bool {
        await MainActor.run {
            self.restoring = true
        }
        
        let result = try? await withUnsafeThrowingContinuation({ continuation in
            RMStore.default().restoreTransactions { _ in
                continuation.resume(returning: true)

            } failure: { _ in
                continuation.resume(returning: false)
            }
        })
        
        await MainActor.run {
            self.restoring = false
            isPurchased = OCPurchase.isUnlockPurchased()
            if isPurchased {
                showIap = false
            }
        }
        
        if let result {
            return result
        }
        return false
    }
    
    static let instance = IapManager()
}
