//
//  SplitViewController.swift
//  SplitKit
//
//  Created by Matteo Gavagnin on 01/09/2017.
//  Copyright © 2017 Dolomate.
//  See LICENSE file for more details.
//

import UIKit

/// Simple container controller that let you dispose two child controllers side by side or one on top of the other, supporting gesture to resize the different areas. Vertical and Horizontal disposition is supported.
@objc(SPKSplitView)
open class SplitView: UIView {

    /// The ratio of the first child.
    @objc public var ratio: CGFloat = 0.65
    
    /// Specify the animation duration to change split orientation between horizontal to vertical and vice versa. Default is 0.25 seconds.
    @objc public var invertAnimationDuration : TimeInterval = 0.25

    // Default value is similar to the UINavigationBar shadow.
    /// Specify the split separator color
    @objc public var separatorColor : UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3) {
        didSet {
            horizontalSeparatorHair.backgroundColor = separatorColor
            verticalSeparatorHair.backgroundColor = separatorColor
        }
    }
    
    /// Specify the split separator color while being dragged
    @objc public var separatorSelectedColor : UIColor = UIColor(red: 233/255, green: 90/255, blue: 57/255, alpha: 1.0) {
        didSet {
            horizontalHandle.barColor = separatorSelectedColor
            verticalHandle.barColor = separatorSelectedColor
        }
    }
    
    fileprivate var shouldAnimateSplitChange = false
    
    /// Change the controllers arrangement:
    /// - side by side with `.horizontal`
    /// - top and bottom with `.vertical`
    @objc public var arrangement : Arrangement = .horizontal {
        didSet {
            let duration = shouldAnimateSplitChange ? invertAnimationDuration : 0.0
            
            switch arrangement {
            case .horizontal:
                firstViewTrailingConstraint.isActive = false
                firstViewHeightConstraint.isActive = false
                firstViewHeightRatioConstraint?.isActive = false
                secondViewFirstTopConstraint.isActive = false
                secondViewLeadingConstraint.isActive = false
                horizontalSeparatorView.isHidden = false
                firstViewBottomConstraint.isActive = true
                firstViewWidthConstraint.isActive = true
                firstViewWidthRatioConstraint?.isActive = true
                secondViewFirstLeadingConstraint.isActive = true
                secondViewTopConstraint.isActive = true
                verticalSeparatorView.isHidden = true
                
//                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: { [unowned self] in
//                    self.layoutIfNeeded()
//                }, completion: { (completed) in
//
//                })
                break
            case .vertical:
                
                firstViewBottomConstraint.isActive = false
                firstViewWidthConstraint.isActive = false
                firstViewWidthRatioConstraint?.isActive = false
                secondViewFirstLeadingConstraint.isActive = false
                secondViewTopConstraint.isActive = false
                verticalSeparatorView.isHidden = false
                firstViewTrailingConstraint.isActive = true
                firstViewHeightConstraint.isActive = true
                firstViewHeightRatioConstraint?.isActive = true
                secondViewFirstTopConstraint.isActive = true
                secondViewLeadingConstraint.isActive = true
                horizontalSeparatorView.isHidden = true
                
//                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: { [unowned self] in
//                    self.layoutIfNeeded()
//                    }, completion: { (completed) in
//
//                })
                break
            }
            
//            if duration == 0.0 {
//                self.layoutIfNeeded()
//            }
        }
    }
    
    /// Switch to the other disposition
    ///
    /// - Parameter sender: the button that triggered the orientation change
    @IBAction func switchArrangement(_ sender: Any? = nil) {
        switch arrangement {
        case .horizontal:
            arrangement = .vertical
            break
        case .vertical:
            arrangement = .horizontal
            break
        }
    }
    
    /// Set the top or leading controller
    @objc public var firstChild : UIView? {
        didSet {
            if let oldController = oldValue {
                oldController.removeFromSuperview()
            }
            if let child = firstChild {
                child.frame = firstContainerView.bounds
                child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                firstContainerView.addSubview(child)
            }
            self.layoutIfNeeded()
        }
    }
    
    /// Set the bottom or trailing controller
    @objc public var secondChild : UIView? {
        didSet {
            if let oldController = oldValue {
                oldController.removeFromSuperview()
            }
            if let child = secondChild {
                child.frame = secondContainerView.bounds
                child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                secondContainerView.addSubview(child)
            }
            self.layoutIfNeeded()
        }
    }

    private let horizontalSeparatorView = UIView()
    private let verticalSeparatorView = UIView()
    
    private let firstContainerView = UIView()
    private let secondContainerView = UIView()
    
    private var firstViewTopConstraint : NSLayoutConstraint!
    private var firstViewBottomConstraint : NSLayoutConstraint!
    private var firstViewLeadingConstraint : NSLayoutConstraint!
    private var firstViewTrailingConstraint : NSLayoutConstraint!
    private var firstViewWidthConstraint : NSLayoutConstraint!
    private var firstViewHeightConstraint : NSLayoutConstraint!
    
    private var firstViewWidthRatioConstraint : NSLayoutConstraint?
    private var firstViewHeightRatioConstraint : NSLayoutConstraint?
    
    private var secondViewTopConstraint : NSLayoutConstraint!
    private var secondViewBottomConstraint : NSLayoutConstraint!
    private var secondViewLeadingConstraint : NSLayoutConstraint!
    private var secondViewTrailingConstraint : NSLayoutConstraint!
    private var secondViewFirstLeadingConstraint : NSLayoutConstraint!
    private var secondViewFirstTopConstraint : NSLayoutConstraint!
    
    private var bottomKeyboardHeight : CGFloat = 0.0
    
    private let horizontalSeparatorHair = UIView()
    private var horizontalSeparatorWidthConstraint : NSLayoutConstraint!
    
    private let verticalSeparatorHair = UIView()
    private var verticalSeparatorHeightConstraint : NSLayoutConstraint!
    
    private let horizontalHandle = HandleView(.horizontal)
    private let verticalHandle = HandleView(.vertical)
    
    fileprivate var didAppearFirstRound = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        firstContainerView.frame = self.bounds
        firstContainerView.accessibilityIdentifier = "FirstContainerView"
        firstContainerView.backgroundColor = .white
        firstContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(firstContainerView)
        
        firstViewTopConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .top, relatedBy: .equal, toItem: firstContainerView, attribute: .top, multiplier: 1, constant: 0)
        firstViewBottomConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .bottom, relatedBy: .equal, toItem: firstContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        firstViewLeadingConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .leading, relatedBy: .equal, toItem: firstContainerView, attribute: .leading, multiplier: 1, constant: 0)
        firstViewTrailingConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .trailing, relatedBy: .equal, toItem: firstContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        
        self.addConstraint(firstViewTopConstraint!)
        self.addConstraint(firstViewBottomConstraint!)
        self.addConstraint(firstViewLeadingConstraint!)
        firstViewTrailingConstraint.isActive = false
        self.addConstraint(firstViewTrailingConstraint!)
        
        firstViewWidthConstraint = NSLayoutConstraint(item: firstContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: (self.bounds.size.width - self.safeAreaInsets.left - self.safeAreaInsets.right) / 2.0)
        firstViewHeightConstraint = NSLayoutConstraint(item: firstContainerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: (self.bounds.size.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom) / 2.0)
        
        
        firstViewWidthConstraint.priority = .defaultLow
        self.addConstraint(firstViewWidthConstraint!)
        
        firstViewHeightConstraint.priority = .defaultLow
        firstViewHeightConstraint.isActive = false
        self.addConstraint(firstViewHeightConstraint!)
        
        secondContainerView.frame = self.bounds
        secondContainerView.accessibilityIdentifier = "SecondContainerView"
        secondContainerView.backgroundColor = .white
        secondContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(secondContainerView)
        
        secondViewTopConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .top, relatedBy: .equal, toItem: secondContainerView, attribute: .top, multiplier: 1, constant: 0)
        secondViewBottomConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .bottom, relatedBy: .equal, toItem: secondContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        secondViewLeadingConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .leading, relatedBy: .equal, toItem: secondContainerView, attribute: .leading, multiplier: 1, constant: 0)
        secondViewTrailingConstraint = NSLayoutConstraint(item: self.safeAreaLayoutGuide, attribute: .trailing, relatedBy: .equal, toItem: secondContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        
        
        secondViewTopConstraint.isActive = false
        self.addConstraint(secondViewTopConstraint!)
        self.addConstraint(secondViewBottomConstraint!)
        secondViewLeadingConstraint.isActive = false
        self.addConstraint(secondViewLeadingConstraint!)
        self.addConstraint(secondViewTrailingConstraint!)
        
        secondViewFirstTopConstraint = NSLayoutConstraint(item: secondContainerView, attribute: .top, relatedBy: .equal, toItem: firstContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        secondViewFirstTopConstraint.isActive = false
        secondViewFirstLeadingConstraint = NSLayoutConstraint(item: secondContainerView, attribute: .leading, relatedBy: .equal, toItem: firstContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        secondViewFirstLeadingConstraint.isActive = false
        
        let separatorSize : CGFloat = 44.0
        horizontalSeparatorView.frame = CGRect(x: (self.bounds.size.width - separatorSize) / 2.0, y: 0.0, width: separatorSize, height: self.bounds.size.height)
        horizontalSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        horizontalSeparatorView.alpha = 1.0
        horizontalSeparatorView.backgroundColor = .clear
        self.addSubview(horizontalSeparatorView)
        self.addConstraint(NSLayoutConstraint(item: firstContainerView, attribute: .trailing, relatedBy: .equal, toItem: horizontalSeparatorView, attribute: .centerX, multiplier: 1, constant: 0))
        
        
        self.addConstraint(NSLayoutConstraint(item: horizontalSeparatorView, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: horizontalSeparatorView, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0))
        
        
        self.addConstraint(NSLayoutConstraint(item: horizontalSeparatorView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: separatorSize))
        
        let horizontalPanGesture = InstantPanGestureRecognizer(target: self, action: #selector(horizontalPanGestureDidPan))
        
        horizontalPanGesture.delaysTouchesBegan = false
        horizontalSeparatorView.addGestureRecognizer(horizontalPanGesture)
        
        horizontalSeparatorHair.frame = horizontalSeparatorView.bounds
        horizontalSeparatorHair.backgroundColor = separatorColor
        horizontalSeparatorView.addSubview(horizontalSeparatorHair)
        horizontalSeparatorHair.translatesAutoresizingMaskIntoConstraints = false
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalSeparatorHair, attribute: .top, relatedBy: .equal, toItem: horizontalSeparatorView, attribute: .top, multiplier: 1, constant: 0))
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalSeparatorHair, attribute: .bottom, relatedBy: .equal, toItem: horizontalSeparatorView, attribute: .bottom, multiplier: 1, constant: 0))
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalSeparatorHair, attribute: .centerX, relatedBy: .equal, toItem: horizontalSeparatorView, attribute: .centerX, multiplier: 1, constant: 0))
        horizontalSeparatorWidthConstraint = NSLayoutConstraint(item: horizontalSeparatorHair, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1.0 / UIScreen.main.scale)
        horizontalSeparatorView.addConstraint(horizontalSeparatorWidthConstraint!)
        horizontalSeparatorView.addSubview(horizontalSeparatorHair)
        
        horizontalSeparatorView.addSubview(horizontalHandle)
        horizontalHandle.translatesAutoresizingMaskIntoConstraints = false
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalHandle, attribute: .centerX, relatedBy: .equal, toItem: horizontalSeparatorView, attribute: .centerX, multiplier: 1, constant: 0))
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalHandle, attribute: .centerY, relatedBy: .equal, toItem: horizontalSeparatorView, attribute: .centerY, multiplier: 1, constant: 0))
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalHandle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: handleSize.height))
        horizontalSeparatorView.addConstraint(NSLayoutConstraint(item: horizontalHandle, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: handleSize.width))
        
        verticalSeparatorView.frame = CGRect(x: 0.0, y: (self.bounds.size.height - separatorSize) / 2.0, width: self.bounds.size.width, height: separatorSize)
        verticalSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        verticalSeparatorView.alpha = 1.0
        verticalSeparatorView.backgroundColor = .clear
        self.addSubview(verticalSeparatorView)
        self.addConstraint(NSLayoutConstraint(item: firstContainerView, attribute: .bottom, relatedBy: .equal, toItem: verticalSeparatorView, attribute: .centerY, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: verticalSeparatorView, attribute: .leading, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: verticalSeparatorView, attribute: .trailing, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: verticalSeparatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: separatorSize))
        
        let verticalPanGesture = InstantPanGestureRecognizer(target: self, action: #selector(verticalPanGestureDidPan))
        verticalPanGesture.delaysTouchesBegan = false
        verticalSeparatorView.addGestureRecognizer(verticalPanGesture)
        
        verticalSeparatorHair.frame = verticalSeparatorView.bounds
        verticalSeparatorHair.backgroundColor = separatorColor
        verticalSeparatorView.addSubview(verticalSeparatorHair)
        verticalSeparatorHair.translatesAutoresizingMaskIntoConstraints = false
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalSeparatorHair, attribute: .leading, relatedBy: .equal, toItem: verticalSeparatorView, attribute: .leading, multiplier: 1, constant: 0))
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalSeparatorHair, attribute: .trailing, relatedBy: .equal, toItem: verticalSeparatorView, attribute: .trailing, multiplier: 1, constant: 0))
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalSeparatorHair, attribute: .centerY, relatedBy: .equal, toItem: verticalSeparatorView, attribute: .centerY, multiplier: 1, constant: 0))
        verticalSeparatorHeightConstraint = NSLayoutConstraint(item: verticalSeparatorHair, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1.0 / UIScreen.main.scale)
        verticalSeparatorView.addConstraint(verticalSeparatorHeightConstraint!)
        verticalSeparatorView.addSubview(verticalSeparatorHair)
        
        verticalSeparatorView.addSubview(verticalHandle)
        verticalHandle.translatesAutoresizingMaskIntoConstraints = false
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalHandle, attribute: .centerX, relatedBy: .equal, toItem: verticalSeparatorView, attribute: .centerX, multiplier: 1, constant: 0))
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalHandle, attribute: .centerY, relatedBy: .equal, toItem: verticalSeparatorView, attribute: .centerY, multiplier: 1, constant: 0))
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalHandle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: handleSize.height))
        verticalSeparatorView.addConstraint(NSLayoutConstraint(item: verticalHandle, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: handleSize.width))
        
        switch traitCollection.horizontalSizeClass {
        case .compact:
            self.arrangement = .vertical
            break
        case .regular:
            self.arrangement = .horizontal
            break
        case .unspecified:
            self.arrangement = .vertical
        }
        
        let horizontalRatio : CGFloat = ratio
        let verticalRatio : CGFloat = ratio
        firstViewWidthRatioConstraint = NSLayoutConstraint(item: firstContainerView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: horizontalRatio, constant: 0)
        firstViewWidthRatioConstraint?.priority = .defaultHigh
        self.addConstraint(firstViewWidthRatioConstraint!)
        
        firstViewHeightRatioConstraint = NSLayoutConstraint(item: firstContainerView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: verticalRatio, constant: 0)
        firstViewHeightRatioConstraint?.priority = .defaultHigh
        firstViewHeightRatioConstraint?.isActive = false
        self.addConstraint(firstViewHeightRatioConstraint!)
        
        
        firstViewHeightConstraint.constant = (self.bounds.size.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom) / 2.0
        
        self.arrangement = .horizontal
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    open override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        if didAppearFirstRound == false {
//            if #available(iOS 11.0, *) {
//                firstViewHeightConstraint.constant = (view.bounds.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom) / 2.0
//            } else {
//                firstViewHeightConstraint.constant = (view.bounds.size.height - topLayoutGuide.length - bottomLayoutGuide.length) / 2.0
//            }
//            didAppearFirstRound = true
//        }
//        shouldAnimateSplitChange = true
//
//        //debugPrint(">>>>>>>> Split addObserver")
//
//        // We do some magic to detect bottom safe area to react the the keyboard size change (appearance, disappearance, ecc)
//        NotificationCenter.default.addObserver(self, selector: #selector(updateRect(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
//    }
    
    @objc func updateRect(notification: NSNotification) {
        //debugPrint(">>>>>>>> Split FIRED NOTIFICATION")
        
        let initialRect = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue
        let _ = self.frame.size.height - self.convert(initialRect!, from: nil).origin.y
        let keyboardRect = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let newHeight = self.frame.size.height - self.convert(keyboardRect!, from: nil).origin.y
        
        self.bottomKeyboardHeight = newHeight
    }
    
//    open override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        //debugPrint(">>>>>>>> Split viewDidDisappear remove observer")
//        NotificationCenter.default.removeObserver(self)
//    }

    private var panInitialX : CGFloat = 0.0
    private var panInitialY : CGFloat = 0.0
    
    @IBAction private func horizontalPanGestureDidPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            guard let senderView = sender.view else { break }
            var ratio : CGFloat = self.ratio
            var width : CGFloat = 1.0
            firstViewWidthRatioConstraint?.isActive = false
            if let multiplier = firstViewWidthRatioConstraint?.multiplier {
                ratio = multiplier
            }
            
            panInitialX = senderView.frame.origin.x - self.safeAreaInsets.left - self.safeAreaInsets.right + senderView.frame.size.width / 2
            width = self.bounds.size.width - self.safeAreaInsets.left - self.safeAreaInsets.right
  
            firstViewWidthConstraint.constant = width * ratio
            firstViewWidthConstraint.priority = .defaultHigh
            horizontalSeparatorWidthConstraint.constant = 2.0
            UIView.animate(withDuration: draggingAnimationDuration, delay: 0, options: .curveEaseInOut, animations: { [unowned self] in
                self.horizontalSeparatorHair.alpha = 1.0
                self.horizontalHandle.alpha = 1.0
                self.horizontalSeparatorHair.backgroundColor = self.separatorSelectedColor
                // self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    
            })
            horizontalHandle.snapped = .none
        case .changed:
            let translation = sender.translation(in: self)
            let finalX = panInitialX + translation.x
            var maximumAllowedWidth : CGFloat = 0.0
            if #available(iOS 11.0, *) {
                maximumAllowedWidth = self.frame.size.width - self.safeAreaInsets.left - self.safeAreaInsets.right
            } else {
                maximumAllowedWidth = self.frame.size.width
            }
            if finalX >= maximumAllowedWidth {
                firstViewWidthConstraint.constant = maximumAllowedWidth
            } else if finalX > 0 {
                firstViewWidthConstraint.constant = finalX
            } else {
                firstViewWidthConstraint.constant = 0
            }
            break
        case .ended:
            var snapped = false
            // If we are near a border, just snap to it
            if firstViewWidthConstraint.constant >= (self.bounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right) * 0.85 {
                firstViewWidthConstraint.constant = self.bounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right
                snapped = true
                horizontalHandle.snapped = .trail
            } else if firstViewWidthConstraint.constant <= (self.bounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right) * 0.15 {
                firstViewWidthConstraint.constant = 0
                snapped = true
                horizontalHandle.snapped = .lead
            }
            horizontalSeparatorWidthConstraint.constant = 1.0 / UIScreen.main.scale
            UIView.animate(withDuration: draggingAnimationDuration, delay: 0, options: .curveEaseOut, animations: { [unowned self] in
                if snapped == false {
                    self.horizontalHandle.alpha = 0.0
                } else {
                    self.horizontalSeparatorHair.alpha = 0.0
                }
                self.horizontalSeparatorHair.backgroundColor = self.separatorColor
                self.layoutIfNeeded()
            }, completion: { (completed) in
                self.restoreHorizontalRatioConstraint()
            })
            if draggingAnimationDuration == 0.0 {
                restoreHorizontalRatioConstraint()
            }
            
            break
        default:
            break
        }
    }
    
    func restoreHorizontalRatioConstraint() {
        self.firstViewWidthConstraint.priority = .defaultLow
        var ratio : CGFloat = 1.0
        if #available(iOS 11.0, *) {
            ratio = self.firstContainerView.bounds.size.width / (self.bounds.size.width - self.safeAreaInsets.left - self.safeAreaInsets.right)
        } else {
            ratio = self.firstContainerView.bounds.size.width / self.bounds.width
        }
        if ratio < 0.0 {
            ratio = 0.0
        } else if ratio > 1.0 {
            ratio = 1.0
        }
        self.removeConstraint(self.firstViewWidthRatioConstraint!)
        self.firstViewWidthRatioConstraint = NSLayoutConstraint(item: self.firstContainerView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: ratio, constant: 0)
        self.addConstraint(self.firstViewWidthRatioConstraint!)
    }
    
    @IBAction private func verticalPanGestureDidPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            guard let senderView = sender.view else { break }
            var ratio : CGFloat = self.ratio
            var height : CGFloat = 1.0
            if let multiplier = firstViewHeightRatioConstraint?.multiplier {
                ratio = multiplier
            }
            firstViewHeightRatioConstraint?.isActive = false
            
            
            panInitialY = senderView.frame.origin.y - self.safeAreaInsets.top - self.safeAreaInsets.bottom + senderView.frame.size.height / 2
            height = self.bounds.size.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom
            
            firstViewHeightConstraint.constant = height * ratio
            firstViewHeightConstraint.priority = .defaultHigh
            verticalSeparatorHeightConstraint.constant = 2.0
            UIView.animate(withDuration: draggingAnimationDuration, delay: 0, options: .curveEaseInOut, animations: { [unowned self] in
                self.verticalSeparatorHair.alpha = 1.0
                self.verticalHandle.alpha = 1.0
                self.verticalSeparatorHair.backgroundColor = self.separatorSelectedColor
                self.layoutIfNeeded()
                }, completion: { (completed) in
                    
            })
            verticalHandle.snapped = .none
        case .changed:
            let translation = sender.translation(in: self)
            let finalY = panInitialY + translation.y
            var maximumAllowedHeight : CGFloat = 0.0
            maximumAllowedHeight = self.frame.size.height - self.safeAreaInsets.top - bottomKeyboardHeight
            
            if finalY >= maximumAllowedHeight {
                firstViewHeightConstraint.constant = maximumAllowedHeight
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } else if finalY > 0 {
                firstViewHeightConstraint.constant = finalY
            } else {
                firstViewHeightConstraint.constant = 0
            }
            break
        case .ended:
            var snapped = false
            // If we are near a border, just snap to it
            
            if firstViewHeightConstraint.constant >= (self.bounds.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom) * 0.85 {
                firstViewHeightConstraint.constant = self.bounds.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom
                snapped = true
                verticalHandle.snapped = .bottom
            } else if firstViewHeightConstraint.constant <= (self.bounds.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom) * 0.15 {
                firstViewHeightConstraint.constant = 0
                snapped = true
                verticalHandle.snapped = .top
            }
 
            verticalSeparatorHeightConstraint.constant = 1.0 / UIScreen.main.scale
            UIView.animate(withDuration: invertAnimationDuration, delay: 0, options: .curveEaseOut, animations: { [unowned self] in
                if snapped == false {
                    self.verticalHandle.alpha = 0.0
                } else {
                    self.verticalSeparatorHair.alpha = 0.0
                }
                self.verticalSeparatorHair.backgroundColor = self.separatorColor
                self.layoutIfNeeded()
                }, completion: { (completed) in
                    self.restoreVerticalRatioConstraint()
            })
            if invertAnimationDuration == 0.0 {
                restoreVerticalRatioConstraint()
            }
            break
        default:
            break
        }
    }
    
    func restoreVerticalRatioConstraint() {
        self.firstViewHeightConstraint.priority = .defaultLow
        var ratio : CGFloat = 1.0
        
        ratio = self.firstContainerView.bounds.size.height / (self.bounds.size.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom)

        if ratio < 0 {
            ratio = 0.0
        } else if ratio > 1 {
            ratio = 1.0
        }
        self.removeConstraint(self.firstViewHeightRatioConstraint!)
        self.firstViewHeightRatioConstraint = NSLayoutConstraint(item: self.firstContainerView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: ratio, constant: 0)
        self.addConstraint(self.firstViewHeightRatioConstraint!)
    }

    func prepareViews(animated: Bool = false) {
        
    }
    
    var arrupdated = false
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let arr: Arrangement = self.bounds.width < 600 || self.bounds.height > self.bounds.width ? .vertical : .horizontal
        
        if !arrupdated {
            self.arrangement = arr
            arrupdated = true
        }
        
        if (self.arrangement != arr) {
            self.arrangement = arr
        }
        
        
//        let currentRatio : CGFloat
//
//        currentRatio = self.firstViewWidthConstraint.constant / (self.bounds.size.width - self.safeAreaInsets.left - self.safeAreaInsets.right)
//
//        let newWidth = (self.bounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right) * currentRatio
//        self.firstViewWidthConstraint.constant = newWidth
        
    }
    
//    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        let currentRatio : CGFloat
//        if #available(iOS 11.0, *) {
//            currentRatio = self.firstViewWidthConstraint.constant / (self.view.bounds.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right)
//        } else {
//            currentRatio = self.firstViewWidthConstraint.constant / self.view.bounds.size.width
//        }
//        super.viewWillTransition(to: size, with: coordinator)
//        coordinator.animate(alongsideTransition: { [unowned self] (context) in
//            var newWidth : CGFloat = 0.0
//            if #available(iOS 11.0, *) {
//                newWidth = (size.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right) * currentRatio
//            } else {
//                newWidth = size.width * currentRatio
//            }
//            self.firstViewWidthConstraint.constant = newWidth
//        }) { (context) in
//
//        }
//    }
    
//    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.willTransition(to: newCollection, with: coordinator)
//        coordinator.animate(alongsideTransition: { [unowned self] (context) in
//            switch newCollection.horizontalSizeClass {
//            case .compact:
//                self.arrangement = .vertical
//                break
//            case .regular:
//                self.arrangement = .horizontal
//                break
//            case .unspecified:
//                self.arrangement = .vertical
//            }
//        }) { (context) in
//
//        }
//    }
}

