//
//  SearchView.swift
//  Proteins
//
//  Created by Oleg on 8/13/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    private var ligands: [String] = []
    @State private var filteredLigands: [String] = []
    @SceneStorage("selectedTab") private var selectedTab: Int = 0

    init() {
        if let path = Bundle.main.path(forResource: "ligands", ofType: "txt") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                ligands = content
                    .components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
                filteredLigands = ligands
            } catch {
                print("Error reading ligands.txt: \(error)")
            }
        }
        _filteredLigands = State(initialValue: ligands)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LigandsListView(ligands: filteredLigands)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    filteredLigands = ligands
                } else {
                    filteredLigands = ligands.filter { $0.localizedCaseInsensitiveContains(newValue) }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .bottom)
        }
        .searchable(text: $searchText, prompt: "Search Proteins")
    }
}

#Preview {
    SearchView()
}

struct IsSearchable: ViewModifier {
    let selectedTab: Int
    @Binding var filter: String
    func body(content: Content) -> some View {
        if selectedTab == 2 {
            content
                .searchable(text: $filter, prompt: "Search Proteins")
        } else {
            content
        }
    }
}

extension View {
    func isSearchable(selectedTab: Int, filter: Binding<String>) -> some View {
        modifier(IsSearchable(selectedTab: selectedTab, filter: filter))
    }
}
