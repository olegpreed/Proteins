//
//  LigandsListView.swift
//  Proteins
//
//  Created by Oleg on 8/15/25.
//

import SwiftUI

struct LigandsListView: View {
    var ligands: [String]
    
    var body: some View {
        ScrollView{
            VStack() {
                ForEach(ligands, id: \.self) { ligand in
                    NavigationLink(value: ligand) {
                        Text(ligand)
                            .font(.custom("IBMPlexMono-Regular", size: 17))
                            .padding()
                            .scrollTransition(transition: { content, phase in
                                content
//                                    .scaleEffect (phase.isIdentity ? 1 : 0.1)
                                    .opacity(phase.isIdentity ? 1 : 0)
                            })
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
//        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .navigationDestination(for: String.self) { ligand in
            ProteinView(ligandCode: ligand)
                .toolbar(.hidden, for: .tabBar)
        }
    }
}


#Preview {
    NavigationStack {
        LigandsListView(ligands: (0..<10).map { "Ligand \($0)" })
    }
}
