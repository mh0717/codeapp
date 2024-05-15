//
//  ImageViewerExtension.swift
//  Code
//
//  Created by Ken Chung on 22/11/2022.
//

import SwiftUI

private class Storage: ObservableObject {
    @Published var data: Data? = nil
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

    @EnvironmentObject var storage: Storage

    var body: some View {
        if let data = storage.data {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .pinchToZoom()
                    .contextMenu {
                        ImageContextMenu(uiImage: uiImage)
                    }
            } else {
                Text("Unsupported image")
            }
        } else {
            ProgressView()
        }
    }

}

class ImageViewerExtension: CodeAppExtension {

    private func loadImageToStorage(url: URL, app: MainApp, storage: Storage) {
        app.workSpaceStorage.contents(
            at: url,
            completionHandler: { data, error in
                storage.data = data
                if let error {
                    app.notificationManager.showErrorMessage(error.localizedDescription)
                }
            })
    }

    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let provider = EditorProvider(
            registeredFileExtensions: [
                "png", "tiff", "tif", "jpeg", "jpg", "gif", "bmp", "bmpf", "ico", "cur",
                "xbm", "heic", "webp",
            ],
            onCreateEditor: { [weak self] url in
                let storage = Storage()
                let editorInstance = EditorInstanceWithURL(
                    view: AnyView(ImageView().environmentObject(storage)),
                    title: url.lastPathComponent,
                    url: url
                )

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
    }
}


class PinchZoomView: UIView {

    weak var delegate: PinchZoomViewDelgate?

    private(set) var scale: CGFloat = 0 {
        didSet {
            delegate?.pinchZoomView(self, didChangeScale: scale)
        }
    }

    private(set) var anchor: UnitPoint = .center {
        didSet {
            delegate?.pinchZoomView(self, didChangeAnchor: anchor)
        }
    }

    private(set) var offset: CGSize = .zero {
        didSet {
            delegate?.pinchZoomView(self, didChangeOffset: offset)
        }
    }

    private(set) var isPinching: Bool = false {
        didSet {
            delegate?.pinchZoomView(self, didChangePinching: isPinching)
        }
    }

    private var startLocation: CGPoint = .zero
    private var location: CGPoint = .zero
    private var numberOfTouches: Int = 0

    init() {
        super.init(frame: .zero)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        pinchGesture.cancelsTouchesInView = false
        addGestureRecognizer(pinchGesture)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    @objc private func pinch(gesture: UIPinchGestureRecognizer) {

        switch gesture.state {
        case .began:
            isPinching = true
            startLocation = gesture.location(in: self)
            anchor = UnitPoint(x: startLocation.x / bounds.width, y: startLocation.y / bounds.height)
            numberOfTouches = gesture.numberOfTouches

        case .changed:
            if gesture.numberOfTouches != numberOfTouches {
                // If the number of fingers being used changes, the start location needs to be adjusted to avoid jumping.
                let newLocation = gesture.location(in: self)
                let jumpDifference = CGSize(width: newLocation.x - location.x, height: newLocation.y - location.y)
                startLocation = CGPoint(x: startLocation.x + jumpDifference.width, y: startLocation.y + jumpDifference.height)

                numberOfTouches = gesture.numberOfTouches
            }

            scale = gesture.scale

            location = gesture.location(in: self)
            offset = CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)

        case .ended, .cancelled, .failed:
            withAnimation(.interactiveSpring()) {
                isPinching = false
                scale = 1.0
                anchor = .center
                offset = .zero
            }
        default:
            break
        }
    }

}

protocol PinchZoomViewDelgate: AnyObject {
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize)
}

struct PinchZoom: UIViewRepresentable {

    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var offset: CGSize
    @Binding var isPinching: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PinchZoomView {
        let pinchZoomView = PinchZoomView()
        pinchZoomView.delegate = context.coordinator
        return pinchZoomView
    }

    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }

    class Coordinator: NSObject, PinchZoomViewDelgate {
        var pinchZoom: PinchZoom

        init(_ pinchZoom: PinchZoom) {
            self.pinchZoom = pinchZoom
        }

        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool) {
            pinchZoom.isPinching = isPinching
        }

        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat) {
            pinchZoom.scale = scale
        }

        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint) {
            pinchZoom.anchor = anchor
        }

        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize) {
            pinchZoom.offset = offset
        }
    }
}

struct PinchToZoom: ViewModifier {
    @State var scale: CGFloat = 1.0
    @State var anchor: UnitPoint = .center
    @State var offset: CGSize = .zero
    @State var isPinching: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .offset(offset)
            .overlay(PinchZoom(scale: $scale, anchor: $anchor, offset: $offset, isPinching: $isPinching))
    }
}

extension View {
    func pinchToZoom() -> some View {
        self.modifier(PinchToZoom())
    }
}
