import SwiftUI
import UIKit

/// 1080×1920 premium "trading-card" share layout for Instagram Stories.
/// Fully static — no animations, no TimelineView, no time-based Canvas —
/// so it renders deterministically through `ImageRenderer` in one pass.
struct ShareCardView: View {
    let result: DapResult
    var streak: Int = 0

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private var dateString: String {
        Self.dateFormatter.string(from: Date())
    }

    private var dBString: String {
        String(format: "%.1f", result.peakDecibels)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: result.tier.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle corner vignette for depth
            RadialGradient(
                colors: [.clear, .black.opacity(0.35)],
                center: .center,
                startRadius: 480,
                endRadius: 1300
            )

            VStack(spacing: 0) {
                // 1. DAP APP branding
                Text("DAP APP")
                    .font(AppFont.display(size: 28))
                    .tracking(6)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 96)

                Spacer(minLength: 0)

                // 2. Emoji — large, above the dB number
                Text(result.tier.emoji)
                    .font(.system(size: 80))
                    .padding(.bottom, 36)

                // 3+4. HERO dB number with "dB" label beside it (baseline-aligned)
                HStack(alignment: .lastTextBaseline, spacing: 14) {
                    Text(dBString)
                        .font(AppFont.display(size: 120))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("dB")
                        .font(AppFont.display(size: 40))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 48)

                // 5. Tier title
                Text(result.tier.displayTitle)
                    .font(AppFont.display(size: 44))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    .padding(.horizontal, 72)
                    .padding(.top, 32)

                Spacer(minLength: 0)

                // 7. Divider
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal, 80)
                    .padding(.bottom, 32)

                // 8+9. Bottom: date (+ streak) on left, QR on right
                HStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(dateString)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        if streak > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color(hex: 0xFF6B35))
                                Text("\(streak) day streak")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.92))
                            }
                        }
                    }

                    Spacer()

                    if let qr = QRCodeImage.make(from: Constants.appStoreURLString, scale: 4) {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .padding(6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 72)
            }
        }
        .frame(width: Constants.shareCardSize.width, height: Constants.shareCardSize.height)
        .clipped()
    }
}

#Preview {
    ShareCardView(
        result: DapResult(peakDecibels: 87.3, tier: .thunderclap),
        streak: 7
    )
    .scaleEffect(0.25)
}
