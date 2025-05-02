//
//  ChartListView.swift
//  AstroStats
//
//  Created by Errick Williams on 5/2/25.
//


import SwiftUI
import CoreData

struct ChartListView: View {
    @FetchRequest(
        entity: ChartEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ChartEntity.birthDate, ascending: true)]
    ) var charts: FetchedResults<ChartEntity>

    var body: some View {
        NavigationView {
            List(charts) { chart in
                VStack(alignment: .leading) {
                    Text(chart.name ?? "Unnamed")
                        .font(.headline)
                    Text(chart.birthPlace ?? "")
                        .font(.subheadline)
                }
            }
            .navigationTitle("Saved Charts")
        }
    }
}




