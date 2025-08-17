//
//  SearchView.swift
//  Proteins
//
//  Created by Oleg on 8/13/25.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var signInModel: SignInModel
    private var ligands: [String] = []
    @State private var filteredLigands: [String] = []
    @State private var searchText: String = ""
    
    init(signInModel: SignInModel) {
        self.signInModel = signInModel
        if let path = Bundle.main.path(forResource: "ligands", ofType: "txt") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                self.ligands = content
                    .components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
                self.filteredLigands = ligands
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
                SearchBarView(searchText: $searchText)
                .padding(.leading)
            }
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty {
                    filteredLigands = ligands
                } else {
                    filteredLigands = ligands.filter { $0.localizedCaseInsensitiveContains(newValue) }
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

#Preview {
    SearchView(
        signInModel: SignInModel()
    )
}
