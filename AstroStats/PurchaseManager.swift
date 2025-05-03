import StoreKit
import Foundation

@MainActor
class PurchaseManager: ObservableObject {
    @Published var isPaidUser = false
    @Published var paidVersionProduct: Product?

    private let productID = "com.yourapp.paidversion"

    init() {
        Task {
            await loadProduct()
            await checkPurchaseStatus()
        }
    }

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            paidVersionProduct = products.first
        } catch {
            print("Error loading product: \(error)")
        }
    }

    func purchase() async {
        guard let product = paidVersionProduct else { return }

        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(_) = verification {
                isPaidUser = true
                print("✅ Paid version unlocked.")
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    func checkPurchaseStatus() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == productID {
                isPaidUser = true
                return
            }
        }
        isPaidUser = false
    }
}

import SwiftUI

import SwiftUI

struct ContentView: View {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some View {
        VStack(spacing: 24) {
            if purchaseManager.isPaidUser {
                Text("Paid Version Enabled")
                    .font(.title2)
                    .fontWeight(.bold)

                // Paid features here
                Text("You can save charts, take screenshots, print, and share reports.")
            } else {
                Text("Free Version")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add and view charts, but no saving or sharing features.")

                if let product = purchaseManager.paidVersionProduct {
                    Button("Upgrade to Paid Version – \(product.displayPrice)") {
                        Task {
                            await purchaseManager.purchase()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    ProgressView("Loading Purchase Info...")
                }
            }
        }
        .padding()
    }
}

import SwiftUI

struct ScreenshotDetectionViewModifier: ViewModifier {
    @State private var isCaptured = false
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isCaptured ? 10 : 0)
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                isCaptured = UIScreen.main.isCaptured
            }
    }
}

extension View {
    func detectScreenshot() -> some View {
        self.modifier(ScreenshotDetectionViewModifier())
    }
}
