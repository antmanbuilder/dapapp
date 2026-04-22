import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @EnvironmentObject private var flow: DapFlowViewModel

    init() {
        // Dark-themed tab bar that matches the app background
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.45)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.45)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0x30 / 255.0, green: 0xD1 / 255.0, blue: 0x58 / 255.0, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0x30 / 255.0, green: 0xD1 / 255.0, blue: 0x58 / 255.0, alpha: 1.0)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            DapTabView()
                .tabItem {
                    Label("Dap", systemImage: "waveform")
                }

            LeaderboardView()
                .tabItem {
                    Label("Board", systemImage: "trophy.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color(hex: 0x30D158))
        .fullScreenCover(isPresented: Binding(
            get: { !history.hasUsername },
            set: { _ in }
        )) {
            UsernameOnboardingView()
                .environmentObject(history)
        }
    }
}

/// The original dap-flow screen. Owns its own share sheet so the result
/// screen's SHARE button can present it directly — the Board tab has its
/// own independent share sheet for invites.
struct DapTabView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @EnvironmentObject private var flow: DapFlowViewModel
    @StateObject private var store = StoreService()
    @StateObject private var interstitial = InterstitialAdCoordinator()

    @State private var showRemoveAds = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    // Tracks when the user navigated away from the Dap tab so we can reset
    // back to the idle screen if they return after a brief detour.
    @State private var leftAt: Date? = nil

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            // Layer 1: phase content fills the entire screen so the result
            // animation can extend edge-to-edge behind the floating top bar
            // and banner ad. Idle / countdown / listening all center their
            // own content, so they look correct in a full-screen slot too.
            Group {
                switch flow.phase {
                case .idle:
                    idleContent
                case .countdown(let n):
                    countdownContent(value: "\(n)")
                case .go:
                    countdownContent(value: "GO")
                case .listening:
                    ListeningView(audio: flow.audio)
                case .result(let result):
                    ResultView(
                        result: result,
                        onShare: { share(result: result) },
                        onAgain: {
                            let showAd = flow.shouldShowInterstitialAfterResult()
                            flow.resetToIdle()
                            if showAd {
                                interstitial.present(from: activeWindowScene())
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: flow.phase)

            // Layer 2: banner ad pinned to the bottom. Wrapped in a VStack
            // with an aligned Spacer so taps above it still reach the
            // content behind.
            if !history.adsRemoved {
                VStack(spacing: 0) {
                    Spacer()
                    BannerAdView(adUnitID: Constants.bannerAdUnitID, isCollapsed: history.adsRemoved)
                }
            }
        }
        // Layer 3: the floating top bar. Uses an overlay so it only claims
        // as much vertical space as it actually renders — the animation can
        // bleed behind it, and the empty area below the bar doesn't absorb
        // taps. Frosted background = subtle tier-color bleed-through.
        .overlay(alignment: .top) {
            VStack(spacing: 0) {
                topBar
                    .background(
                        Color(hex: 0x1C1C1E).opacity(0.7)
                    )
                    .background(.ultraThinMaterial.opacity(0.3))

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
        .onAppear {
            interstitial.preload()
            Task { await store.loadProducts() }
            // If the user has been away from this tab for 2+ seconds, drop
            // them back on the idle screen instead of the last result so
            // the Dap tab always feels "fresh" when they come back to it.
            if let leftAt = leftAt, Date().timeIntervalSince(leftAt) > 2.0 {
                flow.resetToIdle()
            }
            leftAt = nil
        }
        .onDisappear {
            leftAt = Date()
        }
        .fullScreenCover(isPresented: $showRemoveAds) {
            RemoveAdsView(store: store, history: history)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
        }
        .alert("Microphone", isPresented: Binding(
            get: { flow.microphoneDenied },
            set: { if !$0 { flow.microphoneDenied = false } }
        )) {
            Button("OK", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("\(Constants.microphoneUsageDescription) You can turn it on in Settings.")
        }
        .alert("Out of daps 😤", isPresented: Binding(
            get: { flow.errorMessage != nil },
            set: { if !$0 { flow.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
            // Reuses the existing `showRemoveAds` state which already has
            // a fullScreenCover wired to the premium paywall — no reason
            // to introduce a parallel flag for the same destination.
            Button("Go Premium ✦") {
                showRemoveAds = true
            }
        } message: {
            Text(flow.errorMessage ?? "")
        }
        .sheet(isPresented: $interstitial.showPlaceholder) {
            VStack(spacing: 16) {
                Text("Interstitial (test)")
                    .font(.headline)
                Text("Replace InterstitialAdCoordinator with Google Mobile Ads after adding the SDK.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Close") { interstitial.showPlaceholder = false }
            }
            .padding()
        }
    }

    private var topBar: some View {
        HStack {
            Text("DAP APP")
                .font(AppFont.display(size: 22))
                .foregroundStyle(.white)
            if history.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(hex: 0xFF6B35))
                        .font(.system(size: 14))
                    Text("\(history.currentStreak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFF6B35))
                }
            }
            Spacer()
            if !history.adsRemoved {
                Button("✦ Premium") { showRemoveAds = true }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x30D158))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var idleContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("DAP APP")
                    .font(AppFont.display(size: 44))
                    .foregroundStyle(.white)

                // Radar-ping rings behind the button add ambient life — they
                // expand slowly outward on a staggered loop so the idle
                // screen never feels static.
                ZStack {
                    IdlePulseRings()
                    DapButton(title: "DAP IT") {
                        flow.startDapFlow()
                    }
                }

                VStack(spacing: 6) {
                    Text("Tap. Dap. Get rated.")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.65))

                    // Free-tier counter — goes red on the last dap so the
                    // user knows they're about to bump into the paywall.
                    if !history.adsRemoved {
                        Text("\(history.dapsRemaining) free daps left today")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                history.dapsRemaining <= 1
                                    ? Color(hex: 0xFF3B30)
                                    : Color(hex: 0x30D158)
                            )
                    }
                }
            }

            Spacer()

            // Personal best only shows once the user has at least one dap —
            // avoids showing "0.0 dB" on first launch.
            VStack(spacing: 10) {
                if let best = history.bestDap {
                    Text(String(format: "🏆 Personal Best: %.1f dB", best.peakDecibels))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                idleStatsRow
            }
            // Extra bottom padding when ads are visible so the stats row
            // clears the banner that floats above the tab bar.
            .padding(.bottom, history.adsRemoved ? 24 : 72)
        }
    }

    private var idleStatsRow: some View {
        let best = history.bestDap?.peakDecibels ?? 0
        return HStack(spacing: 10) {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                Text("\(history.currentStreak) streak")
            }
            Text("•")
            Text("\(history.totalDaps) daps")
            Text("•")
            Text(String(format: "Best: %.1f dB", best))
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.35))
    }

    private func countdownContent(value: String) -> some View {
        Text(value)
            .font(AppFont.display(size: 120))
            .foregroundStyle(.white)
            .scaleEffect(1.3)
            .transition(.asymmetric(
                insertion: .scale(scale: 2.0).combined(with: .opacity),
                removal: .scale(scale: 0.5).combined(with: .opacity)
            ))
            .id(value)
    }

    @MainActor
    private func share(result: DapResult) {
        print("=== SHARE DEBUG ===")
        print("Username: \(history.username ?? "nil")")
        print("Streak: \(history.currentStreak)")
        print("Result: \(result.peakDecibels) dB, tier: \(result.tier)")

        let testImage = ShareImageRenderer.renderCard(result: result, username: history.username ?? "test", streak: history.currentStreak)
        print("Image result: \(testImage == nil ? "NIL" : "OK \(testImage!.size)")")

        if let img = testImage {
            print("Image size: \(img.size), scale: \(img.scale)")
        }
        print("=== END DEBUG ===")

        let username = history.username ?? "someone"
        let streakCount = history.currentStreak

        if let image = ShareImageRenderer.renderCard(
            result: result,
            username: username,
            streak: streakCount
        ) {
            let text = "I just hit \(String(format: "%.1f", result.peakDecibels)) dB on Dap App! \(result.tier.emoji) Can you beat me? Add me: @\(username)"
            shareItems = [image, text] as [Any]
        } else {
            let text = "I just hit \(result.tier.displayTitle) (\(String(format: "%.1f", result.peakDecibels)) dB) on Dap App! \(result.tier.emoji) Can you beat me? Add me: @\(username)"
            shareItems = [text] as [Any]
        }
        // Defer the sheet presentation by one run loop so `shareItems` is fully
        // committed before SwiftUI reads it — avoids the "have to tap twice"
        // bug caused by the sheet flipping true in the same state-write batch.
        DispatchQueue.main.async {
            self.showShareSheet = true
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }
}

/// Three faint green circles that expand outward on a staggered loop,
/// giving the idle DAP IT button a gentle radar-ping halo. Each ring starts
/// small (scale 0.5, hidden behind the button) and grows to 1.5 while
/// fading out — the staggered delay means there's always one ring visible.
private struct IdlePulseRings: View {
    @State private var scale0: CGFloat = 0.5
    @State private var scale1: CGFloat = 0.5
    @State private var scale2: CGFloat = 0.5
    @State private var opacity0: Double = 0
    @State private var opacity1: Double = 0
    @State private var opacity2: Double = 0

    var body: some View {
        ZStack {
            ring(scale: scale0, opacity: opacity0)
            ring(scale: scale1, opacity: opacity1)
            ring(scale: scale2, opacity: opacity2)
        }
        .frame(width: 300, height: 300)
        .allowsHitTesting(false)
        .onAppear {
            pulse(delay: 0.0) { s, o in scale0 = s; opacity0 = o }
            pulse(delay: 0.8) { s, o in scale1 = s; opacity1 = o }
            pulse(delay: 1.6) { s, o in scale2 = s; opacity2 = o }
        }
    }

    private func ring(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .stroke(Color(hex: 0x30D158).opacity(opacity), lineWidth: 2)
            .frame(width: 300, height: 300)
            .scaleEffect(scale)
    }

    private func pulse(delay: Double, apply: @escaping (CGFloat, Double) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            apply(0.5, 0.15)
            withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false)) {
                apply(1.5, 0)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DapHistoryStore())
        .environmentObject(DapFlowViewModel(history: DapHistoryStore()))
}
