//
//  AstrologyPDFGenerator.swift
//  AstroStats
//
//  Created by Errick Williams on 5/2/25.
//


import UIKit
import PDFKit

struct AstrologyPDFGenerator {
    static func generatePDF(for person: Person, chartImage: UIImage) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Lila Astrology",
            kCGPDFContextAuthor: "Lila Labs",
            kCGPDFContextTitle: "\(person.name)'s Astrology Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 612.0
        let pageHeight = 792.0
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.systemIndigo
            ]

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ]

            // Draw title
            let title = "\(person.name)'s Natal Chart"
            title.draw(at: CGPoint(x: 72, y: 48), withAttributes: titleAttributes)

            // Birth data
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            let birthInfo = "\(dateFormatter.string(from: person.birthDate))\n\(person.birthPlace)\n\(String(format: "%.2f", person.latitude))°, \(String(format: "%.2f", person.longitude))°"
            birthInfo.draw(at: CGPoint(x: 72, y: 90), withAttributes: subtitleAttributes)

            // Chart image
            let imageRect = CGRect(x: 72, y: 140, width: 468, height: 468)
            chartImage.draw(in: imageRect)

            // Key stats
            var y = imageRect.maxY + 20
            let lineHeight: CGFloat = 22

            let keyStats = [
                "☉ Sun Sign: \(person.sunSign ?? "Unknown")",
                "☽ Moon Sign: \(person.moonSign ?? "Unknown")",
                "↑ Ascendant: \(person.ascendantSign ?? "Unknown")",
                "⚡️ Strongest Planet: \(person.strongestPlanet ?? "Unknown")",
                "🔥 Strongest Sign: \(person.strongestSign ?? "Unknown")",
                "🏠 Strongest House: \(person.strongestHouse?.replacingOccurrences(of: "House ", with: "") ?? "Unknown")"
            ]

            for stat in keyStats {
                stat.draw(at: CGPoint(x: 72, y: y), withAttributes: subtitleAttributes)
                y += lineHeight
            }
        }

        return data
    }
}
