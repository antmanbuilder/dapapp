import SwiftUI
import UIKit

struct ContentView: View {
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
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
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
                .font(.system(size: 36, weight: .heavy, design: .rounded))
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
        VStack(spacing: 24) {
            Text(value)
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 40)
        }
    }

    private func share(result: DapResult) {
        guard let image = ShareImageRenderer.renderCard(result: result) else { return }
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
