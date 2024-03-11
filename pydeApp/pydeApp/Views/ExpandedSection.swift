//
//  ExpandedSection.swift
//  pydeApp
//
//  Created by Huima on 2024/3/11.
//

import SwiftUI



struct ExpandedSection<Header, Content>: View  where Header: View, Content: View{
    let header: Header
    let content: Content
    @State var expanded: Bool = true
    var body: some View {
        if #available(iOS 17.0, *) {
            Section(isExpanded: $expanded) {
                content
            } header: {
                header
            }
        } else {
            Section(
                header: header
            ) {
                content
            }
        }
    }
}
