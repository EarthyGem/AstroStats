//
//  HouseDetailsView.swift
//  AstroStats
//
//  Created by Errick Williams on 5/12/25.
//


import SwiftUI
import SwiftEphemeris

import SwiftUI
import SwiftEphemeris

struct HouseDetailsView: View {
    let person: Person
    let house: Int

    var body: some View {
        let chartCake = ChartCake(
            birthDate: person.birthDate,
            latitude: person.latitude,
            longitude: person.longitude
        )

        let chart = chartCake.natal
        let housePower = person.houseScores?[house] ?? 0.0
        let planetsInHouse = chart.rickysBodies.filter {
            chart.houseCusps.house(of: $0).number == house
        }



        let rulers: [CelestialObject] = chart.houseCusps.getRulersForCusp(cuspNumber: house)
        let cuspPower = rulers
        let cusp = chart.houseCusps.houses[house - 1]
        let interceptedSigns = chart.houseCusps.possibleInterceptedSignsForHouse(cusp: cusp)
        let interceptedRulers = interceptedSigns.flatMap { chart.houseCusps.rulersCO(of: $0) }
        let cuspSign = cusp.sign
        let cuspRulerPower = chart.houseCusps.rulersCO(of: cusp).compactMap { person.planetScores?[$0] }.reduce(0, +) * 0.5
        let interceptedPower = interceptedRulers.compactMap { person.planetScores?[$0] }.reduce(0, +) * 0.25

        let adjustedCuspPower = cuspRulerPower + interceptedPower

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // House Header
                HStack(spacing: 8) {
                    Text("\(ordinal(house)) House")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Power Summary
                HStack {
                    Text("Total Power:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", housePower))
                        .font(.headline)
                }

                // Cusp Sign and Rulers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cusp Sign: \(cuspSign.keyName.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(rulers, id: \.self) { co in
                        HStack {
                            GlyphProvider.planetImage(for: co.keyName)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(co.keyName.capitalized)
                            Spacer()
                            Text(String(format: "%.2f", person.planetScores?[co] ?? 0.0))
                        }
                        .font(.subheadline)
                    }
                }

                // Planets in the House
                if !planetsInHouse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Planets in this House:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(planetsInHouse, id: \.self) { coordinate in
                            HStack {
                                GlyphProvider.planetImage(for: coordinate.body.keyName)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(coordinate.body.keyName.capitalized)
                                Spacer()
                                Text(String(format: "%.2f", person.planetScores?[coordinate.body] ?? 0.0))
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(ordinal(house)) House")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ordinal(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
