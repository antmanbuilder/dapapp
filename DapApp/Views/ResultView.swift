import SwiftUI

struct ResultView: View {
    let result: DapResult
    let onShare: () -> Void
    let onAgain: () -> Void

    @State private var shake: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            TierAnimationView(tier: result.tier)
                .blur(radius: result.tier == .didYouEvenTouch ? 8 : 0)

            VStack(spacing: 18) {
                Text(result.tier.emoji)
                    .font(.system(size: 88))
                    .scaleEffect(pulse && result.tier == .earthquake ? 1.08 : 1.0)
                    .animation(
                        result.tier == .earthquake
                            ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                            : .default,
                        value: pulse
                    )

                Text(result.tier.displayTitle)
                    .font(AppFont.display(size: 28))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    .offset(x: shakeOffset())

                Text(String(format: "%.1f dB", result.peakDecibels))
                    .font(AppFont.display(size: 24))
                    .foregroundStyle(Color.white.opacity(0.75))

                HStack(spacing: 16) {
                    Button(action: onShare) {
                        Text("SHARE")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onAgain) {
                        Text("DAP AGAIN")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: 0x30D158))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            pulse = true
            runShakeIfNeeded()
        }
    }

    private func shakeOffset() -> CGFloat {
        switch result.tier {
        case .crispy: return sin(shake * .pi) * 5
        case .thunderclap: return sin(shake * .pi * 2) * 10
        case .earthquake: return sin(shake * .pi * 3) * 14
        default: return 0
        }
    }

    private func runShakeIfNeeded() {
        guard result.tier.rawValue >= 4 else { return }
        Task {
            for f in 0..<30 {
                await MainActor.run {
                    shake = CGFloat(f) / 10.0
                }
                try? await Task.sleep(nanoseconds: 28_000_000)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        ResultView(
            result: DapResult(peakDecibels: 87.3, tier: .thunderclap),
            onShare: {},
            onAgain: {}
        )
    }
}
