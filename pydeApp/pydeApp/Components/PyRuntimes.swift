//
//  PyRuntimes.swift
//  iPyDE
//
//  Created by Huima on 2024/3/18.
//

import SwiftUI
import pydeCommon

struct PyRuntimesView : View {
    var body: some View {
        NavigationView {
            List{
                Section("Python3 Runtimes") {
                    ForEach(Array(ConstantManager.RemotePlugins.keys), id: \.self) { item in
                        HStack {
                            VStack {
                                Text(item)
                                Text(ConstantManager.RemotePlugins[item] ?? "")
                            }
                            Spacer()
                            if let cmd = ConstantManager.RemotePlugins[item], cmd.count > 0 {
                                Button("", systemImage: "stop.circle") {
                                    
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
}
