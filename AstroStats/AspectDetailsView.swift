import SwiftUI
import SwiftEphemeris

import SwiftUI
import SwiftEphemeris

struct AspectDetailsView: View {
    let person: Person
    let aspectKind: Kind

    var body: some View {
        let chart = ChartCake(
            birthDate: person.birthDate,
            latitude: person.latitude,
            longitude: person.longitude
        )

        let aspects = chart.natal.filterAndFormatNatalAspects(by: aspectKind)

        return ScrollView {
            VStack(spacing: 16) {
                Text("\(aspectKind.symbol) \(aspectKind.description.capitalized) Aspects")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                ForEach(Array(aspects.keys.sorted {
                    aspects[$0, default: 0] > aspects[$1, default: 0]
                }), id: \.self) { aspect in
                    AspectCardView(
                        aspect: aspect,
                        description: "\(aspect.body1.body.keyName) \(aspect.kind.symbol) \(aspect.body2.body.keyName)",
                        score: aspects[aspect] ?? 0,
                        chartCake: chart // ✅ <- THIS LINE was missing
                    )
                }
            }
            .padding()
        }
        .navigationTitle(aspectKind.description.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
import SwiftUI
import SwiftEphemeris

struct AspectCardView: View {
    let aspect: CelestialAspect
    let description: String
    let score: Double
    let chartCake: ChartCake  

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                planetBlock(for: aspect.body1)
                Spacer()
                VStack(alignment: .center, spacing: 2) {
                    Text(aspect.kind.symbol)
                        .font(.title2)
                        .foregroundColor(aspect.kind.aspectColor)
                    Text(aspect.kind.keyword)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                planetBlock(for: aspect.body2)
            }

            Divider()

            HStack {
                scoreBlock(label: "Score", value: String(format: "%.1f", score))
                Spacer()
                scoreBlock(label: "Orb", value: String(format: "%.1f°", aspect.orbDelta))
                Spacer()
                scoreBlock(label: "MaxOrb", value: String(format: "%.1f°", aspect.orb))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func planetBlock(for coordinate: Coordinate) -> some View {
        let sign = coordinate.formatted
        let houseNumber = chartCake.houseCusps.house(of: coordinate)
        let houseOrdinal = ordinal(houseNumber.number)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                GlyphProvider.planetImage(for: coordinate.body.keyName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(coordinate.body.planet?.planetColor)
                Text(coordinate.body.keyName)
                    .font(.headline)
                    .foregroundColor(coordinate.body.planet?.planetColor)
            }

            Text("\(sign) \(houseOrdinal) House")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    private func ordinal(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)th"
    }


    private func scoreBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }




}
