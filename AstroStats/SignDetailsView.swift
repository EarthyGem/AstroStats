//
//  SignDetailsView.swift
//  AstroStats
//
//  Created by Errick Williams on 5/12/25.
//


import SwiftUI
import SwiftEphemeris

import SwiftUI
import SwiftEphemeris

struct SignDetailsView: View {
    let person: Person
    let sign: Zodiac

    var body: some View {
        let chartCake = ChartCake(
            birthDate: person.birthDate,
            latitude: person.latitude,
            longitude: person.longitude
        )
        let chart = chartCake.natal

        let signPower = person.signScores?[sign] ?? 0.0
        let planetsInSign = chart.rickysBodies.filter { $0.sign == sign }
        let rulerPlanets = sign.rulingPlanets()
        let weightedRulerPower = rulerPlanets
            .compactMap { person.planetScores?[$0] }
            .map { $0 * 0.5 }
            .reduce(0, +)


        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Sign Header
                HStack(spacing: 8) {
                    GlyphProvider.signImage(for: sign.keyName.uppercased())
                        .resizable()
                        .frame(width: 28, height: 28)
                    Text(sign.keyName.capitalized)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Total Power
                HStack {
                    Text("Total Power:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", signPower))
                        .font(.headline)
                }

                // Rulership
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ruler(s):")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(rulerPlanets, id: \.self) { planet in
                        HStack {
                            GlyphProvider.planetImage(for: planet.keyName)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(planet.keyName.capitalized)
                            Spacer()
                            Text(String(format: "%.2f", person.planetScores?[planet] ?? 0.0))
                        }
                        .font(.subheadline)
                    }

                    HStack {
                        Text("Unoccupied Sign Ruler Contribution:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", weightedRulerPower))
                            .font(.caption)
                    }
                }

                // Planets in Sign
                if !planetsInSign.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Planets in \(sign.keyName.capitalized):")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(planetsInSign, id: \.self) { planet in
                            HStack {
                                GlyphProvider.planetImage(for: planet.body.keyName)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(planet.body.keyName.capitalized)
                                Spacer()
                                Text(String(format: "%.2f", person.planetScores?[planet.body] ?? 0.0))
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(sign.keyName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
