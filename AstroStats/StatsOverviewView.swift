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

// Fixed Zoomable Chart - Completely locked until zoom
struct ZoomableBirthChartView: UIViewRepresentable {
    let person: Person

    func makeUIView(context: Context) -> UIView {
        // Create container view
        let containerView = UIView()
        containerView.backgroundColor = .clear

        // Create scroll view with zooming
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear

        // 🔒 Completely disable all scrolling and bouncing
        scrollView.isScrollEnabled = false
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false

        // Create birth chart view
        let chartView = createBirthChartView()
        chartView.tag = 100

        // Add gestures to the chart view instead of scroll view
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        chartView.addGestureRecognizer(doubleTapGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        chartView.addGestureRecognizer(pinchGesture)

        chartView.isUserInteractionEnabled = true

        scrollView.addSubview(chartView)
        containerView.addSubview(scrollView)

        // Store reference to scroll view for coordinator
        scrollView.tag = 200

        // Set up constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        chartView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view fills container
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Chart view centered and sized
            chartView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            chartView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            chartView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            chartView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        return containerView
    }

    func updateUIView(_ containerView: UIView, context: Context) {
        // No updates needed
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

    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableBirthChartView
        private var isZooming = false

        init(_ parent: ZoomableBirthChartView) {
            self.parent = parent
        }

        // Allow zooming
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }

        // Control scrolling based on zoom state
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Only enable scrolling when actually zoomed in
            let isZoomedIn = scrollView.zoomScale > 1.01 // Small buffer for floating point precision
            scrollView.isScrollEnabled = isZoomedIn
            scrollView.bounces = isZoomedIn

            // Center content when at minimum zoom
            if !isZoomedIn {
                centerContent(in: scrollView)
            }
        }

        // Prevent any movement when zoom ends at 1.0
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale <= 1.01 {
                scrollView.isScrollEnabled = false
                scrollView.bounces = false
                centerContent(in: scrollView)
            }
        }

        private func centerContent(in scrollView: UIScrollView) {
            guard let chartView = scrollView.viewWithTag(100) else { return }

            // Force content to center
            let boundsSize = scrollView.bounds.size
            let frameToCenter = chartView.frame

            let offsetX = max(0, (boundsSize.width - frameToCenter.width) / 2)
            let offsetY = max(0, (boundsSize.height - frameToCenter.height) / 2)

            scrollView.contentOffset = CGPoint(x: -offsetX, y: -offsetY)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let chartView = gesture.view,
                  let scrollView = chartView.superview as? UIScrollView else { return }

            switch gesture.state {
            case .began:
                isZooming = true
                scrollView.isScrollEnabled = true
                scrollView.bounces = true

            case .changed:
                // Handle zoom manually during gesture
                let scale = gesture.scale
                let newScale = scrollView.zoomScale * scale
                let clampedScale = min(max(newScale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)

                scrollView.zoomScale = clampedScale
                gesture.scale = 1.0

            case .ended, .cancelled:
                isZooming = false
                // Final check - disable if back to 1.0
                if scrollView.zoomScale <= 1.01 {
                    scrollView.isScrollEnabled = false
                    scrollView.bounces = false
                    centerContent(in: scrollView)
                }

            default:
                break
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let chartView = gesture.view,
                  let scrollView = chartView.superview as? UIScrollView else { return }

            if scrollView.zoomScale > 1.01 {
                // Zoom out to reset
                UIView.animate(withDuration: 0.3) {
                    scrollView.zoomScale = 1.0
                }
            } else {
                // Zoom in to tapped location
                let location = gesture.location(in: chartView)
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
