import SwiftUI

import SwiftUI

struct PlanetScoresView: View {
    let person: Person
    @State private var sortByStrength = true
    @State private var showGodFunction = false

    private let conventionalOrder = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Planet Power Distribution")
                    .font(.headline)
                    .padding(.top)

                Picker("Sort Order", selection: $sortByStrength) {
                    Text("By Strength").tag(true)
                    Text("Conventional").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if let planetScores = person.planetScores {
                    let totalScore = planetScores.values.reduce(0, +)

                    let sortedPlanets: [(CelestialObject, Double)] = {
                        if sortByStrength {
                            return planetScores.sorted { $0.value > $1.value }
                        } else {
                            return conventionalOrder.compactMap { key in
                                planetScores.first { $0.key.keyName == key }
                            }
                        }
                    }()

                    ForEach(sortedPlanets, id: \.0) { planet, score in
                        HStack {
                            // Wrap in NavigationLink but keep original dimensions
                            NavigationLink(destination: PlanetDetailView(person: person, planet: planet)) {
                                HStack(spacing: 4) {
                                    GlyphProvider.planetImage(for: planet.keyName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)

                                    Text(planet.keyName)
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 80, alignment: .leading)
                                }
                                .frame(width: 120, alignment: .leading)
                                // No extra padding or background to maintain original size
                            }
                            .buttonStyle(PlainButtonStyle())

                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 22)
                                    .cornerRadius(6)

                                Rectangle()
                                    .fill(planetColor(planet.keyName))
                                    .frame(width: calculateBarWidth(score), height: 22)
                                    .cornerRadius(6)

                                Text(String(format: "%.1f%%", (score / totalScore) * 100))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            }

                            Text(String(format: "%.1f", score))
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)

                    Text("Strongest Planet: \(person.strongestPlanet ?? "Unknown")")
                        .font(.headline)
                        .padding(.bottom)

                    Picker("Meaning Type", selection: $showGodFunction) {
                        Text("Urges").tag(false)
                        Text("Deities").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    PlanetMeaningSummaryView(showGodFunction: showGodFunction)
                        .padding(.bottom)
                } else {
                    Text("Planet score data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }

    // Correct version using strength-relative width
    private func calculateBarWidth(_ score: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 200

        if let maxScore = person.planetScores?.values.max() {
            let ratio = score / maxScore
            return max(20, ratio * maxBarWidth)
        }

        return 40
    }

    // Color palette for planets
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
        case "n.node", "northnode", "mean node": return Color(red: 0.8, green: 0.4, blue: 0.0)
        case "s.node", "southnode", "mean south node": return Color(red: 0.7, green: 0.7, blue: 0.7)
        case "ac", "asc": return .white
        case "mc": return .white
        default: return .gray
        }
    }
}

    // 🟢 Use your updated color palette
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


struct PlanetMeaningSummaryView: View {
    let showGodFunction: Bool
    let planetOrder: [Planet] = [
        .sun, .moon, .mercury, .venus, .mars,
        .jupiter, .saturn, .uranus, .neptune, .pluto
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(showGodFunction ? "Planetary Deities" : "Planetary Urges")
                .font(.headline)
                .padding(.vertical, 8)

            ForEach(planetOrder, id: \.keyName) { planet in
                HStack(alignment: .top) {
                    Text("\(planet.symbol) \(planet.keyName)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(width: 110, alignment: .leading)

                    Text(showGodFunction ? planet.godName : planet.urge)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


import SwiftUI


import SwiftUI

import SwiftUI

struct SignScoresView: View {
    let person: Person
    @State private var sortByStrength = false
    @State private var showEvolutionaryAim = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Zodiac Sign Distribution")
                    .font(.headline)
                    .padding(.top)

                Picker("Sort Order", selection: $sortByStrength) {
                    Text("Zodiac Order").tag(false)
                    Text("By Strength").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if let signScores = person.signScores {
                    let totalScore = signScores.values.reduce(0, +)

                    let signs: [(Zodiac, Double)] = {
                        if sortByStrength {
                            return signScores.sorted { $0.value > $1.value }
                        } else {
                            return Zodiac.allCases.compactMap { sign in
                                if let score = signScores[sign] {
                                    return (sign, score)
                                }
                                return nil
                            }
                        }
                    }()

                    ForEach(signs, id: \.0) { sign, score in
                        HStack {
                            HStack(spacing: 4) {
                                GlyphProvider.signImage(for: sign.keyName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)

                                Text(sign.keyName)
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 80, alignment: .leading)
                            }
                            .frame(width: 120, alignment: .leading)

                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 22)
                                    .cornerRadius(6)

                                Rectangle()
                                    .fill(signColor(sign.keyName))
                                    .frame(width: calculateBarWidth(score), height: 22)
                                    .cornerRadius(6)

                                Text(String(format: "%.1f%%", (score / totalScore) * 100))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(signTextColor(sign.keyName))
                                    .padding(.horizontal, 8)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            }

                            Text(String(format: "%.1f", score))
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("Zodiac sign data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)
                Text("Strongest Planet Sign: \(person.strongestPlanetSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom, 4)

                Text("Sun Sign: \(person.sunSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom, 4)

                Text("Moon Sign: \(person.moonSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom, 4)

                Text("Ascendant: \(person.ascendantSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom)

                Picker("Meaning Type", selection: $showEvolutionaryAim) {
                    Text("Attitudes").tag(false)
                    Text("Evolutionary Aims").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                SignMeaningSummaryView(showEvolutionaryAim: showEvolutionaryAim)
                    .padding(.bottom)
            }
            .padding()
        }
    }

    private func signTextColor(_ sign: String) -> Color {
        switch sign {
        case "Libra":
            return Color(red: 0.1, green: 0.1, blue: 0.4) // Dark blue for better contrast
        default:
            return .white
        }
    }

    private func calculateBarWidth(_ score: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 200

        if let maxScore = person.signScores?.values.max() {
            let ratio = score / maxScore
            return max(20, ratio * maxBarWidth)
        }

        return 40
    }

    private func signColor(_ sign: String) -> Color {
        switch sign {
        case "Aries":       return Color(red: 1.0, green: 0.5, blue: 0.5) // Light Red (Mars - masculine)
        case "Taurus":      return Color(red: 0.8, green: 0.8, blue: 0.0) // Deep Yellow (Venus - feminine)
        case "Gemini":      return Color(red: 0.7, green: 0.5, blue: 1.0) // Light Violet (Mercury - masculine)
        case "Cancer":      return Color(red: 0.0, green: 0.3, blue: 0.0) // Deep Green (Moon - feminine)
        case "Leo":         return Color(red: 1.0, green: 0.7, blue: 0.2) // Bright Orange (Sun - masculine)
        case "Virgo":       return Color(red: 0.4, green: 0.2, blue: 0.6) // Deep Violet (Mercury - feminine)
        case "Libra":       return Color(red: 1.0, green: 1.0, blue: 0.6) // Bright Yellow (Venus - masculine)
        case "Scorpio":     return Color(red: 0.6, green: 0.0, blue: 0.0) // Deep Red (Mars - feminine)
        case "Sagittarius": return Color(red: 0.5, green: 0.3, blue: 0.9) // Light Indigo (Jupiter - masculine)
        case "Capricorn":   return Color(red: 0.0, green: 0.0, blue: 0.5) // Deep Blue (Saturn - feminine)
        case "Aquarius":    return Color(red: 0.3, green: 0.3, blue: 1.0) // Light Blue (Saturn - masculine)
        case "Pisces":      return Color(red: 0.2, green: 0.0, blue: 0.5) // Deep Indigo (Jupiter - feminine)
        default:            return Color.gray
        }
    }
}


struct SignMeaningSummaryView: View {
    let showEvolutionaryAim: Bool
    let zodiacOrder: [Zodiac] = Zodiac.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(showEvolutionaryAim ? "Evolutionary Aims" : "Sign Attitudes")
                .font(.headline)
                .padding(.vertical, 8)

            ForEach(zodiacOrder, id: \.self) { sign in
                HStack(alignment: .top) {
                    Text(sign.keyName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(width: 100, alignment: .leading)

                    Text(showEvolutionaryAim ? sign.evolutionaryAim : sign.attitude)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


import SwiftUI

struct HouseScoresView: View {
    let person: Person
    @State private var sortByStrength = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Astrological Houses Distribution")
                    .font(.headline)
                    .padding(.top)

                Picker("Sort Order", selection: $sortByStrength) {
                    Text("House Order").tag(false)
                    Text("By Strength").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if let houseScores = person.houseScores {
                    let totalScore = houseScores.values.reduce(0, +)

                    let sortedHouses: [(Int, Double)] = {
                        if sortByStrength {
                            return houseScores.sorted { $0.value > $1.value }
                        } else {
                            return (1...12).compactMap { num in
                                houseScores[num].map { (num, $0) }
                            }
                        }
                    }()

                    ForEach(sortedHouses, id: \.0) { houseNumber, score in
                        HStack {
                            Text("House \(houseNumber)")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 120, alignment: .leading)

                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 22)
                                    .cornerRadius(6)

                                Rectangle()
                                    .fill(houseColor(houseNumber))
                                    .frame(width: calculateBarWidth(score), height: 22)
                                    .cornerRadius(6)

                                Text(String(format: "%.1f%%", (score / totalScore) * 100))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            }

                            Text(String(format: "%.1f", score))
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("House data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)

                HouseInformationView()
                    .padding(.bottom)
            }
            .padding()
        }
    }

    private func calculateBarWidth(_ score: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 200

        if let maxScore = person.houseScores?.values.max() {
            let ratio = score / maxScore
            return max(20, ratio * maxBarWidth)
        }

        return 40
    }

    private func houseColor(_ house: Int) -> Color {
        switch house {
        case 1, 5, 9: return .red.opacity(0.8)
        case 2, 6, 10: return .green.opacity(0.8)
        case 3, 7, 11: return .blue.opacity(0.8)
        case 4, 8, 12: return .purple.opacity(0.8)
        default: return .gray
        }
    }
}


struct HouseInformationView: View {
    let houseKeywords = [
        1: "Self, appearance, identity",
        2: "Values, possessions, resources",
        3: "Communication, siblings, local travel",
        4: "Home, family, roots, security",
        5: "Creativity, romance, children",
        6: "Health, work, service",
        7: "Partnerships, marriage, contracts",
        8: "Transformation, shared resources",
        9: "Higher learning, travel, philosophy",
        10: "Career, public image, authority",
        11: "Friends, groups, aspirations",
        12: "Spirituality, unconscious, isolation"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("House Meanings")
                .font(.headline)
                .padding(.vertical, 8)
            
            ForEach(1...12, id: \.self) { house in
                if let keywords = houseKeywords[house] {
                    HStack(alignment: .top) {
                        Text("\(house).")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 25, alignment: .leading)
                        
                        Text(keywords)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct AstrologyChartView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePerson = PersonStore().people[0]
        AstrologyChartView(person: samplePerson)
    }
}
import SwiftUI
import SwiftEphemeris

enum GlyphProvider {
    static func planetImage(for planet: String) -> Image {
        let name = planet.lowercased()
        return Image(uiImage: UIImage(named: name) ?? UIImage(systemName: "questionmark.circle")!)
    }

    static func signImage(for signKey: String) -> Image {
        let name = signKey.capitalized
        return Image(uiImage: UIImage(named: name) ?? UIImage(systemName: "questionmark.circle")!)
    }
}



import SwiftUI

import SwiftUI
import SwiftEphemeris

struct AspectStrengthView: View {
    let person: Person
    @State private var showKeyword = true

    private let aspectSymbolMapping: [Kind: String] = [
        .conjunction: "☌", .sextile: "⚹", .square: "□", .trine: "△", .opposition: "☍",
        .semisextile: "⚺", .semisquare: "∠", .sesquisquare: "⚼", .inconjunction: "⚻", .parallel: "∥"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Aspect Strength by Type")
                    .font(.headline)
                    .padding(.top)

                if let scores = person.aspectScores, !scores.isEmpty {
                    let totalScore = scores.map { $0.1 }.reduce(0, +)

                    ForEach(Array(scores.enumerated()), id: \.0) { index, pair in
                        let aspect = pair.0
                        let score = pair.1
                        let percent = (score / totalScore) * 100
                        let color = aspectColor(aspect)

                        HStack {
                            // Aspect glyph
                            Text(aspectSymbolMapping[aspect] ?? aspect.symbol)
                                .font(.system(size: 24))
                                .foregroundColor(color)
                                .padding(.trailing, 2)

                            // Aspect name
                            Text(aspect.description.capitalized)
                                .font(.system(size: 16, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .layoutPriority(1)
                                .frame(width: 100, alignment: .leading)

                            // Bar with percentage
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 22)
                                    .cornerRadius(6)

                                Rectangle()
                                    .fill(color)
                                    .frame(width: calculateBarWidth(score, scores), height: 22)
                                    .cornerRadius(6)

                                Text(String(format: "%.1f%%", percent))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                            }

                            // Raw score
                            Text(String(format: "%.1f", score))
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("Aspect score data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)

                Picker("Meaning Type", selection: $showKeyword) {
                    Text("Keywords").tag(true)
                    Text("Degrees").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                AspectMeaningSummaryView(showKeyword: showKeyword)
                    .padding(.bottom)
            }
            .padding()
        }
    }

    private func calculateBarWidth(_ score: Double, _ allScores: [(Kind, Double)]) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 200
        if let maxScore = allScores.map({ $0.1 }).max(), maxScore > 0 {
            let ratio = score / maxScore
            return max(20, ratio * maxBarWidth)
        }
        return 40
    }

    private func aspectColor(_ aspect: Kind) -> Color {
        switch aspect {
        case .conjunction: return .purple
        case .sextile: return .green
        case .square: return .red
        case .trine: return .blue
        case .opposition: return .orange
        case .semisextile: return .mint
        case .semisquare: return .pink
        case .sesquisquare: return .indigo
        case .inconjunction: return .teal
        case .parallel: return .gray
        default: return .gray
        }
    }
}

struct AspectMeaningSummaryView: View {
    let showKeyword: Bool
    let aspects: [Kind] = Kind.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(showKeyword ? "Aspect Keywords" : "Aspect Degrees")
                .font(.headline)
                .padding(.vertical, 8)

            ForEach(aspects, id: \.self) { aspect in
                HStack(alignment: .top) {
                    Text("\(aspect.symbol) \(aspect.description.capitalized)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(width: 140, alignment: .leading)

                    Text(showKeyword ? aspect.keyword : aspect.degrees)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


//
//struct HarmonyDiscordView: View {
//    let person: Person
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Text("Planetary Harmony & Discord")
//                    .font(.headline)
//                    .padding(.top)
//                
//                if let harmonyDiscordScores = person.signHarmonyDiscordScores {
//                    let sortedScores = harmonyDiscordScores.sorted { $0.value.net > $1.value.net }
//                    
//                    ForEach(Array(sortedScores.enumerated()), id: \.offset) { index, element in
//                        let sign = element.key
//                        let scores = element.value
//                        
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(sign.keyName).fontWeight(.bold)
//                                Spacer()
//                                Text("Harmony: \(scores.harmony, specifier: "%.1f")")
//                                Text("Discord: \(scores.discord, specifier: "%.1f")")
//                            }
//                            
//                            Text("Net: \(scores.net, specifier: "%.1f")")
//                                .foregroundColor(scores.net >= 0 ? .green : .red)
//                            
//                            // 🎯 Bar chart
//                            HStack(spacing: 0) {
//                                ZStack(alignment: .trailing) {
//                                    Rectangle()
//                                        .fill(Color.green.opacity(0.7))
//                                        .frame(width: CGFloat(scores.harmony) * 5, height: 22)
//                                        .cornerRadius(6, corners: [.topLeft, .bottomLeft])
//                                    
//                                    Text(String(format: "%.1f", scores.harmony))
//                                        .font(.system(size: 12, weight: .medium))
//                                        .foregroundColor(.white)
//                                        .padding(.trailing, 4)
//                                }
//                                
//                                ZStack(alignment: .leading) {
//                                    Rectangle()
//                                        .fill(Color.red.opacity(0.7))
//                                        .frame(width: CGFloat(scores.discord) * 5, height: 22)
//                                        .cornerRadius(6, corners: [.topRight, .bottomRight])
//                                    
//                                    Text(String(format: "%.1f", scores.discord))
//                                        .font(.system(size: 12, weight: .medium))
//                                        .foregroundColor(.white)
//                                        .padding(.leading, 4)
//                                }
//                            }
//                            .frame(width: UIScreen.main.bounds.width - 40, alignment: .leading)
//                            .offset(x: (UIScreen.main.bounds.width - 40) / 2 - CGFloat(scores.harmony) * 5)
//                        }
//                        .padding(.vertical, 4)
//                        .padding(.horizontal)
//                    }
//                    
//                    // ✅ Interpretation block
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Interpretation")
//                            .font(.headline)
//                            .padding(.top, 20)
//                        
//                        Text("Planets with higher harmony scores (green) tend to bring beneficial influences and flow into your life in their respective areas. Planets with higher discord scores (red) may indicate areas of challenge or growth.")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                        
//                        if let mostHarmonious = sortedScores.first?.key,
//                           let mostDiscordant = sortedScores.last?.key {
//                            Text("Most Harmonious: \(mostHarmonious.keyName)")
//                                .font(.subheadline)
//                                .padding(.vertical, 4)
//                            
//                            Text("Most Challenging: \(mostDiscordant.keyName)")
//                                .font(.subheadline)
//                        }
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(10)
//                    .padding()
//                } else {
//                    Text("Harmony/discord data not available")
//                        .foregroundColor(.secondary)
//                        .padding()
//                }
//            }
//            .padding()
//        }
//    }
//}
