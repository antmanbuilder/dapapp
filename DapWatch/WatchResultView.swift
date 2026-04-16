import SwiftUI

struct WatchResultView: View {
    let result: DapResult
    let onAgain: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(result.tier.emoji)
                .font(.system(size: 44))

            Text(result.tier.displayTitle)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            Text(String(format: "%.0f dB", result.peakDecibels))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)

            Button("Again", action: onAgain)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x30D158))
        }
        .padding(.horizontal, 4)
    }
}
