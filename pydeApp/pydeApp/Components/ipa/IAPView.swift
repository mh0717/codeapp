//
//  IAPView.swift
//  pydeApp
//
//  Created by Huima on 2024/1/28.
//

import Foundation
import SwiftUI
import pydeCommon
import python3_objc
import CryptoKit

struct IAPView: View {
    
    @EnvironmentObject var App: MainApp
    
    
    var body: some View {
        TabView {
            Text("First")
            Text("Second")
            Text("Third")
        }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}



#Preview("IAP") {
    IAPView()
}



