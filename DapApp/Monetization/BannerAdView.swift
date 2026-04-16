import SwiftUI

/// Banner slot. Add the [Google Mobile Ads SDK](https://developers.google.com/admob/ios/quick-start) via SPM,
/// then replace this view’s body with a `UIViewRepresentable` wrapping `GADBannerView` (or `BannerView` in newer SDKs).
struct BannerAdView: View {
    init(adUnitID: String, isCollapsed: Bool = false) {
        self.adUnitID = adUnitID
        self.isCollapsed = isCollapsed
    }

    let adUnitID: String
    var isCollapsed: Bool = false

    var body: some View {
        if isCollapsed {
            Color.clear.frame(height: 0)
        } else {
            HStack {
                Spacer()
                Text("Ad")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
        }
    }
}
