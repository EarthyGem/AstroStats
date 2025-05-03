//
//  ExportManager.swift
//  AstroStats
//
//  Created by Errick Williams on 5/2/25.
//


import SwiftUI
import PDFKit

class ExportManager {
    func exportToPDF(view: UIView) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: view.bounds)
        return pdfRenderer.pdfData { context in
            context.beginPage()
            view.layer.render(in: context.cgContext)
        }
    }
}
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
struct ReportView: View {
    @State private var showShareSheet = false
    let exportManager = ExportManager()
    
    var body: some View {
        VStack {
            // Your report content
            Text("Astrology Report")
            
            Button("Export & Share") {
                if let window = UIApplication.shared.windows.first,
                   let pdfData = exportManager.exportToPDF(view: window) {
                    let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
                }
            }
        }
    }
}
