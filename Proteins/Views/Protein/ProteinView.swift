//
//  ProteinView.swift
//  Proteins
//
//  Created by Oleg on 8/16/25.
//

import SwiftUI

struct ProteinView: View {
    @State private var viewModel: ViewModel
    
    init(ligandCode: String) {
        let viewModel = ViewModel(ligandCode: ligandCode)
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if let error = viewModel.loadingError {
                Text("Loading Error: \(error.localizedDescription)")
            } else if let structure = viewModel.structure {
                MoleculeViewerScreen(structure: structure)
            } else {
                Text("Loading...")
            }
        }
        .navigationTitle(viewModel.ligandCode)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLigand()
        }
    }
}

#Preview {
    ProteinView(ligandCode: "13M")
}
