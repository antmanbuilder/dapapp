import SwiftUI

struct ResultView: View {
    let result: DapResult
    let onShare: () -> Void
    let onAgain: () -> Void

    @State private var showTitle = false
    @State private var showDB = false
    @State private var showButtons = false
    @State private var showCard = false

    var body: some View {
        ZStack {
            // Layer 1: full-screen tier animation. Sits at the very back of
            // the ZStack and covers everything — status bar, top bar, tab
            // bar, ad banner. Belt-and-suspenders: both `.ignoresSafeArea`
            // variants are applied so the paint extends edge-to-edge even
            // when a parent container (TabView / Group / .overlay-hosting
            // ZStack) tries to constrain it to the safe area. Tier 6
            // handles its own overscan/clip internally for shake.
            TierGraphicView(tier: result.tier)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .all)
                .edgesIgnoringSafeArea(.all)

            // Layer 2: the floating dark-frosted card — Instagram-Stories
            // style. Centered vertically. The backdrop itself fades in at
            // the same moment as the title for the slam effect.
            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Text(result.tier.displayTitle)
                        .font(AppFont.display(size: 32))
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.65), radius: 8, y: 3)
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                        .scaleEffect(showTitle ? 1.0 : 3.0)
                        .opacity(showTitle ? 1 : 0)

                    Text(String(format: "%.1f dB", result.peakDecibels))
                        .font(AppFont.display(size: 26))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                        .scaleEffect(showDB ? 1.0 : 2.0)
                        .opacity(showDB ? 1 : 0)

                    HStack(spacing: 16) {
                        Button(action: onShare) {
                            Text("SHARE")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial)
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
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                    .padding(.top, 4)
                    .offset(y: showButtons ? 0 : 40)
                    .opacity(showButtons ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(result.tier.cardBackdropOpacity))
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.2))
                        )
                        .opacity(showCard ? 1 : 0)
                )
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            // Phase 1 (1.8s): Let the animation breathe, then SLAM the tier
            // title in with a heavy spring + haptic. Starting scale 3.0x
            // makes it feel thrown at the user.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                    showTitle = true
                    showCard = true
                }
                HapticService.play(for: result.tier)
            }
            // Phase 2 (2.3s): dB number slams in, slightly less dramatic.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    showDB = true
                }
            }
            // Phase 3 (2.8s): Buttons slide up from below.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showButtons = true
                }
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
