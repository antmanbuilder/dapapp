import SwiftUI
import UIKit

/// 1080×1920 export layout for `ImageRenderer`.
struct ShareCardView: View {
    let result: DapResult

    var body: some View {
        ZStack {
            LinearGradient(
                colors: result.tier.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("DAP APP")
                    .font(AppFont.display(size: 40))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.top, 72)

                Spacer(minLength: 80)

                Text(result.tier.emoji)
                    .font(.system(size: 200))

                Text(result.tier.displayTitle)
                    .font(AppFont.display(size: 48))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.top, 32)

                Text(String(format: "%.1f dB", result.peakDecibels))
                    .font(AppFont.display(size: 56))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 20)

                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("dap app")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    if let qr = QRCodeImage.make(from: Constants.appStoreURLString, scale: 6) {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 120, height: 120)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 72)
            }
        }
        .frame(width: Constants.shareCardSize.width, height: Constants.shareCardSize.height)
    }
}
