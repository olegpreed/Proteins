//
//  MainView.swift
//  Proteins
//
//  Created by Oleg on 12/3/25.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab: Int = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Settings", systemImage: "gearshape", value: 0) {
                SettingsView()
            }
            Tab(value: 1, role: .search) {
                SearchView()
            }
        }
    }
}

#Preview {
    MainView()
}
