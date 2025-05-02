import SwiftUI
import UIKit

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
            HarmonyDiscordView(person: person)
                .tabItem {
                    Label("Harmony", systemImage: "circle.righthalf.filled")
                }
                .tag(4)
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Birth Chart View that wraps the UIKit BirthChartView
struct BirthChartView: View {
    let person: Person
    
    var body: some View {
        VStack(spacing: 0) {
            InfoCardView(person: person)
                .padding()
            
            // Use UIViewRepresentable to wrap the UIKit birth chart view
            BirthChartUIViewWrapper(person: person)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

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
            
            // Core astrological data
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    AstroAttributeRow(label: "Sun", value: person.sunSign ?? "Unknown")
                    AstroAttributeRow(label: "Moon", value: person.moonSign ?? "Unknown")
                    AstroAttributeRow(label: "Ascendant", value: person.ascendantSign ?? "Unknown")
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 6) {
                    AstroAttributeRow(label: "Strongest Planet", value: person.strongestPlanet ?? "Unknown")
                    AstroAttributeRow(label: "Longitude", value: String(format: "%.4f°", person.longitude))
                    AstroAttributeRow(label: "Latitude", value: String(format: "%.4f°", person.latitude))
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatBirthInfo() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return "\(dateFormatter.string(from: person.birthDate)) • \(person.birthPlace)"
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
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// UIViewRepresentable wrapper for the UIKit Birth Chart View
struct BirthChartUIViewWrapper: UIViewRepresentable {
    let person: Person
    
    func makeUIView(context: Context) -> UIView {
        // Create the birth chart view container
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Create and add the birth chart view
        let birthChartView = createBirthChartView()
        containerView.addSubview(birthChartView)
        
        // Set up constraints
        birthChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            birthChartView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            birthChartView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            birthChartView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.9),
            birthChartView.heightAnchor.constraint(equalTo: birthChartView.widthAnchor) // Square aspect ratio
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the chart view if needed
    }
    
    private func createBirthChartView() -> UIView {
        // Create a placeholder birth chart view
        // In a real app, you would use your actual BirthChartView class from your code
        let birthChartView = PlaceholderBirthChartView(frame: .zero)
        birthChartView.person = person
        return birthChartView
    }
}

// Placeholder Birth Chart View - Replace with your actual implementation
class PlaceholderBirthChartView: UIView {
    var person: Person?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Background
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fillEllipse(in: rect.insetBy(dx: 2, dy: 2))
        
        context?.setStrokeColor(UIColor.gray.cgColor)
        context?.setLineWidth(2.0)
        context?.strokeEllipse(in: rect.insetBy(dx: 2, dy: 2))
        
        // Draw wheel divisions for houses
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 2
        
        for i in 0..<12 {
            let angle = CGFloat(i) * (2.0 * .pi / 12.0)
            let x1 = center.x + radius * 0.5 * cos(angle)
            let y1 = center.y + radius * 0.5 * sin(angle)
            let x2 = center.x + radius * cos(angle)
            let y2 = center.y + radius * sin(angle)
            
            context?.move(to: CGPoint(x: x1, y: y1))
            context?.addLine(to: CGPoint(x: x2, y: y2))
            context?.strokePath()
        }
        
        // Add zodiac symbols along the outer edge
        let zodiacSigns = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]
        let fontSize: CGFloat = 16.0
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black
        ]
        
        for i in 0..<12 {
            let angle = CGFloat(i) * (2.0 * .pi / 12.0) - .pi / 2 // Start from top (12 o'clock)
            let x = center.x + (radius - 20) * cos(angle)
            let y = center.y + (radius - 20) * sin(angle)
            
            let text = zodiacSigns[i] as NSString
            let textSize = text.size(withAttributes: textAttributes)
            
            text.draw(at: CGPoint(x: x - textSize.width / 2, y: y - textSize.height / 2), 
                      withAttributes: textAttributes)
        }
        
        // Place planet symbols (simplified)
        if let person = person, let planetScores = person.planetScores {
            let planets = ["☉", "☽", "☿", "♀", "♂", "♃", "♄", "♅", "♆", "♇"]
            let planetNames = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
            
            let planetAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.blue
            ]
            
            // Distribute planets around the chart
            for i in 0..<min(planets.count, planetNames.count) {
                if let score = planetScores[planetNames[i]] {
                    // Position planets at different distances from center based on score
                    let angle = CGFloat(i) * (2.0 * .pi / 10.0) - .pi / 3
                    let distance = radius * (0.3 + 0.3 * CGFloat(score / 20.0))
                    let x = center.x + distance * cos(angle)
                    let y = center.y + distance * sin(angle)
                    
                    let planetSymbol = planets[i] as NSString
                    let textSize = planetSymbol.size(withAttributes: planetAttributes)
                    
                    planetSymbol.draw(at: CGPoint(x: x - textSize.width / 2, y: y - textSize.height / 2), 
                                      withAttributes: planetAttributes)
                }
            }
        }
        
        // Draw center circle
        context?.setFillColor(UIColor.lightGray.cgColor)
        context?.fillEllipse(in: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20))
    }
}

// Planet Scores Chart View
struct PlanetScoresView: View {
    let person: Person
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Planet Power Distribution")
                    .font(.headline)
                    .padding(.top)
                
                if let planetScores = person.planetScores {
                    let totalScore = planetScores.values.reduce(0, +)
                    let sortedPlanets = planetScores.sorted { $0.value > $1.value }
                    
                    ForEach(sortedPlanets, id: \.key) { planetName, score in
                        HStack {
                            HStack(spacing: 4) {
                                PlanetSymbolView(planet: planetName)
                                    .frame(width: 28, height: 28)
                                
                                Text(planetName)
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
                                    .fill(planetColor(planetName))
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
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 200
        return CGFloat(score / totalScore) * maxWidth
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

// Sign Scores Chart View
struct SignScoresView: View {
    let person: Person
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Zodiac Sign Distribution")
                    .font(.headline)
                    .padding(.top)
                
                if let signScores = person.signScores {
                    let totalScore = signScores.values.reduce(0, +)
                    
                    // Use zodiac order
                    let zodiacOrder = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", 
                                       "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
                    
                    let orderedSigns = zodiacOrder.compactMap { sign -> (String, Double)? in
                        if let score = signScores[sign] {
                            return (sign, score)
                        }
                        return nil
                    }
                    
                    ForEach(orderedSigns, id: \.0) { signName, score in
                        HStack {
                            HStack(spacing: 4) {
                                Text(zodiacSymbol(for: signName))
                                    .font(.system(size: 18))
                                    .frame(width: 28, height: 28)
                                
                                Text(signName)
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
                                    .fill(signColor(signName))
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
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 200
        return CGFloat(score / totalScore) * maxWidth
    }
    
    private func zodiacSymbol(for sign: String) -> String {
        switch sign {
        case "Aries": return "♈"
        case "Taurus": return "♉"
        case "Gemini": return "♊"
        case "Cancer": return "♋"
        case "Leo": return "♌"
        case "Virgo": return "♍"
        case "Libra": return "♎"
        case "Scorpio": return "♏"
        case "Sagittarius": return "♐"
        case "Capricorn": return "♑"
        case "Aquarius": return "♒"
        case "Pisces": return "♓"
        default: return "?"
        }
    }
    
    private func signColor(_ sign: String) -> Color {
        switch sign {
        case "Aries", "Leo", "Sagittarius": // Fire signs
            return .red
        case "Taurus", "Virgo", "Capricorn": // Earth signs
            return .green
        case "Gemini", "Libra", "Aquarius": // Air signs
            return .blue
        case "Cancer", "Scorpio", "Pisces": // Water signs
            return .teal
        default:
            return .gray
        }
    }
}

// House Scores Chart View
struct HouseScoresView: View {
    let person: Person
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Astrological Houses Distribution")
                    .font(.headline)
                    .padding(.top)
                
                if let houseScores = person.houseScores {
                    let totalScore = houseScores.values.reduce(0, +)
                    let sortedHouses = houseScores.sorted { $0.key < $1.key }
                    
                    ForEach(sortedHouses, id: \.key) { houseNumber, score in
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
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 200
        return CGFloat(score / totalScore) * maxWidth
    }
    
    private func houseColor(_ house: Int) -> Color {
        switch house {
        case 1, 5, 9: // Fire houses
            return .red.opacity(0.8)
        case 2, 6, 10: // Earth houses
            return .green.opacity(0.8)
        case 3, 7, 11: // Air houses
            return .blue.opacity(0.8)
        case 4, 8, 12: // Water houses
            return .purple.opacity(0.8)
        default:
            return .gray
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

// Harmony Discord View
struct HarmonyDiscordView: View {
    let person: Person
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Planetary Harmony & Discord")
                    .font(.headline)
                    .padding(.top)
                
                if let harmonyDiscordScores = person.harmonyDiscordScores {
                    let sortedScores = harmonyDiscordScores.sorted { $0.value.difference > $1.value.difference }
                    
                    ForEach(sortedScores, id: \.key) { planetName, scores in
                        VStack(spacing: 4) {
                            HStack {
                                HStack(spacing: 8) {
                                    PlanetSymbolView(planet: planetName)
                                        .frame(width: 28, height: 28)
                                    
                                    Text(planetName)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(width: 120, alignment: .leading)
                                
                                Spacer()
                                
                                Text("Net: \(String(format: "%.1f", scores.difference))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(scores.difference >= 0 ? .green : .red)
                            }
                            
                            HStack(spacing: 0) {
                                // Harmony bar
                                ZStack(alignment: .trailing) {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.7))
                                        .frame(width: CGFloat(scores.harmony) * 5, height: 22)
                                        .cornerRadius(6, corners: [.topLeft, .bottomLeft])
                                    
                                    Text(String(format: "%.1f", scores.harmony))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.trailing, 4)
                                }
                                
                                // Discord bar
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.red.opacity(0.7))
                                        .frame(width: CGFloat(scores.discord) * 5, height: 22)
                                        .cornerRadius(6, corners: [.topRight, .bottomRight])
                                    
                                    Text(String(format: "%.1f", scores.discord))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.leading, 4)
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width - 40, alignment: .leading)
                            .offset(x: (UIScreen.main.bounds.width - 40) / 2 - CGFloat(scores.harmony) * 5)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interpretation")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        Text("Planets with higher harmony scores (green) tend to bring beneficial influences and flow into your life in their respective areas. Planets with higher discord scores (red) may indicate areas of challenge or growth.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let mostHarmonious = sortedScores.first?.key,
                           let mostDiscordant = sortedScores.last?.key {
                            Text("Most Harmonious: \(mostHarmonious)")
                                .font(.subheadline)
                                .padding(.vertical, 4)
                            
                            Text("Most Challenging: \(mostDiscordant)")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    
                } else {
                    Text("Harmony/discord data not available")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
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