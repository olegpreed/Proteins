//
//  ProteinView.swift
//  Proteins
//
//  Created by Oleg on 8/16/25.
//

import SwiftUI

struct ProteinView: View {
    var ligand: String
    @State private var result: String = "Loading..."
    
    init(ligand: String) {
        self.ligand = ligand
        print(ligand)
        return
    }
    
    var body: some View {
        VStack {
            Text(ligand)
            Text(result)
        }
        .onAppear {
            fetchresult()
        }
    }
    
    private func fetchresult() {
        guard let url = URL(string: "https://files.rcsb.org/ligands/view/\(ligand)_ideal.sdf") else {
            result = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    result = "Error: \(error.localizedDescription)"
                }
                return
            }
            if let data = data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    result = text.prefix(500) + "..." // show preview
                    print(text) // debug print
                }
            } else {
                DispatchQueue.main.async {
                    result = "No data"
                }
            }
        }.resume()
    }
        

}

#Preview {
    ProteinView(ligand: "13M")
}
