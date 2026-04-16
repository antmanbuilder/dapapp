import Foundation
import StoreKit

/// StoreKit 2 — remove ads IAP.
@MainActor
final class StoreService: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInFlight = false
    @Published var lastError: String?

    private let productIDs = [Constants.removeAdsProductID]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchaseRemoveAds() async throws -> Bool {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = products.first else {
            throw StoreError.productUnavailable
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws -> Bool {
        try await AppStore.sync()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Constants.removeAdsProductID {
                return true
            }
        }
        return false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case productUnavailable
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return "Purchase isn’t available right now."
        case .failedVerification: return "Couldn’t verify purchase."
        }
    }
}
