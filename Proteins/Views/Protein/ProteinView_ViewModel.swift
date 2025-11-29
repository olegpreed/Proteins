//
//  ProteinView_ViewModel.swift
//  Proteins
//
//  Created by Artem Forkunov on 29/11/25.
//

import Foundation

extension ProteinView {
    enum LigandLoadError: Error {
        case invalidCode, invalidResponse, invalidData, unknownError
    }
    
    @Observable
    class ViewModel {
        let ligandCode: String
        
        private(set) var structure: CIFStructure?
        private(set) var loadingError: LigandLoadError?
        
        init(ligandCode: String) {
            self.ligandCode = ligandCode
        }
        
        func loadLigand() async {
            do {
                let cifData = try await fetchCIFData(for: ligandCode)
                print(cifData)
                let cif = try CIFParser.parse(from: cifData)
                structure = cif.dataBlocks.first.map { $0.structure() }
                
            } catch let error as LigandLoadError {
                loadingError = error
            } catch {
                print(error)
                loadingError = .unknownError
            }
        }
        
        private func fetchCIFData(for ligandCode: String) async throws -> String {
            guard let url = URL(string: "https://files.rcsb.org/ligands/view/\(ligandCode).cif") else {
                throw LigandLoadError.invalidCode
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw LigandLoadError.invalidResponse
            }
            guard let text = String(data: data, encoding: .utf8) else {
                throw LigandLoadError.invalidData
            }
            return text
        }
    }
}
