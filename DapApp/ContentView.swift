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

/// The original dap-flow screen, unchanged in behavior — just moved off the
/// root so `ContentView` can host a tab bar.
struct DapTabView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @EnvironmentObject private var flow: DapFlowViewModel
    @StateObject private var store = StoreService()
    @StateObject private var interstitial = InterstitialAdCoordinator()

    @State private var showRemoveAds = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 8)

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
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: flow.phase)

                Spacer(minLength: 8)

                if !history.adsRemoved {
                    BannerAdView(adUnitID: Constants.bannerAdUnitID, isCollapsed: history.adsRemoved)
                }
            }
        }
        .onAppear {
            interstitial.preload()
            Task { await store.loadProducts() }
        }
        .sheet(isPresented: $showRemoveAds) {
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
        .alert("Something went wrong", isPresented: Binding(
            get: { flow.errorMessage != nil },
            set: { if !$0 { flow.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
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
                Button("Remove Ads") { showRemoveAds = true }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x30D158))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var idleContent: some View {
        VStack(spacing: 28) {
            Text("DAP APP")
                .font(AppFont.display(size: 44))
                .foregroundStyle(.white)

            DapButton(title: "DAP IT") {
                flow.startDapFlow()
            }

            Text("Tap. Dap. Get rated.")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(.bottom, 24)
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
        let card = ShareCardView(result: result, streak: history.currentStreak)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0
        guard let image = renderer.uiImage else { return }
        shareItems = [image]
        showShareSheet = true
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }
}

#Preview {
    ContentView()
        .environmentObject(DapHistoryStore())
        .environmentObject(DapFlowViewModel(history: DapHistoryStore()))
}
