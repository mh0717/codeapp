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
                if event.startLocation.x < 50 {
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
                
                if !isShowing, event.startLocation.x <= 50 {
                    if event.location.x > 150 {
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
                    if event.translation.width < 10 {
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
              
              Color.gray.ignoresSafeArea().opacity((offset + sideWidth) / sideWidth * 0.7).onTapGesture {
                  if isShowing {
                      withAnimation {
                          isShowing = false
                          offset = -sideWidth
                      }
                  }
              }
            
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
