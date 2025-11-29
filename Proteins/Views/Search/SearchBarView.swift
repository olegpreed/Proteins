//
//  SearchBarView.swift
//  Proteins
//
//  Created by Oleg on 8/15/25.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        TextField("Search", text: $searchText)
            .font(.custom("IBMPlexMono-Regular", size: 17))
    }
}

#Preview {
    SearchBarView(
        searchText: .constant("")
    )
}
