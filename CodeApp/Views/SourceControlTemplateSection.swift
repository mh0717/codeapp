//
//  SourceControlTemplateSection.swift
//  Code
//
//  Created by Ken Chung on 11/1/2023.
//

import SwiftUI

struct SourceControlTemplateSection: View {
    @EnvironmentObject var App: MainApp

    let onClone: (String) async throws -> Void

    var body: some View {
        Section(
            header:
                Text("source_control.community_templates")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            if let templates = App.searchManager.templates {
                ForEach(templates, id: \.html_url) { item in
                    GitHubSearchResultCell(item: item, onClone: onClone)
                }.listRowBackground(Color.init(id: "sideBar.background"))
            } else {
                ProgressView()
            }

            
//            #if PYTHON3IDE
//            Text(NSLocalizedString("source_control.community_templates.description", comment: "").replacingFirstOccurrence(of: "{{python3ide}}", with: ""))
//                .foregroundColor(.gray)
//                .font(.system(size: 12, weight: .light))
//            #else
//            Text(NSLocalizedString("source_control.community_templates.description", comment: "").replacingFirstOccurrence(of: "{{ipyde-template}}", with: ""))
//                .foregroundColor(.gray)
//                .font(.system(size: 12, weight: .light))
//            #endif
        }
        .onAppear {
            if App.searchManager.templates == nil {
                App.searchManager.listTemplates()
            }
        }
    }

}
