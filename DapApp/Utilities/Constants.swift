import SwiftUI

enum Constants {
    /// Share card pixel size (Instagram Story).
    static let shareCardSize = CGSize(width: 1080, height: 1920)

    /// Mic usage string (also set in Info.plist).
    static let microphoneUsageDescription = "Dap App needs your mic to measure your dap"

    // MARK: - Ads (replace with real AdMob unit IDs)

    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Google test banner
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Google test interstitial
    static let dapsBetweenInterstitials = 5

    // MARK: - IAP

    static let removeAdsProductID = "com.dapapp.removeads"

    // MARK: - App Store (QR on share card)

    static let appStoreURLString = "https://apps.apple.com/app/id0000000000"

    // MARK: - History

    static let maxHistoryCount = 50
}
