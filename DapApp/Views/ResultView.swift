import SwiftUI

struct ResultView: View {
    let result: DapResult
    let onShare: () -> Void
    let onAgain: () -> Void

    @State private var shake: CGFloat = 0
    @State private var pulse = false

    @State private var showDB = false
    @State private var showTitle = false
    @State private var showGraphic = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                ZStack {
                    Color.clear.frame(height: 250)
                    if showGraphic {
                        TierGraphicView(tier: result.tier)
                            .frame(height: 250)
                            .scaleEffect(pulse && result.tier == .earthquake ? 1.04 : 1.0)
                            .animation(
                                result.tier == .earthquake
                                    ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                                    : .default,
                                value: pulse
                            )
                            .transition(
                                .scale(scale: 0.5).combined(with: .opacity)
                            )
                    }
                }

                Text(result.tier.displayTitle)
                    .font(AppFont.display(size: 28))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    .offset(x: shakeOffset())
                    .opacity(showTitle ? 1 : 0)

                Text(String(format: "%.1f dB", result.peakDecibels))
                    .font(AppFont.display(size: 24))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .opacity(showDB ? 1 : 0)
                    .offset(y: showDB ? 0 : 36)

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
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 44)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Phase 1: dB number slams in (0.3s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    showDB = true
                }
            }
            // Phase 2: Tier title (0.8s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showTitle = true
                }
            }
            // Phase 3: Tier graphic (1.2s) — kick off pulse + shake here too
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.4)) {
                    showGraphic = true
                }
                pulse = true
                runShakeIfNeeded()
            }
            // Phase 4: Buttons (2.0s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showButtons = true
                }
            }
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
