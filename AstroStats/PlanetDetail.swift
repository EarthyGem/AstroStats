import SwiftUI
import SwiftEphemeris

struct PlanetDetailView: View {
    let person: Person
    let planet: CelestialObject
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            // Planet header
            HStack(spacing: 16) {
                GlyphProvider.planetImage(for: planet.keyName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(planet.keyName)
                        .font(.title)
                        .fontWeight(.bold)

                    if let score = person.planetScores?[planet] {
                        Text("Total power: \(String(format: "%.1f", score))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
            )
            .padding(.horizontal)

            // Tab selector
            Picker("View Type", selection: $selectedTab) {
                Text("Scoring Details").tag(0)
                Text("Correspondences").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Content based on selected tab
            if selectedTab == 0 {
                PlanetScoringView(person: person, planet: planet, chartCake: ChartCake(birthDate: person.birthDate, latitude: person.latitude, longitude: person.longitude))
            } else {
                PlanetCorrespondencesView(planet: planet)
            }

            Spacer()
        }
        .navigationTitle("\(planet.keyName) Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import SwiftEphemeris

// Main view broken into sub-components
struct PlanetScoringView: View {
    let person: Person
    let planet: CelestialObject
    let chartCake: ChartCake  // Add this parameter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // House Information
                HouseInfoSection(person: person, planet: planet)

                // Aspect Information - pass the chartCake directly
                AspectInfoSection(person: person, planet: planet, chartCake: chartCake)
            }
            .padding(.vertical)
        }
    }
}

// House information extracted to a separate component
struct HouseInfoSection: View {
    let person: Person
    let planet: CelestialObject

    @State private var chart: Chart?
    @State private var coordinate: Coordinate?
    @State private var houseScore: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("House Position")
                .font(.headline)
                .padding(.bottom, 4)

            if let chart = chart, let coordinate = coordinate {
                let house = chart.houseCusps.cusp(for: coordinate.longitude).number
                let score = chart.getHouseScore(for: coordinate)

                Text("House \(house)")
                    .font(.system(size: 18, weight: .semibold))

                // Show sign of house cusp
                Text("House Score: \(String(format: "%.2f", score))")
                    .font(.subheadline)
                    .padding(.vertical, 4)

                // Show house score
                if let houseScore = houseScore {
                    Text("House Influence: \(String(format: "%.2f", houseScore)) astrodynes")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                Text("House data not available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .onAppear {
            setupData()
        }
    }

    private func setupData() {
        // Initialize data on appear to avoid complex expressions in the View body
        self.chart = Chart(
            date: person.birthDate,
            latitude: person.latitude,
            longitude: person.longitude,
            houseSystem: .placidus
        )

        if let chart = self.chart {
            switch planet {
            case .planet(.sun): self.coordinate = chart.sun
            case .planet(.moon): self.coordinate = chart.moon
            case .planet(.mercury): self.coordinate = chart.mercury
            case .planet(.venus): self.coordinate = chart.venus
            case .planet(.mars): self.coordinate = chart.mars
            case .planet(.jupiter): self.coordinate = chart.jupiter
            case .planet(.saturn): self.coordinate = chart.saturn
            case .planet(.uranus): self.coordinate = chart.uranus
            case .planet(.neptune): self.coordinate = chart.neptune
            case .planet(.pluto): self.coordinate = chart.pluto
            default: break
            }
        }

        // Get house score
        let chartCake = getChartCake()
        if let coordinate = self.coordinate {
            self.houseScore = chartCake?.getHouseScore(for: coordinate)
        }
    }

    private func getChartCake() -> ChartCake? {
        // Connect this to how you access ChartCake in your app
        // For example: return person.chartCake
        return nil
    }
}

// Aspect information extracted to a separate component
// Simplified Aspect information section that uses existing chartCake
struct AspectInfoSection: View {
    let person: Person
    let planet: CelestialObject
    let chartCake: ChartCake  // Pass in the chartCake directly

    @State private var aspects: [CelestialAspect: Double] = [:]
    @State private var debugInfo: String = "Loading aspects..."

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aspects")
                .font(.headline)
                .padding(.bottom, 4)

            if !aspects.isEmpty {
                // Sort aspects by power (descending)
                let sortedAspects = aspects.keys.sorted { a, b in
                    aspects[a]! > aspects[b]!
                }

                // Display each aspect in a styled card
                ForEach(sortedAspects, id: \.self) { aspect in
                    let score = aspects[aspect] ?? 0
                    aspectCard(for: aspect, score: score)
                        .padding(.bottom, 8)
                }

                // Total aspect power
                HStack {
                    Text("Total Aspect Power")
                        .font(.headline)

                    Spacer()

                    Text("\(String(format: "%.2f", aspects.values.reduce(0, +)))")
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(.top, 8)
            } else {
                Text("No significant aspects found")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)

                // This is for debugging purposes only
                if debugInfo != "Loading aspects..." {
                    Text(debugInfo)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .onAppear {
            loadAspects()
        }
    }

    private func loadAspects() {
        // Directly use the provided chartCake to get aspects
        do {
            let aspectsResult = chartCake.natal.filterAndFormatNatalAspects(
                by: planet,
                aspectsScores: chartCake.allCelestialAspectScoresByAspect(),
                includeParallel: true
            )

            if aspectsResult.isEmpty {
                debugInfo = "Filter function returned empty results"
            } else {
                self.aspects = aspectsResult
                debugInfo = "Found \(aspectsResult.count) aspects"
            }
        } catch {
            debugInfo = "Error getting aspects: \(error.localizedDescription)"
        }
    }

    // Create styled aspect card
    private func aspectCard(for aspect: CelestialAspect, score: Double) -> some View {
        let otherBody = aspect.body1.body == planet ? aspect.body2 : aspect.body1

        let otherBodyName = otherBody.body.keyName

        return HStack {
            // Left: Other planet info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Planet glyph - use Text fallback if image not available
                    Text(getPlanetSymbol(otherBody.body.keyName))
                        .font(.system(size: 24))
                        .foregroundColor(getPlanetColor(otherBody.body.keyName))

                    Text(otherBodyName)
                        .font(.headline)
                }

               let sign = otherBody.sign.keyName
                    HStack {
                        // Sign symbol - use Text fallback if image not available
                        Image(getSignSymbol(sign))
                            .font(.system(size: 18))

                        let house = chartCake.natal.houseCusps.house(of: otherBody).number
                        Text("\(sign), House \(house)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

            }

            Spacer()

            // Middle: Aspect symbol
            VStack(spacing: 2) {
                Text(getAspectSymbol(for: aspect.kind))
                    .font(.title)
                    .foregroundColor(getAspectColor(aspect.kind))

                Text(aspect.kind.description.capitalized)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("(\(getAspectEffect(aspect.kind)))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Right: Score and orb
            VStack(alignment: .trailing, spacing: 4) {
                Text("Score: \(String(format: "%.1f", score))")
                    .font(.subheadline)

                Text("Orb: \(String(format: "%.1f°", abs(aspect.orbDelta)))")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("MaxOrb: \(String(format: "%.1f°", abs(aspect.orb)))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // Helper functions for symbols
    private func getPlanetSymbol(_ name: String) -> String {
        switch name.lowercased() {
        case "sun": return "☉"
        case "moon": return "☽"
        case "mercury": return "☿"
        case "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturn": return "♄"
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluto": return "♇"
        default: return "•"
        }
    }

    private func getSignSymbol(_ name: String) -> String {
        switch name.lowercased() {
        case "aries": return "♈"
        case "taurus": return "♉"
        case "gemini": return "♊"
        case "cancer": return "♋"
        case "leo": return "♌"
        case "virgo": return "♍"
        case "libra": return "♎"
        case "scorpio": return "♏"
        case "sagittarius": return "♐"
        case "capricorn": return "♑"
        case "aquarius": return "♒"
        case "pisces": return "♓"
        default: return "•"
        }
    }

    private func getAspectSymbol(for kind: Kind) -> String {
        switch kind {
        case .conjunction: return "☌"
        case .opposition: return "☍"
        case .trine: return "△"
        case .square: return "□"
        case .sextile: return "⚹"
        case .semisextile: return "⚺"
        case .semisquare: return "∠"
        case .sesquisquare: return "⚼"
        case .inconjunction: return "⚻"
        case .parallel: return "∥"
        default: return "?"
        }
    }

    private func getAspectEffect(_ kind: Kind) -> String {
        switch kind {
        case .conjunction: return "Fusion"
        case .opposition: return "Separation"
        case .trine: return "Harmony"
        case .square: return "Obstacle"
        case .sextile: return "Opportunity"
        case .semisquare: return "Irritation"
        case .semisextile: return "Adjustment"
        case .inconjunction: return "Paradox"
        case .sesquisquare: return "Agitation"
        case .parallel: return "Alignment"
        default: return "Aspect"
        }
    }

    private func getAspectColor(_ kind: Kind) -> Color {
        switch kind {
        case .conjunction: return .orange
        case .opposition: return .blue
        case .trine: return .indigo
        case .square: return .red
        case .sextile: return .yellow
        case .semisquare: return .purple
        case .semisextile: return .green
        case .inconjunction: return .pink
        case .sesquisquare: return .white
        case .parallel: return Color(red: 0.75, green: 1.0, blue: 0.0) // Lime green
        default: return .gray
        }
    }

    private func getPlanetColor(_ planet: String) -> Color {
        switch planet.lowercased() {
        case "sun": return .orange
        case "moon": return .green
        case "mercury": return Color(red: 0.5, green: 0.0, blue: 0.8)
        case "venus": return .yellow
        case "mars": return .red
        case "jupiter": return .indigo
        case "saturn": return .blue
        case "uranus": return .green
        case "neptune": return .teal
        case "pluto": return .indigo
        default: return .gray
        }
    }
}
// Further breakdown of aspect list to reduce complexity
struct AspectListView: View {
    let sortedAspects: [(key: CelestialAspect, value: Double)]
    let planet: CelestialObject

    var body: some View {
        ForEach(0..<sortedAspects.count, id: \.self) { index in
            let aspectPair = sortedAspects[index]

            VStack {
                HStack {
                    Text(getOtherPlanetName(aspectPair.key))
                        .font(.system(size: 16))
                        .frame(width: 80, alignment: .leading)

                    Text(aspectPair.key.kind.description.capitalized)
                        .font(.system(size: 16))
                        .frame(width: 100, alignment: .leading)

                    Spacer()

                    Text("\(String(format: "%.2f", aspectPair.value))")
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.vertical, 4)

                if index < sortedAspects.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func getOtherPlanetName(_ aspect: CelestialAspect) -> String {
        if aspect.body1.body == planet {
            return aspect.body2.body.keyName
        } else {
            return aspect.body1.body.keyName
        }
    }
}

struct PlanetCorrespondencesView: View {
    let planet: CelestialObject

    // Comprehensive correspondences for all planets
    private var correspondences: [String: String] {
        switch planet.keyName.lowercased() {
        case "sun":
            return [
                "Urge": "The urge for significance, for power",
                "Deity": "Apollo, Helios, Ra, Mithras",
                "Body Parts": "Heart, spine, vitality, arterial blood, circulation",
                "Diseases": "Cardiovascular issues, fever, inflammation, hypertension",
                "Gems": "Diamond, ruby, amber, topaz, sunstone",
                "Plants": "Sunflower, marigold, saffron, cinnamon, bay laurel",
                "Metal": "Gold",
                "Colors": "Orange, gold",
                "Musical Note": "D",
                "Day": "Sunday"
            ]
        case "moon":
            return [
                "Urge": "The urge for change, for domestic security, for emotional expression",
                "Deity": "Selene, Diana, Artemis, Isis",
                "Body Parts": "Breasts, stomach, lymph, digestive fluids, cerebrospinal fluids",
                "Diseases": "Digestive disorders, fluid retention, hormonal imbalances",
                "Gems": "Pearl, moonstone, crystal, opal, selenite",
                "Plants": "Cucumber, melon, cabbage, pumpkin, lily, poppy",
                "Element": "Water",
                "Metal": "Silver",
                "Colors": "Silver, white, pale green, cream",
                "Musical Note": "E",
                "Day": "Monday"
            ]
        case "mercury":
            return [
                "Urge": "The urge for expression, for mental activity, for communication",
                "Deity": "Hermes, Thoth, Mercury",
                "Body Parts": "Brain, nervous system, hands, lungs, speech organs",
                "Diseases": "Nervous disorders, respiratory issues, coordination problems",
                "Gems": "Agate, opal, variegated stones, quicksilver",
                "Plants": "Lavender, marjoram, parsley, valerian, dill",
                "Element": "Air",
                "Metal": "Mercury, quicksilver",
                "Colors": "Purple, violet, mixed colors",
                "Musical Note": "E",
                "Day": "Wednesday"
            ]
        case "venus":
            return [
                "Urge": "The urge for companionship, for love, for beauty, for art",
                "Deity": "Aphrodite, Venus, Ishtar, Freya",
                "Body Parts": "Throat, kidneys, veins, thymus, sense of touch",
                "Diseases": "Throat problems, kidney issues, diabetes, thyroid disorders",
                "Gems": "Emerald, jade, coral, rose quartz, turquoise",
                "Plants": "Rose, apple, strawberry, lily, mint",
                "Element": "Earth/Air",
                "Metal": "Copper",
                "Colors": "Green, pink, pastel blue",
                "Musical Note": "A",
                "Day": "Friday"
            ]
        case "mars":
            return [
                "Urge": "The urge for aggression, for action, for conquest, for vigor",
                "Deity": "Ares, Mars, Tyr",
                "Body Parts": "Muscles, head, adrenal glands, genitals, red blood cells",
                "Diseases": "Inflammation, burns, cuts, fevers, headaches",
                "Gems": "Ruby, bloodstone, red jasper, garnet",
                "Plants": "Red pepper, nettle, ginger, basil, garlic",
                "Element": "Fire",
                "Metal": "Iron, steel",
                "Colors": "Red, scarlet, crimson",
                "Musical Note": "C",
                "Day": "Tuesday"
            ]
        case "jupiter":
            return [
                "Urge": "The urge for expansion, for growth, for wisdom, for abundance",
                "Deity": "Zeus, Jupiter, Thor",
                "Body Parts": "Liver, hips, thighs, fat cells, arterial system",
                "Diseases": "Metabolic disorders, liver issues, blood sugar problems",
                "Gems": "Sapphire, lapis lazuli, turquoise, amethyst",
                "Plants": "Sage, nutmeg, dandelion, oak, maple",
                "Element": "Fire/Air",
                "Metal": "Tin",
                "Colors": "Royal blue, purple, indigo",
                "Musical Note": "F#",
                "Day": "Thursday"
            ]
        case "saturn":
            return [
                "Urge": "The urge for security, for stability, for structure, for discipline",
                "Deity": "Chronos, Saturn, Shani",
                "Body Parts": "Bones, teeth, skin, knees, skeletal system",
                "Diseases": "Arthritis, bone issues, chronic conditions, depression",
                "Gems": "Onyx, jet, obsidian, black tourmaline",
                "Plants": "Cypress, ivy, nightshade, hemlock, yew",
                "Element": "Earth",
                "Metal": "Lead",
                "Colors": "Black, dark blue, gray, brown",
                "Musical Note": "G",
                "Day": "Saturday"
            ]
        case "uranus":
            return [
                "Urge": "The urge for freedom, for change, for originality, for revolution",
                "Deity": "Uranus, Prometheus, Varuna",
                "Body Parts": "Nervous system, ankles, bioelectric currents",
                "Diseases": "Spasms, neurological disorders, electrical imbalances",
                "Gems": "Aquamarine, amber, uranium glass, fluorite",
                "Plants": "Clover, birch, aspen, unusual plants",
                "Element": "Air/Fire",
                "Metal": "Uranium, aluminum",
                "Colors": "Electric blue, neon colors, ultraviolet",
                "Musical Note": "D#",
                "Day": "None (modern planet)"
            ]
        case "neptune":
            return [
                "Urge": "The urge for unity, for transcendence, for idealism, for dissolution",
                "Deity": "Poseidon, Neptune, Vishnu",
                "Body Parts": "Pineal gland, feet, lymphatic system, psychic centers",
                "Diseases": "Addictions, mysterious ailments, foot problems, immune disorders",
                "Gems": "Moonstone, aquamarine, pearl, coral",
                "Plants": "Lotus, seaweed, water lily, marijuana, mushrooms",
                "Element": "Water",
                "Metal": "Neptune (hypothetical)",
                "Colors": "Sea green, misty blue, lavender",
                "Musical Note": "A#",
                "Day": "None (modern planet)"
            ]
        case "pluto":
            return [
                "Urge": "The urge for power, for transformation, for rebirth, for elimination",
                "Deity": "Hades, Pluto, Shiva, Kali",
                "Body Parts": "Reproductive organs, cellular regeneration, waste elimination",
                "Diseases": "Degenerative disorders, obsessions, power-related illnesses",
                "Gems": "Obsidian, black tourmaline, plutonium",
                "Plants": "Scorpion grass, blackthorn, deadly nightshade",
                "Element": "Water/Fire",
                "Metal": "Plutonium",
                "Colors": "Black, dark red, deep purple",
                "Musical Note": "C#",
                "Day": "None (modern planet)"
            ]
        default:
            return ["Information": "No correspondences available"]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with planet symbol and element
                HStack(spacing: 16) {
                    if let element = correspondences["Element"] {
                        ElementSymbolView(element: element, planetColor: planetColor(planet.keyName))
                    }

                    if let urge = correspondences["Urge"] {
                        Text(urge)
                            .font(.subheadline)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 3)
                )
                .padding(.horizontal)

                // All other correspondences
                LazyVGrid(
                    columns: [GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(correspondences.sorted(by: { $0.key < $1.key }), id: \.key) { category, info in
                        if category != "Urge" { // Skip urge as it's already in the header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category)
                                    .font(.headline)
                                    .foregroundColor(planetColor(planet.keyName))

                                Text(info)
                                    .font(.subheadline)
                                    .padding(.leading, 8)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // Element symbol view with appropriate styling
    struct ElementSymbolView: View {
        let element: String
        let planetColor: Color

        var body: some View {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(planetColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(elementSymbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(planetColor)
                }

                Text(element)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }

        private var elementSymbol: String {
            if element.contains("Fire") {
                return "△"
            } else if element.contains("Earth") {
                return "▽"
            } else if element.contains("Air") {
                return "△"
            } else if element.contains("Water") {
                return "▽"
            } else {
                return "○"
            }
        }
    }

    private func planetColor(_ planet: String) -> Color {
        switch planet.lowercased() {
        case "sun": return .orange
        case "moon": return .green
        case "mercury": return Color(red: 0.5, green: 0.0, blue: 0.8)
        case "venus": return .yellow
        case "mars": return .red
        case "jupiter": return .indigo
        case "saturn": return .blue
        case "uranus": return .green
        case "neptune": return .teal
        case "pluto": return .indigo
        default: return .gray
        }
    }
}
