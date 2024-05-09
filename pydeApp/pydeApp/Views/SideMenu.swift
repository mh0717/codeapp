//
//  SideMenu.swift
//  Code
//
//  Created by Huima on 2024/5/6.
//

import SwiftUI


public struct SideMenu<MenuContent: View>: ViewModifier {
    @Binding var isShowing: Bool
    @Binding var isEnabled: Bool
    
    @State private var offset = -320.0
    let sideWidth = 320.0
    
    
    private let menuContent: () -> MenuContent
    
    public init(isEnabled: Binding<Bool>, isShowing: Binding<Bool>,
         @ViewBuilder menuContent: @escaping () -> MenuContent) {
        _isEnabled = isEnabled
        _isShowing = isShowing
        self.menuContent = menuContent
    }
    
    public func body(content: Content) -> some View {
        let drag = DragGesture().onChanged({ event in
            if !isEnabled {
                return
            }
            if !isShowing {
                if event.startLocation.x < 10 {
                    offset =  min(max(event.location.x - sideWidth, -sideWidth), 0)
                    
                }
            } else {
                if event.startLocation.x >= sideWidth {
                    
                    offset = min(max(event.translation.width, -sideWidth), 0)
                }
            }
        })
            .onEnded { event in
                if !isEnabled {
                    return
                }
                
                if !isShowing {
                    if offset >= -sideWidth * 0.7 {
                        withAnimation {
                            offset = 0
                            isShowing = true
                        }
                        
                    } else {
                        withAnimation {
                            offset = -sideWidth
                        }
                        
                    }
                    return
                }
                
                if isShowing {
                    if event.startLocation.x >= sideWidth, event.translation.width < 10 {
                        withAnimation {
                            isShowing = false
                            offset = -sideWidth
                        }
                    }
                    
                }
            }
        
        return GeometryReader { geometry in
          ZStack(alignment: .leading) {
              content
              
              Color.black.ignoresSafeArea().opacity((offset + sideWidth) / sideWidth * 0.6).onTapGesture {
                  if isShowing {
                      withAnimation {
                          isShowing = false
                          offset = -sideWidth
                      }
                  }
              }
              
              Color.white.opacity(0.00001).frame(width: 10)
            
              menuContent()
                .frame(width: sideWidth)
                .transition(.move(edge: .leading))
                .offset(x: offset)
          }.gesture(drag)
        }
    }
}


public extension View {
    func sideMenu<MenuContent: View>(
        isEnabled: Binding<Bool>,
        isShowing: Binding<Bool>,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) -> some View {
        self.modifier(SideMenu(isEnabled: isEnabled, isShowing: isShowing, menuContent: menuContent))
    }
}

public struct TwoSideMenu<MenuContent: View, RightMenu: View>: ViewModifier {
    @Binding var isShowing: Bool
    @Binding var isEnabled: Bool
    @Binding var isRightShowing: Bool
    @Binding var isRightEnabled: Bool
    
    @State var width = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    
    @State var rightOffset = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    
    @State private var offset = -320.0
    let sideWidth = 320.0
    
    
    
    
    private let menuContent: () -> MenuContent
    private let rightMenu: () -> RightMenu
    
    public init(isEnabled: Binding<Bool>, isShowing: Binding<Bool>, isRightEnabled: Binding<Bool>, isRightShowing: Binding<Bool>,
                
         @ViewBuilder menuContent: @escaping () -> MenuContent,
                @ViewBuilder rightMenu: @escaping () -> RightMenu) {
        _isEnabled = isEnabled
        _isShowing = isShowing
        _isRightEnabled = isRightEnabled
        _isRightShowing = isRightShowing
        self.menuContent = menuContent
        self.rightMenu = rightMenu
    }
    
    public func body(content: Content) -> some View {
        let drag = DragGesture().onChanged({ event in
            if isEnabled, !isRightShowing {
                if !isShowing {
                    if event.startLocation.x < 10 {
                        offset =  min(max(event.location.x - sideWidth, -sideWidth), 0)
                        
                    }
                } else {
                    if event.startLocation.x >= sideWidth {
                        
                        offset = min(max(event.translation.width, -sideWidth), 0)
                    }
                }
            }
            
            if isRightEnabled, !isShowing {
                if !isRightShowing {
                    if event.startLocation.x > width - 10 {
                        rightOffset = min(width, max(width - sideWidth, event.location.x))
                    }
                } else {
                    if event.startLocation.x < width - sideWidth {
                        rightOffset =  min(width, max(width - sideWidth, width - sideWidth + event.translation.width))
                    }
                }
            }
            
        }).onEnded { event in
            
            if isEnabled, !isShowing {
                if offset >= -sideWidth * 0.7 {
                    withAnimation {
                        offset = 0
                        isShowing = true
                    }
                    
                } else {
                    withAnimation {
                        offset = -sideWidth
                    }
                    
                }
            }
            
            if isEnabled, isShowing {
                if event.startLocation.x >= sideWidth, event.translation.width < 10 {
                    withAnimation {
                        isShowing = false
                        offset = -sideWidth
                    }
                }
                
            }
            
            if isRightEnabled, !isRightShowing {
                if rightOffset >= width - sideWidth * 0.3 {
                    withAnimation {
                        rightOffset = width
                        isRightShowing = false
                    }
                } else {
                    withAnimation {
                        rightOffset = width - sideWidth
                        isRightShowing = true
                    }
                }
            }
            
            if isRightEnabled, isRightShowing {
                if event.startLocation.x < width - sideWidth, event.translation.width > 10 {
                    withAnimation {
                        rightOffset = width
                        isRightShowing = false
                    }
                } else {
                    withAnimation {
                        rightOffset = width - sideWidth
                    }
                }
            }
        }
        
        return GeometryReader { geometry in
            if geometry.size.width != width {
                DispatchQueue.main.async {
                    width = geometry.size.width
                    if isRightShowing {
                        rightOffset = geometry.size.width - sideWidth
                    } else {
                        rightOffset = geometry.size.width
                    }
                }
            }
            let opacity = max(
                (offset + sideWidth) / sideWidth * 0.4,
                (width - rightOffset) / sideWidth * 0.4
            )
            return ZStack(alignment: .leading) {
                content
                
                Color.black.ignoresSafeArea().opacity(opacity).onTapGesture {
                    if isShowing {
                        isShowing = false
                    }
                    if isRightShowing {
                        isRightShowing = false
                    }
                }
                
                HStack{
                    Color(UIColor.systemBackground).opacity(0.00001).frame(width: 10)
                    Spacer()
                    Color(UIColor.systemBackground).opacity(0.00001).frame(width: 10)
                }.edgesIgnoringSafeArea(.all)
                
                menuContent()
                    .frame(width: sideWidth)
                    .offset(x: offset)
                
                
                rightMenu()
                .frame(width: sideWidth)
                .offset(x: rightOffset)
            }.gesture(drag).onChange(of: isShowing, perform: { value in
                withAnimation {
                    if value {
                        offset = 0
                    } else {
                        offset = -sideWidth
                    }
                }
              
          }).onChange(of: isRightShowing, perform: { value in
              withAnimation {
                  if value {
                      rightOffset = width - sideWidth
                  } else {
                      rightOffset = width
                  }
              }
          })
        }
    }
}


public extension View {
    func twoSideMenu<MenuContent: View, RightMenu: View>(
        isEnabled: Binding<Bool>,
        isShowing: Binding<Bool>,
        isRightEnabled: Binding<Bool>,
        isRightShowing: Binding<Bool>,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder rightMenu: @escaping () -> RightMenu
    ) -> some View {
        self.modifier(TwoSideMenu(isEnabled: isEnabled, isShowing: isShowing, isRightEnabled: isRightEnabled, isRightShowing: isRightShowing, menuContent: menuContent, rightMenu: rightMenu))
    }
}



extension Binding where Value == Bool {
    /// Creates a binding by mapping an optional value to a `Bool` that is
    /// `true` when the value is non-`nil` and `false` when the value is `nil`.
    ///
    /// When the value of the produced binding is set to `false` the value
    /// of `bindingToOptional`'s `wrappedValue` is set to `nil`.
    ///
    /// Setting the value of the produce binding to `true` does nothing and
    /// will log an error.
    ///
    /// - parameter bindingToOptional: A `Binding` to an optional value, used to calculate the `wrappedValue`.
    public init(mappedTo bindingToOptional: Binding<Bool>) {
        self.init(
            get: { bindingToOptional.wrappedValue == false },
            set: { newValue in
            }
        )
    }
}

extension Binding {
    /// Returns a binding by mapping this binding's value to a `Bool` that is
    /// `true` when the value is non-`nil` and `false` when the value is `nil`.
    ///
    /// When the value of the produced binding is set to `false` this binding's value
    /// is set to `nil`.
    public func mappedToNot() -> Binding<Bool> where Value == Bool {
        return Binding<Bool>(mappedTo: self)
    }
}










internal struct DelayModifier: ViewModifier {
    @StateObject private var state = DelayState()
    
    var action: () -> Void
    var delay: TimeInterval
    
    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
        .buttonStyle(DelayButtonStyle(delay: delay))
        .accessibilityRemoveTraits(.isButton)
        .environmentObject(state)
        .disabled(state.disabled)
    }
}


private struct DelayButtonStyle: ButtonStyle {
    @EnvironmentObject private var state: DelayState
    
    var delay: TimeInterval
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isPressed in
                state.onIsPressed(isPressed, delay: delay)
            }
    }
}


@MainActor
private final class DelayState: ObservableObject {
    @Published private(set) var disabled = false
    
    func onIsPressed(_ isPressed: Bool, delay: TimeInterval) {
        workItem.cancel()
        
        if isPressed {
            workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                
                self.objectWillChange.send()
                self.disabled = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + max(delay, 0), execute: workItem)
        } else {
            disabled = false
        }
    }
    
    private var workItem = DispatchWorkItem(block: {})
}


public extension View {
    /// Sequences a gesture with a long press and attaches the result to the view,
    /// which results in the gesture only receiving events after the long press
    /// succeeds.
    ///
    /// Use this view modifier *instead* of `.gesture` to delay a gesture:
    ///
    ///     ScrollView {
    ///         FooView()
    ///             .delayedGesture(someGesture, delay: 0.2)
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///    - delay: A value that controls the duration of the long press that
    ///      must elapse before the gesture can be recognized by the view.
    ///    - action: An action to perform if a tap gesture is recognized
    ///      before the long press can be recognized by the view.
    func delayedGesture<T: Gesture>(
        _ gesture: T,
        including mask: GestureMask = .all,
        delay: TimeInterval = 0.25,
        onTapGesture action: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(DelayModifier(action: action, delay: delay))
            .gesture(gesture, including: mask)
    }
    
    /// Attaches a long press gesture to the view, which results in gestures with a
    /// lower precedence only receiving events after the long press succeeds.
    ///
    /// Use this view modifier *before* `.gesture` to delay a gesture:
    ///
    ///     ScrollView {
    ///         FooView()
    ///             .delayedInput(delay: 0.2)
    ///             .gesture(someGesture)
    ///     }
    ///
    /// - Parameters:
    ///    - delay: A value that controls the duration of the long press that
    ///      must elapse before lower precedence gestures can be recognized by
    ///      the view.
    ///    - action: An action to perform if a tap gesture is recognized
    ///      before the long press can be recognized by the view.
    func delayedInput(
        delay: TimeInterval = 0.25,
        onTapGesture action: @escaping () -> Void = {}
    ) -> some View {
        modifier(DelayModifier(action: action, delay: delay))
    }
}
