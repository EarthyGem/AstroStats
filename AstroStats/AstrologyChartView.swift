import SwiftUI
import UIKit
import SwiftEphemeris
struct AstrologyChartView: View {
    let person: Person
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Birth Chart
            BirthChartView(person: person)
                .tabItem {
                    Label("Birth Chart", systemImage: "circle.grid.cross")
                }
                .tag(0)
            
            // Tab 2: Planet Scores
            PlanetScoresView(person: person)
                .tabItem {
                    Label("Planets", systemImage: "star.circle")
                }
                .tag(1)
            
            // Tab 3: Sign Scores
            SignScoresView(person: person)
                .tabItem {
                    Label("Signs", systemImage: "circle.hexagongrid")
                }
                .tag(2)
            
            // Tab 4: House Scores
            HouseScoresView(person: person)
                .tabItem {
                    Label("Houses", systemImage: "square.grid.3x3")
                }
                .tag(3)
            
            // Tab 5: Harmony & Discord
            // Tab 5: Aspects
            AspectStrengthView(person: person)
                .tabItem {
                    Label("Aspects", systemImage: "waveform.path.ecg")
                }
                .tag(4)


        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
// Birth Chart View that wraps the UIKit BirthChartView - with scrolling and zooming
struct BirthChartView: View {
    let person: Person
    
    var body: some View {
        // Main ScrollView containing all content
        ScrollView {
            VStack(spacing: 16) {
                // Info card at the top
                InfoCardView(person: person)
                    .padding(.horizontal)
                
                // Chart container with rounded corners and shadow
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
                    
                    // Zoomable birth chart
                    ZoomableBirthChartView(person: person)
                        .padding(8)
                }
                .padding(.horizontal, 16)
                .aspectRatio(1, contentMode: .fit) // Keep it square
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// Improved InfoCardView
struct InfoCardView: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and birth info
            VStack(alignment: .center, spacing: 4) {
                Text(person.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text(formatBirthInfo())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)

            Divider()

            // Attributes with glyphs
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160), spacing: 16)],
                alignment: .leading,
                spacing: 12
            ) {
                if let strongestPlanet = person.strongestPlanet {
                    AstroGlyphRow(
                        label: "Strongest Planet",
                        image: GlyphProvider.planetImage(for: strongestPlanet),
                        value: strongestPlanet
                    )
                }

                if let sun = person.sunSign {
                    AstroGlyphRow(
                        label: "Sun",
                        image: GlyphProvider.signImage(for: sun),
                        value: sun
                    )
                }

                if let moon = person.moonSign {
                    AstroGlyphRow(
                        label: "Moon",
                        image: GlyphProvider.signImage(for: moon),
                        value: moon
                    )
                }

                if let asc = person.ascendantSign {
                    AstroGlyphRow(
                        label: "Ascendant",
                        image: GlyphProvider.signImage(for: asc),
                        value: asc
                    )
                }

                if let strongestSign = person.strongestSign {
                    AstroGlyphRow(
                        label: "Strongest Sign",
                        image: GlyphProvider.signImage(for: strongestSign),
                        value: strongestSign
                    )
                }

                AstroAttributeRow(
                    label: "Strongest House",
                    value: person.strongestHouse ?? "??"
                )
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func formatBirthInfo() -> String {
        // Simply use the person's formattedBirthDate() method instead of creating a new formatter
        return "\(person.formattedBirthDate()) • \(person.birthPlace)"
    }
    private func ordinalHouseString(for house: String?) -> String {
        guard let houseStr = house, let number = Int(houseStr) else { return "Unknown" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
struct AstroGlyphRow: View {
    let label: String
    let image: Image
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

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
}


struct AstroAttributeRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// Zoomable UIKit wrapper for Birth Chart
struct ZoomableBirthChartView: UIViewRepresentable {
    let person: Person
    
    func makeUIView(context: Context) -> UIScrollView {
        // Create scroll view with zooming
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear
        
        // Create birth chart view
        let chartView = createBirthChartView()
        chartView.tag = 100 // Tag for identification
        
        // Add double-tap gesture for zoom reset
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        chartView.addGestureRecognizer(doubleTapGesture)
        chartView.isUserInteractionEnabled = true
        
        scrollView.addSubview(chartView)
        
        // Set up constraints for the chart view
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            chartView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            chartView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            chartView.heightAnchor.constraint(equalTo: scrollView.widthAnchor) // Square aspect ratio
        ])
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update content size if needed
        if let chartView = scrollView.viewWithTag(100) {
            scrollView.contentSize = chartView.bounds.size
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createBirthChartView() -> UIView {
        let chart = Chart(
            date: person.birthDate,
            latitude: person.latitude,
            longitude: person.longitude,
            houseSystem: .placidus,
            name: person.name,
            birthPlace: person.birthPlace
        )
        
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        let birthChartView = ChartView(frame: frame, chart: chart)
        birthChartView.backgroundColor = .white
        birthChartView.layer.cornerRadius = 16
        birthChartView.clipsToBounds = true
        
        return birthChartView
    }
    
    // Coordinator for UIScrollView delegate
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableBirthChartView
        
        init(_ parent: ZoomableBirthChartView) {
            self.parent = parent
        }
        
        // Allow zooming
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }
        
        // Reset zoom on double tap
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            if let scrollView = gesture.view?.superview as? UIScrollView {
                if scrollView.zoomScale > scrollView.minimumZoomScale {
                    // Reset zoom
                    UIView.animate(withDuration: 0.3) {
                        scrollView.zoomScale = scrollView.minimumZoomScale
                    }
                } else {
                    // Zoom in to where tapped
                    let location = gesture.location(in: gesture.view)
                    let zoomRect = CGRect(
                        x: location.x - 50,
                        y: location.y - 50,
                        width: 100,
                        height: 100
                    )
                    scrollView.zoom(to: zoomRect, animated: true)
                }
            }
        }
    }
}
// Planet Scores Chart View
struct PlanetScoresView: View {
    let person: Person
    @State private var sortByStrength = true

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

                    ForEach(sortedPlanets, id: \.0) { planetName, score in
                        HStack {
                            HStack(spacing: 4) {
                                GlyphProvider.planetImage(for: planetName.keyName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)

                                Text(planetName.keyName)
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
                                    .fill(planetColor(planetName.keyName))
                                    .frame(width: calculateBarWidth(score, totalScore), height: 22)
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
                    Text("Planet score data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)

                Text("Strongest Planet: \(person.strongestPlanet ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom)
            }
            .padding()
        }
    }

    private func calculateBarWidth(_ score: Double, _ totalScore: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 100
        let ratio = pow(score / totalScore, 0.8)
        return max(20, ratio * maxBarWidth)
    }

    private func planetColor(_ planet: String) -> Color {
        switch planet.lowercased() {
        case "sun": return .orange
        case "moon": return .blue
        case "mercury": return .purple
        case "venus": return .pink
        case "mars": return .red
        case "jupiter": return .yellow
        case "saturn": return .gray
        case "uranus": return .green
        case "neptune": return .teal
        case "pluto": return .indigo
        default: return .gray
        }
    }
}

struct PlanetSymbolView: View {
    let planet: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(planetColor)
                .frame(width: 28, height: 28)
            
            Text(planetSymbol)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
    
    private var planetSymbol: String {
        switch planet.lowercased() {
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
        default: return "★"
        }
    }
    
    private var planetColor: Color {
        switch planet.lowercased() {
        case "sun": return .orange
        case "moon": return .blue
        case "mercury": return .purple
        case "venus": return .pink
        case "mars": return .red
        case "jupiter": return .yellow
        case "saturn": return .gray
        case "uranus": return .green
        case "neptune": return .teal
        case "pluto": return .indigo
        default: return .gray
        }
    }
}

struct SignScoresView: View {
    let person: Person
    @State private var sortByStrength = false

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

                    ForEach(signs, id: \.0) { signName, score in
                        HStack {
                            HStack(spacing: 4) {
                                GlyphProvider.signImage(for: signName.keyName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)

                                Text(signName.keyName)
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
                                    .fill(signColor(signName.keyName))
                                    .frame(width: max(calculateBarWidth(score, totalScore), 20), height: 22)
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
                    Text("Zodiac sign data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)

                Text("Sun Sign: \(person.sunSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom, 4)

                Text("Moon Sign: \(person.moonSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom, 4)

                Text("Ascendant: \(person.ascendantSign ?? "Unknown")")
                    .font(.headline)
                    .padding(.bottom)
            }
            .padding()
        }
    }

    private func calculateBarWidth(_ score: Double, _ totalScore: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 100
        let ratio = pow(score / totalScore, 0.8)
        return max(20, ratio * maxBarWidth)
    }

    private func signColor(_ sign: String) -> Color {
        switch sign {
        case "Aries", "Leo", "Sagittarius": return .red
        case "Taurus", "Virgo", "Capricorn": return .green
        case "Gemini", "Libra", "Aquarius": return .blue
        case "Cancer", "Scorpio", "Pisces": return .teal
        default: return .gray
        }
    }
}


// House Scores Chart View
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
                                    .frame(width: calculateBarWidth(score, totalScore), height: 22)
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

    private func calculateBarWidth(_ score: Double, _ totalScore: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 100
        let ratio = pow(score / totalScore, 0.8)
        return max(20, ratio * maxBarWidth)
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



struct AspectStrengthView: View {
    let person: Person

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

                let chart = ChartCake(
                    birthDate: person.birthDate,
                    latitude: person.latitude,
                    longitude: person.longitude,
                    name: person.name,
                    sexString: "Unknown",
                    categoryString: "Unknown",
                    roddenRating: "AA",
                    birthPlace: person.birthPlace
                )

                let scores = chart.natal.totalScoresByAspectType()
                let totalScore = scores.map { $0.1 }.reduce(0, +)

                ForEach(Array(scores.enumerated()), id: \.0) { index, pair in

                    let aspect = pair.0
                    let score = pair.1
                    let percent = (score / totalScore) * 100
                    let color = aspectColor(aspect)

                    HStack {
                        Text(aspectSymbolMapping[aspect] ?? aspect.symbol)
                            .font(.system(size: 20))
                            .frame(width: 40, alignment: .leading)
                            .foregroundColor(color)  // Apply the same color as the bar

                        Text(aspect.description.capitalized)
                            .frame(width: 100, alignment: .leading)

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 22)
                                .cornerRadius(6)

                            Rectangle()
                                .fill(color)
                                .frame(width: calculateBarWidth(score, totalScore), height: 22)
                                .cornerRadius(6)

                            Text(String(format: "%.1f%%", percent))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                        }

                        Text(String(format: "%.1f", score))
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    private func calculateBarWidth(_ score: Double, _ totalScore: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let maxBarWidth: CGFloat = screenWidth - 100 // more room for visible differentiation
        let ratio = pow(score / totalScore, 0.8)     // nonlinear curve
        return max(20, ratio * maxBarWidth)          // ensures a visible minimum
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
