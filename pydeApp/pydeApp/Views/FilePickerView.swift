//
//  FilePickerView.swift
//  Code
//
//  Created by Huima on 2024/5/7.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import pydeCommon

struct FilePickerView: UIViewControllerRepresentable {

    @EnvironmentObject var App: MainApp
    let onOpen: ((URL) -> Void)
    
    let allowedTypes: [UTType]
//    [UTType(filenameExtension: "whl")!]

    func makeCoordinator() -> Coordinator {
        return FilePickerView.Coordinator(parent1: self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = context.coordinator
        documentPicker.shouldShowFileExtensions = true
        return documentPicker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController, context: Context
    ) {

    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: FilePickerView
        var fileQuery: NSMetadataQuery?

        init(parent1: FilePickerView) {
            parent = parent1
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                parent.App.notificationManager.showErrorMessage("Permission denied")
                return
            }
            parent.onOpen(url)
        }
    }
}
