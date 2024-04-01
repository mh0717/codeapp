//
//  PyRuntimes.swift
//  iPyDE
//
//  Created by Huima on 2024/3/18.
//

import SwiftUI
import pydeCommon

private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

struct PyRuntimesView : View {
    @State var foreCount = 1
    
    var body: some View {
        NavigationView {
            List{
                Section("Python3 Interpreters") {
                    ForEach(Array(ConstantManager.RemotePlugins.keys).sorted(), id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString("Interpreter: ", comment: "") + String(item.last!)).foregroundColor(.primary)
                                Text(ConstantManager.RemotePlugins[item] ?? "")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            if foreCount > 0 { Spacer()}
                            if let cmd = ConstantManager.RemotePlugins[item], cmd.count > 0 {
                                Button("", systemImage: "stop.circle") {
                                    wmessager.passMessage(message: "", identifier: ConstantManager.PYDE_REMOTE_FORCE_EXIT(item))
                                }
                            }
                        }
                    }
                }
            }
            
        }.onReceive(timer) { _ in
            self.foreCount += 1
        }
    }
}
