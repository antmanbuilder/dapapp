import SwiftUI
import UIKit

/// Presents a placeholder full-screen “ad” every N daps. Swap in Google interstitial APIs after adding the AdMob SDK.
@MainActor
final class InterstitialAdCoordinator: ObservableObject {
    @Published var showPlaceholder = false

    func preload() {}

    func present(from windowScene: UIWindowScene?) {
        showPlaceholder = true
    }
}
