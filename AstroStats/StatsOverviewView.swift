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
