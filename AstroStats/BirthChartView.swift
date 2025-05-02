//
//  BirthChartView.swift
//  AstroStats
//
//  Created by Errick Williams on 5/1/25.
//


//
//  BirthChartView.swift
//  AstroLogic2
//

import UIKit
import SwiftEphemeris
import OrderedCollections

    class ChartView: UIView {
        var planetPositions: [CelestialObject: CGFloat] = [:]
        var chart: Chart?
        let baseFontSize: CGFloat = 8
        let smallBaseFontSize: CGFloat = 6
        var isStatic: Bool = false // Add this flag to control gesture recognizers

        // Add a separate initializer for creating static view for image rendering
        init(frame: CGRect, chart: Chart, isStatic: Bool = false) {
            self.chart = chart
            self.isStatic = isStatic
            super.init(frame: frame)

            // Only set up gesture recognizers if this is not a static view
            if !isStatic {
                setupGestureRecognizers()
            }
            updateBirthChart()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var pinchGesture: UIPinchGestureRecognizer!
        private var panGesture: UIPanGestureRecognizer!
        private var currentScale: CGFloat = 1.0
        private var lastLocation: CGPoint = .zero


        private func setupGestureRecognizers() {
            pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            addGestureRecognizer(pinchGesture)

            panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            addGestureRecognizer(panGesture)
        }

        // Rest of your BirthChartView implementation remains the same...

        // Optional: You might want to clean up the view's subviews before rendering as an image
        func prepareForImageCapture() {
            // Remove any interactive elements or temporary views that shouldn't be in the image
            for subview in subviews {
                if subview is UIButton {
                    subview.removeFromSuperview()
                }
            }
        }
    

    // In your ChartViewController:
    func createStaticBirthChartImage() -> UIImage {
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height - 200)
        let rect = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth)

        // Create a static version of the birth chart view
        let staticBirthChartView = ChartView(frame: rect, chart: chart!, isStatic: true)
        staticBirthChartView.backgroundColor = .white

        // Ensure the view is laid out and rendered
        staticBirthChartView.setNeedsLayout()
        staticBirthChartView.layoutIfNeeded()

        // Create an image of the view
        return staticBirthChartView.asImage()
    }
    @objc private func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            currentScale = gestureRecognizer.scale
        }

        let minScale: CGFloat = 0.1
        let maxScale: CGFloat = 3.0

        var newScale = currentScale * gestureRecognizer.scale
        newScale = min(newScale, maxScale)
        newScale = max(newScale, minScale)

        let scaleTransform = CGAffineTransform(scaleX: newScale, y: newScale)
        transform = scaleTransform

        currentScale = gestureRecognizer.scale
    }

    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self.superview)
        switch gestureRecognizer.state {
        case .began:
            lastLocation = self.center
        case .changed:
            let center = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
            self.center = center
        default:
            break
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
         backgroundColor = .white
        // Draw the zodiac circle, houses, and planet symbols
        drawZodiacCircle(context: context)
        drawHouseLines(context: context)
        drawPlanetSymbols(context: context)
//        print(getHousesDegree())
//        print(getHouseNames())
//        print(getHousesCuspLongitude())
    }

    private func drawZodiacCircle(context: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.45
        context.setStrokeColor(UIColor.systemIndigo.cgColor)
        context.setLineWidth(0.3)
        context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.strokePath()

        let innerRadius1 = radius * 0.34
        let innerRadius2 = radius * 0.41
        context.addEllipse(in: CGRect(x: center.x - innerRadius1, y: center.y - innerRadius1, width: innerRadius1 * 2, height: innerRadius1 * 2))
        context.strokePath()

        context.addEllipse(in: CGRect(x: center.x - innerRadius2, y: center.y - innerRadius2, width: innerRadius2 * 2, height: innerRadius2 * 2))
        context.strokePath()

        // Draw the image in the middle of the zodiac circle
        let lilaImage = UIImage(named: "Lila")
        let imageRadius = radius * 0.2
        let imageSize = CGSize(width: imageRadius * 1.5, height: imageRadius * 1.5)
        let imageOrigin = CGPoint(x: center.x - imageSize.width / 2, y: center.y - imageSize.height / 2)
        let imageFrame = CGRect(origin: imageOrigin, size: imageSize)
        lilaImage?.draw(in: imageFrame)
    }

    private func drawHouseLines(context: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.45
        let innerRadius1 = radius * 0.34
        let innerRadius2 = radius * 0.41
        let labelRadius = (innerRadius1 + innerRadius2) / 2
        let houseDegrees = getHousesDegree()
        let houseMinutes = getHousesMinute()
        let houseDistances = getHousesDistances()
        let houseCuspSignNames = getHouseNames()
        let font = UIFont.systemFont(ofSize: dynamicScalingFactor(baseSize: baseFontSize))
        let smallFont = dynamicScalingFactor(baseSize: smallBaseFontSize)
        context.setStrokeColor(UIColor.systemIndigo.cgColor)
        context.setLineWidth(0.3)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        var accumulatedAngle: CGFloat = 0

        for index in 0..<12 {
            let angle = 2 * .pi - ((accumulatedAngle + houseDistances[index]) * .pi / 180) + .pi
            let startX = center.x + cos(angle) * innerRadius1
            let startY = center.y + sin(angle) * innerRadius1

            let endX = center.x + cos(angle) * radius
            let endY = center.y + sin(angle) * radius

            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()

            let houseDegree = houseDegrees[(index + 1) % 12]
            let houseMinute = houseMinutes[(index + 1) % 12]
            let glyphLabelAngleOffset: CGFloat = 0.0
            let degreeLabelAngleOffset: CGFloat
            let minuteLabelAngleOffset: CGFloat
            let adjustedIndex = (index + 1) % 12

            if index == 11 { // House 1
                degreeLabelAngleOffset = 0.11
                minuteLabelAngleOffset = -0.08
            } else if adjustedIndex < 6 { // Houses 2-6
                degreeLabelAngleOffset = 0.11
                minuteLabelAngleOffset = -0.08
            } else { // Houses 7-12
                degreeLabelAngleOffset = -0.08
                minuteLabelAngleOffset = 0.08
            }

            // Add the house number label
            let houseNumberLabel = UILabel()
            houseNumberLabel.textColor = .systemIndigo
            houseNumberLabel.textAlignment = .center
            houseNumberLabel.text = "\((index) % 12 + 1)"
            houseNumberLabel.font = UIFont(name: "TimesNewRomanPSMT", size: smallFont) ?? UIFont.systemFont(ofSize: smallFont, weight: .bold)
            houseNumberLabel.sizeToFit()

            let labelAngle = 2 * .pi - ((accumulatedAngle + (houseDistances[index] / 2)) * .pi / 180) + .pi
            let labelX = center.x + cos(labelAngle) * labelRadius - houseNumberLabel.bounds.width / 2
            let labelY = center.y + sin(labelAngle) * labelRadius - houseNumberLabel.bounds.height / 2
            houseNumberLabel.frame.origin = CGPoint(x: labelX, y: labelY)
            addSubview(houseNumberLabel)

            // Add the house degree label
            let houseDegreeLabel = UILabel()
            houseDegreeLabel.textColor = .black
            houseDegreeLabel.textAlignment = .center
            houseDegreeLabel.text = "\(Int(houseDegree))°"
            houseDegreeLabel.font = UIFont(name: "TimesNewRomanPSMT", size: font.pointSize) ?? UIFont.systemFont(ofSize: smallFont)
            houseDegreeLabel.sizeToFit()
            let labelRadius1 = 1.07 * radius
            let labelAngle1 = 2 * .pi - ((accumulatedAngle + houseDistances[index]) * .pi / 180) + .pi + degreeLabelAngleOffset
            let labelX1 = center.x + cos(labelAngle1) * labelRadius1 - houseDegreeLabel.bounds.width / 2
            let labelY1 = center.y + sin(labelAngle1) * labelRadius1 - houseDegreeLabel.bounds.height / 2
            houseDegreeLabel.frame.origin = CGPoint(x: labelX1, y: labelY1)
            addSubview(houseDegreeLabel)

            let signName = houseCuspSignNames[(index + 1) % 12]

            guard let image = UIImage(named: signName) else { continue }
            print("House \(index + 1) : Degree \(Int(houseDegree))°, Minute \(Int(houseMinute))', Sign Index: \(signName)")

            let imageSize = min(bounds.width, bounds.height) / 30
            let labelRadius2 = 1.07 * radius // Keep the same radius as the degree and minute labels
            let labelAngle2 = 2 * .pi - ((accumulatedAngle + houseDistances[index]) * .pi / 180) + .pi + glyphLabelAngleOffset
            let labelX2 = center.x + cos(labelAngle2) * labelRadius2 - imageSize / 2
            let labelY2 = center.y + sin(labelAngle2) * labelRadius2 - imageSize / 2
            let imageRect = CGRect(x: labelX2, y: labelY2, width: imageSize, height: imageSize)
            image.draw(in: imageRect)

            // Add the house minute label
            let houseMinuteLabel = UILabel()
            houseMinuteLabel.textColor = .black
            houseMinuteLabel.textAlignment = .center
            houseMinuteLabel.text = "\(Int(houseMinute))'"

            houseMinuteLabel.font = UIFont(name: "TimesNewRomanPSMT", size: font.pointSize) ?? UIFont.systemFont(ofSize: smallFont)
            houseMinuteLabel.sizeToFit()
            let labelRadius3 = 1.07 * radius
            let labelAngle3 = 2 * .pi - ((accumulatedAngle + houseDistances[index]) * .pi / 180) + .pi + minuteLabelAngleOffset
            let labelX3 = center.x + cos(labelAngle3) * labelRadius3 - houseMinuteLabel.bounds.width / 2
            let labelY3 = center.y + sin(labelAngle3) * labelRadius3 - houseMinuteLabel.bounds.height / 2
            houseMinuteLabel.frame.origin = CGPoint(x: labelX3, y: labelY3)
            addSubview(houseMinuteLabel)

            accumulatedAngle += houseDistances[index]
        }
    }

    func zodiacSign(for degree: CGFloat) -> Int {
        let adjustedDegree = degree.truncatingRemainder(dividingBy: 360)
        return Int(adjustedDegree / 30)
    }
    func adjustedFontSize(for size: CGFloat) -> CGFloat {
        let device = UIDevice.current.userInterfaceIdiom
        let screenBounds = UIScreen.main.bounds
        let screenWidth = min(screenBounds.width, screenBounds.height)  // Ensure consistency regardless of orientation

        switch device {
        case .pad:
            // Significantly increase the scaling factor for iPads
            if screenWidth >= 1024 {  // iPad Pro 12.9"
                return size * 2.5  // Very large scaling for better readability
            } else if screenWidth >= 834 {  // iPad Pro 11" or iPad Air
                return size * 2.3  // Very large scaling for better readability
            } else {  // Standard iPads
                return size * 2.1  // Very large scaling for better readability
            }
        case .phone:
            // Adjust based on iPhone screen size
            if screenWidth >= 414 {  // iPhone Plus, Pro Max
                return size * 1.0
            } else if screenWidth >= 375 {  // iPhone 11, XR, etc.
                return size * 0.95
            } else {  // Smaller iPhones (SE, 5s, etc.)
                return size * 0.9
            }
        default:
            return size  // Default adjustment for any other cases
        }
    }

    private func drawPlanetSymbols(context: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let symbolSize = min(bounds.width, bounds.height) / 20
        // Adjust baseRadius based on the device type
        let device = UIDevice.current.userInterfaceIdiom
        let baseRadius: CGFloat
        if device == .pad {
            baseRadius = min(bounds.width, bounds.height) * 0.45 - 20
        } else if device == .phone {
            baseRadius = min(bounds.width, bounds.height) * 0.48 - 20
        } else {
            baseRadius = min(bounds.width, bounds.height) * 0.46 - 20 // Default value
        }
        let font = UIFont.systemFont(ofSize: dynamicScalingFactor(baseSize: baseFontSize))
        let smallFont = UIFont.systemFont(ofSize: dynamicScalingFactor(baseSize: smallBaseFontSize))
    //    let symbolSize = min(bounds.width, bounds.height) / 30

        let retrogradeOffsetFactor: CGFloat = 3.5  // Adjust this factor to position "R" for retrograde
        let planetSymbols: [CelestialObject] = [
            .planet(.sun),
            .planet(.moon),
            .planet(.mercury),
            .planet(.venus),
            .planet(.mars),
            .planet(.jupiter),
            .planet(.saturn),
            .planet(.uranus),
            .planet(.neptune),
            .planet(.pluto),
            .lunarNode(.meanSouthNode),
            .lunarNode(.meanNode),
            .asteroid(.chiron)
        ]

        guard let chart = chart else { return }
        let natal = chart

        // Sample data structure to determine retrograde status (populate with real data)
        let isRetrograde: [CelestialObject: Bool] = chart.determineIfRetrograde(for: chart.planets)


        let planetDegree: [(planet: CelestialObject, degree: Int)] = [
            (.planet(.sun), Int(natal.sun.degree)),
            (.planet(.moon), Int(natal.moon.degree)),
            (.planet(.mercury), Int(natal.mercury.degree)),
            (.planet(.venus), Int(natal.venus.degree)),
            (.planet(.mars), Int(natal.mars.degree)),
            (.planet(.jupiter), Int(natal.jupiter.degree)),
            (.planet(.saturn), Int(natal.saturn.degree)),
            (.planet(.uranus), Int(natal.uranus.degree)),
            (.planet(.neptune), Int(natal.neptune.degree)),
            (.planet(.pluto), Int(natal.pluto.degree)),
            (.lunarNode(.meanSouthNode), Int(natal.southNode.degree)),
            (.lunarNode(.meanNode), Int(natal.northNode.degree)),
            (.asteroid(.chiron), Int(natal.chiron.degree))
        ]

        let planetSignSymbols: [(planet: CelestialObject, sign: Zodiac)] = [
            (.planet(.sun), natal.sun.sign),
            (.planet(.moon), natal.moon.sign),
            (.planet(.mercury), natal.mercury.sign),
            (.planet(.venus), natal.venus.sign),
            (.planet(.mars), natal.mars.sign),
            (.planet(.jupiter), natal.jupiter.sign),
            (.planet(.saturn), natal.saturn.sign),
            (.planet(.uranus), natal.uranus.sign),
            (.planet(.neptune), natal.neptune.sign),
            (.planet(.pluto), natal.pluto.sign),
            (.lunarNode(.meanSouthNode), natal.southNode.sign),
            (.lunarNode(.meanNode), natal.northNode.sign),
            (.asteroid(.chiron), (natal.chiron.sign))
        ]

        let planetMinute: [(planet: CelestialObject, minute: Int)] = [
            (.planet(.sun), Int(natal.sun.minute)),
            (.planet(.moon), Int(natal.moon.minute)),
            (.planet(.mercury), Int(natal.mercury.minute)),
            (.planet(.venus), Int(natal.venus.minute)),
            (.planet(.mars), Int(natal.mars.minute)),
            (.planet(.jupiter), Int(natal.jupiter.minute)),
            (.planet(.saturn), Int(natal.saturn.minute)),
            (.planet(.uranus), Int(natal.uranus.minute)),
            (.planet(.neptune), Int(natal.neptune.minute)),
            (.planet(.pluto), Int(natal.pluto.minute)),
            (.lunarNode(.meanSouthNode), Int(natal.southNode.minute)),
            (.lunarNode(.meanNode), Int(natal.northNode.minute)),
            (.asteroid(.chiron), Int(natal.chiron.minute))

        ]

        let sortedPlanetSymbols = planetSymbols.sorted { (symbol1, symbol2) -> Bool in
            if let position1 = planetPositions[symbol1], let position2 = planetPositions[symbol2] {
                return position1 < position2
            }
            return false
        }

        let sortedPlanetDegree = planetDegree.sorted { (degree1, degree2) -> Bool in
            if let position1 = planetPositions[degree1.planet], let position2 = planetPositions[degree2.planet] {
                return position1 < position2
            }
            return false
        }

        let sortedPlanetSignSymbol = planetSignSymbols.sorted { (sign1, sign2) -> Bool in
            if let position1 = planetPositions[sign1.planet], let position2 = planetPositions[sign2.planet] {
                return position1 < position2
            }
            return false
        }

        let sortedPlanetMinute = planetMinute.sorted { (minute1, minute2) -> Bool in
            if let position1 = planetPositions[minute1.planet], let position2 = planetPositions[minute2.planet] {
                return position1 < position2
            }
            return false
        }

        for (index, celestialObject) in sortedPlanetSymbols.enumerated() {
            guard let position = planetPositions[celestialObject] else { continue }
            let angle = 2 * .pi - (position * .pi / 180) + .pi

            let radius = baseRadius
            let planetCenter = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            let celestialRect = CGRect(x: planetCenter.x - symbolSize / 2, y: planetCenter.y - symbolSize / 2, width: symbolSize, height: symbolSize)

            drawPlanetSymbol(context: context, imageName: celestialObject.keyName.lowercased(), angle: angle, radius: radius, center: center)

            let degreeText = sortedPlanetDegree[index].degree
            drawTextLabel(context: context, text: "\(degreeText)º", angle: angle, radius: radius - symbolSize, center: center, fontSize: font.pointSize)

            let sign = sortedPlanetSignSymbol[index].sign
            drawSignSymbol(context: context, imageName: sign.keyName, angle: angle, radius: radius - symbolSize * 2, center: center)

            let minuteText = "\(sortedPlanetMinute[index].minute)'"
            drawTextLabel2(context: context, text: minuteText, angle: angle, radius: radius - symbolSize * 3, center: center, fontSize: smallFont.pointSize)


            // Retrograde Symbol Radius (only if retrograde)
             if isRetrograde[celestialObject] == true {
                 let retrogradeRadius = radius - symbolSize * retrogradeOffsetFactor
                 drawTextLabel(context: context, text: "℞", angle: angle, radius: retrogradeRadius, center: center, fontSize: adjustedFontSize(for: 4))
             }

            // (CGRect) (origin = (x = 858.05967324727112, y = 342.02428031177311), size = (width = 33.466666666666669, height = 33.466666666666669))

            print("planet: \(celestialObject.keyName) at sign: \(sign.keyName) degree: \(degreeText) and minute: \(minuteText)")
        }
    }

    private func drawSignSymbol(context: CGContext, imageName: String, angle: CGFloat, radius: CGFloat, center: CGPoint) {
        if let image = UIImage(named: imageName) {
            let imageSize = min(bounds.width, bounds.height) / 50
            let imageCenterX = center.x + cos(angle) * radius - imageSize / 2
            let imageCenterY = center.y + sin(angle) * radius - imageSize / 2
            let imageRect = CGRect(x: imageCenterX, y: imageCenterY, width: imageSize, height: imageSize)
            image.draw(in: imageRect)
        }
    }

    private func drawPlanetSymbol(context: CGContext, imageName: String, angle: CGFloat, radius: CGFloat, center: CGPoint) {
        if let image = UIImage(named: imageName) {
            let imageSize = min(bounds.width, bounds.height) / 35
            let imageCenterX = center.x + cos(angle) * radius - imageSize / 2
            let imageCenterY = center.y + sin(angle) * radius - imageSize / 2
            let imageRect = CGRect(x: imageCenterX, y: imageCenterY, width: imageSize, height: imageSize)
            image.draw(in: imageRect)
        }
    }

    // Additional functions for drawing symbols and labels
    private func drawTextLabel(context: CGContext, text: String, angle: CGFloat, radius: CGFloat, center: CGPoint, fontSize: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let font = UIFont.systemFont(ofSize: dynamicScalingFactor(baseSize: baseFontSize))

        // Use Times New Roman
        let customFont = UIFont(name: "TimesNewRomanPSMT", size: font.pointSize) ?? UIFont.systemFont(ofSize: fontSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: customFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.black
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let textCenterX = center.x + cos(angle) * radius - textSize.width / 2
        let textCenterY = center.y + sin(angle) * radius - textSize.height / 2
        let textRect = CGRect(x: textCenterX, y: textCenterY, width: textSize.width, height: textSize.height)
        attributedText.draw(in: textRect)
    }

    private func drawTextLabel2(context: CGContext, text: String, angle: CGFloat, radius: CGFloat, center: CGPoint, fontSize: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let smallFont = UIFont.systemFont(ofSize:dynamicScalingFactor(baseSize: smallBaseFontSize))
        // Use Times New Roman
        let customFont = UIFont(name: "TimesNewRomanPSMT", size: smallFont.pointSize) ?? UIFont.systemFont(ofSize: smallFont.pointSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: customFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.black
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let textCenterX = center.x + cos(angle) * radius - textSize.width / 2
        let textCenterY = center.y + sin(angle) * radius - textSize.height / 2
        let textRect = CGRect(x: textCenterX, y: textCenterY, width: textSize.width, height: textSize.height)
        attributedText.draw(in: textRect)
    }
    

    func updateBirthChart() {
        let ascendantOffset = getHouses()[0]
        let planets = fixPositionsIfNecessary()

        let planetPositions: [CelestialObject: CGFloat] = [
            .planet(.sun): planets[0] - ascendantOffset,
            .planet(.moon): planets[1] - ascendantOffset,
            .planet(.mercury): planets[2] - ascendantOffset,
            .planet(.venus): planets[3] - ascendantOffset,
            .planet(.mars): planets[4] - ascendantOffset,
            .planet(.jupiter): planets[5] - ascendantOffset,
            .planet(.saturn): planets[6] - ascendantOffset,
            .planet(.uranus): planets[7] - ascendantOffset,
            .planet(.neptune): planets[8] - ascendantOffset,
            .planet(.pluto): planets[9] - ascendantOffset,
            .lunarNode(.meanSouthNode): planets[10] - ascendantOffset,
            .lunarNode(.meanNode): planets[11] - ascendantOffset,
            .asteroid(.ceres): planets[12] - ascendantOffset
        ]
        updatePlanetPositions(newPositions: planetPositions)
    }
    func dynamicScalingFactor(baseSize: CGFloat) -> CGFloat {
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height - 140)
        let baseScreenWidth: CGFloat = 360.0
        let scalingFactor = screenWidth / baseScreenWidth
        if screenWidth > 1024 {
            return baseSize * scalingFactor
        } else if screenWidth > 768 {
            return baseSize * scalingFactor
        } else {
            return baseSize * scalingFactor
        }
    }
    func updatePlanetPositions(newPositions: [CelestialObject: CGFloat]) {
        planetPositions = newPositions
        setNeedsDisplay()
    }

    func fixPositionsIfNecessary() -> [CGFloat] {
        let planets = getPlanets() // list of positions
        let natal = self.chart!.houseCusps
        let gap = 3.5
        let minDistance = 4.0

   //     print("Degrees of house cusps:")
        for cusp in natal.houses {
            let degree = preciseRound(cusp.longitude, precision: .thousandths)
            print("cusp \(cusp.number) starting at \(degree) aka \(cusp.formatted)")
        }

        // Convert planets Array to an OrderedDictionary where key = index and value = degree
        let orderedBodies = planets.enumerated().reduce(into: OrderedDictionary<Int, CGFloat>()) { od, element in
            let (index, value) = element
            od[index] = value
        }

        // Sort 'orderedBodies' by chart degree
        let sortedBodiesI = orderedBodies.sorted {
            $0.value < $1.value
        }.reduce(into: OrderedDictionary<Int, CGFloat>()) { od, element in
            let (index, value) = element
            od[index] = value
        }

        // Print out the sortedBodies OrderedDictionary
//        for (key, degree) in sortedBodiesI {
//            print("\(key) : \(preciseRound(degree, precision: .thousandths))")
//        }

        func rolloverNormalize(_ val: CGFloat) -> CGFloat {
            return (val < 0.0) ? val + 360.0 : (val > 360.0) ? val - 360.0 : val
        }

        func rollover(_ longitude: CGFloat, add delta: CGFloat) -> CGFloat {
            return (longitude + delta < 0.0) ? (longitude + delta + 360) : (longitude + delta >= 360.0) ? (longitude + delta - 360.0) : (longitude + delta)
        }

        var sortedBodiesM = sortedBodiesI

        // What do we know?
        // Planets are sorted in order from Aries 0 to Pisces 29
        // Indexes are planet numbers:
        // Sun = 0
        // ...
        // Pluto = 9
        // South Node = 10

        // Get list of indexes (in degree order) where the planets are within 3.5 degrees of each other
        
        let pairs = zip(sortedBodiesI.keys, sortedBodiesI.keys.dropFirst())
        var adjacentIndexes = [(i: Int, j: Int)]()

        for (i, j) in pairs {
            let pos_i = sortedBodiesI[i]!
            let pos_j = sortedBodiesI[j]!
            let delta = abs(pos_j - pos_i)

            if delta < gap {
                let tuple = (i, j)
                adjacentIndexes.append(tuple)
            }
        }

//        if adjacentIndexes.count > 0 {
//            for (i, j) in adjacentIndexes {
//                let pos_i = preciseRound(sortedBodiesI[i]!, precision: .hundredths)
//                let pos_j = preciseRound(sortedBodiesI[j]!, precision: .hundredths)
//                print("\(i) = \(pos_i) and \(j) = \(pos_j)")
//            }
//        }

        // FIRST make sure any adjustment stay within their house
        // SECOND we want to preserve the Zodiac order of the planets

        func moveBodiesIfCuspsAreSame(_ i: Int, _ j: Int, _ cusp: Cusp) {
            let pos_i = sortedBodiesM[i]!
            let pos_j = sortedBodiesM[j]!
            let nextCusp = natal.nextCusp(of: cusp)

            func conventionalAdjustment(startOfHouse: CGFloat, endOfHouse: CGFloat) {
                let delta = abs(abs(pos_i) - abs(pos_j))

                if delta < gap {
                    let adjDelta = (minDistance - delta) / 2.0
                    let temp_i = rollover(pos_i, add: -adjDelta)
                    let temp_j = rollover(pos_j, add: adjDelta)

                    var adj_i = temp_i
                    var adj_j = temp_j

                    if temp_j > endOfHouse {
                        adj_j = rollover(pos_j, add: -adjDelta)
                        adj_i = rollover(adj_i, add: -adjDelta)
                    }

                    if temp_i < startOfHouse {
                        adj_i = rollover(pos_i, add: adjDelta)
                        adj_j = rollover(adj_j, add: adjDelta)
                    }

                    sortedBodiesM[i] = adj_i
                    sortedBodiesM[j] = adj_j
                }
            }

            let hardStop = cusp.value
            let nextHardStop = nextCusp.value

            if cusp.value > nextCusp.value {
                let rolloverRange = cusp.value...359.999

                if rolloverRange ~= pos_i {
                    let houseDelta1 = abs(abs(hardStop) - abs(pos_i))
                    let houseDelta2 = abs(abs(hardStop) - abs(pos_j))
                    let delta = houseDelta1 < houseDelta2 ? houseDelta1 : houseDelta2
                    let adj_i: CGFloat
                    let adj_j: CGFloat

                    if delta < 4.0 {
                        adj_i = rollover(hardStop, add: 2.0)
                        adj_j = rollover(hardStop, add: 6.0)
                    } else {
                        adj_i = rollover(pos_i, add: -2.0)
                        adj_j = rollover(pos_j, add: 2.0)
                    }

                    sortedBodiesM[i] = adj_i
                    sortedBodiesM[j] = adj_j
                } else {
                    conventionalAdjustment(startOfHouse: hardStop, endOfHouse: nextHardStop)
                }
            } else {
                conventionalAdjustment(startOfHouse: hardStop, endOfHouse: nextHardStop)
            }
        }

        for (i, j) in adjacentIndexes {
            let pos_i = sortedBodiesM[i]!
            let pos_j = sortedBodiesM[j]!
            let i_cusp = natal.cusp(for: pos_i)
            let j_cusp = natal.cusp(for: pos_j)

            if i_cusp == j_cusp {
                moveBodiesIfCuspsAreSame(i, j, i_cusp)
            }
        }

//        for key in sortedBodiesI.keys {
//            let deg = preciseRound(sortedBodiesI[key]!, precision: .hundredths)
//            print("\(key) = \(deg)")
//        }
//
//        print("\n\n")
//
//        for key in sortedBodiesM.keys {
//            let deg = preciseRound(sortedBodiesM[key]!, precision: .hundredths)
//            print("\(key) = \(deg)")
//        }

        // Produce final sort by Planetary order (Sun --> South Node)
        let finalSortedBodies = sortedBodiesM.sorted {
            $0.key < $1.key
        }.reduce(into: OrderedDictionary<Int, CGFloat>()) { od, element in
            let (index, value) = element
            od[index] = value
        }

        // Return array of Planetary degrees based on Planet order (Sun --> South Node)
        let valuesArray = Array(finalSortedBodies.elements.map { $0.value })

        return valuesArray
    }

    private func getPlanets() -> [CGFloat] {
        guard let chart = chart else {
            return [CGFloat]()
        }

        let natal = chart
        let sunPosition = natal.sun.value
        let moonPosition = natal.moon.value
        let mercuryPosition = natal.mercury.value
        let venusPosition = natal.venus.value
        let marsPosition = natal.mars.value
        let jupiterPosition = natal.jupiter.value
        let saturnPosition = natal.saturn.value
        let uranusPosition = natal.uranus.value
        let neptunePosition = natal.neptune.value
        let plutoPosition = natal.pluto.value

        let southNodePosition = natal.southNode.value
        let northNodePosition = natal.northNode.value
        let chironPosition = natal.chiron.value
        return [
            sunPosition,
            moonPosition,
            mercuryPosition,
            venusPosition,
            marsPosition,
            jupiterPosition,
            saturnPosition,
            uranusPosition,
            neptunePosition,
            plutoPosition,
            southNodePosition,
            northNodePosition,
            chironPosition
        ]
    }

    private func getHouses() -> [CGFloat] {
        guard let chart = chart else {
            return [CGFloat]()
        }

        let houseCusps = chart.houseCusps
        let first = houseCusps.first.value
        let second = houseCusps.second.value
        let third = houseCusps.third.value
        let fourth = houseCusps.fourth.value
        let fifth = houseCusps.fifth.value
        let sixth = houseCusps.sixth.value
        let seventh = houseCusps.seventh.value
        let eighth = houseCusps.eighth.value
        let ninth = houseCusps.ninth.value
        let tenth = houseCusps.tenth.value
        let eleventh = houseCusps.eleventh.value
        let twelfth = houseCusps.twelfth.value
           print("House cusps: \(first), \(second), \(third), \(fourth), \(fifth), \(sixth), \(seventh), \(eighth), \(ninth), \(tenth), \(eleventh), \(twelfth)")

        return [first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth]
    }

    private func getHousesDegree() -> [CGFloat] {
        guard let chart = chart else {
            return [CGFloat]()
        }

        let houseCusps = chart.houseCusps
        let first = houseCusps.first.degree
        let second = houseCusps.second.degree
        let third = houseCusps.third.degree
        let fourth = houseCusps.fourth.degree
        let fifth = houseCusps.fifth.degree
        let sixth = houseCusps.sixth.degree
        let seventh = houseCusps.seventh.degree
        let eighth = houseCusps.eighth.degree
        let ninth = houseCusps.ninth.degree
        let tenth = houseCusps.tenth.degree
        let eleventh = houseCusps.eleventh.degree
        let twelfth = houseCusps.twelfth.degree

        return [first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth]
    }

    private func getHousesMinute() -> [CGFloat] {
        guard let chart = chart else {
            return [CGFloat]()
        }

        let houseCusps = chart.houseCusps
        let first = houseCusps.first.minute
        let second = houseCusps.second.minute
        let third = houseCusps.third.minute
        let fourth = houseCusps.fourth.minute
        let fifth = houseCusps.fifth.minute
        let sixth = houseCusps.sixth.minute
        let seventh = houseCusps.seventh.minute
        let eighth = houseCusps.eighth.minute
        let ninth = houseCusps.ninth.minute
        let tenth = houseCusps.tenth.minute
        let eleventh = houseCusps.eleventh.minute
        let twelfth = houseCusps.twelfth.minute

        return [first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth]
    }

    private func getHouseNames() -> [String] {
        guard let chart = chart else {
            return [String]()
        }

        let houseCusps = chart.houseCusps
        let first = houseCusps.first.sign.keyName
        let second = houseCusps.second.sign.keyName
        let third = houseCusps.third.sign.keyName
        let fourth = houseCusps.fourth.sign.keyName
        let fifth = houseCusps.fifth.sign.keyName
        let sixth = houseCusps.sixth.sign.keyName
        let seventh = houseCusps.seventh.sign.keyName
        let eighth = houseCusps.eighth.sign.keyName
        let ninth = houseCusps.ninth.sign.keyName
        let tenth = houseCusps.tenth.sign.keyName
        let eleventh = houseCusps.eleventh.sign.keyName
        let twelfth = houseCusps.twelfth.sign.keyName

        return [first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth]
    }


    private func getHousesCuspLongitude() -> [CGFloat] {
        guard let chart = chart else {
            return [CGFloat]()
        }

        let houseCusps = chart.houseCusps
        let first = houseCusps.first.value
        let second = houseCusps.second.value
        let third = houseCusps.third.value
        let fourth = houseCusps.fourth.value
        let fifth = houseCusps.fifth.value
        let sixth = houseCusps.sixth.value
        let seventh = houseCusps.seventh.value
        let eighth = houseCusps.eighth.value
        let ninth = houseCusps.ninth.value
        let tenth = houseCusps.tenth.value
        let eleventh = houseCusps.eleventh.value
        let twelfth = houseCusps.twelfth.value

        return [first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth]
    }


    private func getHousesDistances() -> [CGFloat] {
        let houseCusps = getHouses()
        // print("House cusps: \(houseCusps)")

        var houseDistances: [CGFloat] = []

        for i in 0..<houseCusps.count {
            let nextIndex = (i + 1) % houseCusps.count
            let distance = (houseCusps[nextIndex] - houseCusps[i] + 360).truncatingRemainder(dividingBy: 360)
            houseDistances.append(distance)
            //   print("House \(i + 1) to \(nextIndex + 1) distance: \(distance)")

        }

        return houseDistances
    }
}
extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
