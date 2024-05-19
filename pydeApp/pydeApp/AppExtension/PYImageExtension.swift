//
//  PYImageExtension.swift
//  Code
//
//  Created by Huima on 2024/5/16.
//

import Foundation
import SwiftUI

class PYImageEditorInstance: EditorInstanceWithURL {
    let storage: PYImageStorage
    
    init(storage: PYImageStorage, title: String, url: URL) {
        self.storage = storage
        
        super.init(
            view: AnyView(ImageView().environmentObject(storage)),
            title: title,
            url: url
        )
    }
    
    init(image: UIImage, title: String) {
        self.storage = PYImageStorage()
        self.storage.image = image
        super.init(
            view: AnyView(ImageView().environmentObject(storage)),
            title: title,
            url: URL(string: "image://\(UUID().uuidString)")!
        )
    }
}

class PYImageStorage: ObservableObject {
    @Published var data: Data? = nil
    @Published var image: UIImage? = nil
}

private struct ImageContextMenu: View {

    let uiImage: UIImage

    var body: some View {
        Button {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        } label: {
            Label("Add to Photos", systemImage: "square.and.arrow.down")
        }
        Button {
            UIPasteboard.general.image = uiImage
        } label: {
            Label("Copy Image", systemImage: "doc.on.doc")
        }

    }

}

private struct ImageView: View {

    @EnvironmentObject var storage: PYImageStorage

    var body: some View {
        if let data = storage.data {
            if let uiImage = storage.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
//                    .pinchToZoom()
                    .contextMenu {
                        ImageContextMenu(uiImage: uiImage)
                    }
            } else {
                Text("Unsupported image")
            }
        } else if let uiImage = storage.image {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
//                .pinchToZoom()
                .contextMenu {
                    ImageContextMenu(uiImage: uiImage)
                }
        } else {
            ProgressView()
        }
    }

}

class PYImageViewerExtension: CodeAppExtension {

    private func loadImageToStorage(url: URL, app: MainApp, storage: PYImageStorage) {
        app.workSpaceStorage.contents(
            at: url,
            completionHandler: { data, error in
                storage.data = data
                if let data {
                    storage.image = UIImage(data: data)
                }
                if let error {
                    app.notificationManager.showErrorMessage(error.localizedDescription)
                }
            })
    }

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let imgExtensions =  [
            "png", "tiff", "tif", "jpeg", "jpg", "gif", "bmp", "bmpf", "ico", "cur",
            "xbm", "heic", "webp",
        ]
        let provider = EditorProvider(
            registeredFileExtensions: imgExtensions,
            onCreateEditor: { [weak self] url in
                let storage = PYImageStorage()
//                let editorInstance = EditorInstanceWithURL(
//                    view: AnyView(ImageView().environmentObject(storage)),
//                    title: url.lastPathComponent,
//                    url: url
//                )
                let editorInstance = PYImageEditorInstance(storage: storage, title: url.lastPathComponent, url: url)

                self?.loadImageToStorage(url: url, app: app, storage: storage)
                editorInstance.fileWatch?.folderDidChange = { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.loadImageToStorage(url: url, app: app, storage: storage)
                    }
                }
                editorInstance.fileWatch?.startMonitoring()

                return editorInstance
            }
        )
        contribution.editorProvider.register(provider: provider)
        
        let isImage: () -> Bool = {
            return app.activeEditor is PYImageEditorInstance
        }
        
        let addToPhoto = ToolbarItem(
            extenionID: "ADD_TO_PHOTO",
            icon: "square.and.arrow.down",
            onClick: {
                if let editor = app.activeEditor as? PYImageEditorInstance, let image = editor.storage.image {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            },
            shouldDisplay: isImage
        )
        
        let copyImage = ToolbarItem(
            extenionID: "COPYIMAGE",
            icon: "doc.on.doc",
            onClick: {
                if let editor = app.activeEditor as? PYImageEditorInstance, let image = editor.storage.image {
                    UIPasteboard.general.image = image
                }
            },
            shouldDisplay: isImage
        )
        
        contribution.toolBar.registerItem(item: addToPhoto)
        contribution.toolBar.registerItem(item: copyImage)
    }
}


public struct SwiftUIImageViewer: View {

    let image: Image

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero

    public init(image: Image) {
        self.image = image
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.x, y: offset.y)
                    .gesture(makeDragGesture(size: proxy.size))
                    .gesture(makeMagnificationGesture(size: proxy.size))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
    }

    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }

    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }

    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}
