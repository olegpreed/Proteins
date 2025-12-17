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
        ScrollView {
            VStack {
                ForEach(ligands, id: \.self) { ligand in
                    NavigationLink(value: ligand) {
                        Text(ligand)
                            .font(.custom("IBMPlexMono-Regular", size: 17))
                            .padding()
                            .scrollTransition(transition: { content, phase in
                                content
                                    .blur(radius: phase.isIdentity ? 0 : 10)
                                    .opacity(phase.isIdentity ? 1 : 0)
                            })
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 90)
            .padding(.bottom, 50)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .navigationDestination(for: String.self) { ligand in
            ProteinView(ligandCode: ligand)
                .toolbar(.hidden, for: .tabBar)
        }
    }
}

#Preview {
    NavigationStack {
        LigandsListView(ligands: (0 ..< 30).map { "Ligand \($0)" })
    }
}
