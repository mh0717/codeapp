//
//  QuickPreview.swift
//  pydeApp
//
//  Created by Huima on 2024/2/25.
//

import QuickLook

class QuickPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    let fileUrl: URL
    init(_ fileUrl: URL) {
        self.fileUrl = fileUrl
        super.init(nibName: nil, bundle: nil)
        
        self.dataSource = self
        self.reloadData()
        
        title = fileUrl.lastPathComponent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }

    func previewController(
      _ controller: QLPreviewController,
      previewItemAt index: Int
    ) -> QLPreviewItem {
      return fileUrl as QLPreviewItem
    }
    
    
}
