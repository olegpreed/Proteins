//
//  SettingsBarView.swift
//  Proteins
//
//  Created by Oleg on 11/29/25.
//

import SwiftUI

struct SettingsBarView: View {
    var body: some View {
        HStack {
            Spacer()
            NavigationLink {
                ContentView()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title)
                    .foregroundStyle(Color(.systemGray4))
                    .padding()
            }
            .glassEffect(.clear, in: Circle())
            Spacer()
        }
    }
}

#Preview {
    SettingsBarView()
}
