//
//  UIView+Pipable.swift
//  Code
//
//  Created by huima on 2025/4/11.
//

// 弱引用包装类
private final class WeakWrapper {
    weak var value: AnyObject?
    init(_ value: AnyObject) {
        self.value = value
    }
}

extension UIView: Pipable {
    private enum AssociatedKeys {
            static var pictureInPictureDelegate = "pictureInPictureDelegateKey"
        }
    
    public var pictureInPictureDelegate: PictureInPictureDelegate? {
        get {
            guard let wrapper = objc_getAssociatedObject(self, &AssociatedKeys.pictureInPictureDelegate) as? WeakWrapper,
                  let delegate = wrapper.value as? PictureInPictureDelegate
            else {
                return nil
            }
            return delegate
        }
        set {
            if let newValue = newValue {
                let wrapper = WeakWrapper(newValue)
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.pictureInPictureDelegate,
                    wrapper,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            } else {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.pictureInPictureDelegate,
                    nil,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
    
    public var previewSize: CGSize {
        return bounds.size
    }
    
    public func willTakeSnapshot() {
        
    }
    
    public func didTakeSnapshot() {
        
    }
    
    
}
