import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DapPhase: Equatable {
    case idle
    case countdown(Int)
    case go
    case listening
    case result(DapResult)
}

@MainActor
final class DapFlowViewModel: ObservableObject {
    @Published var phase: DapPhase = .idle
    @Published var microphoneDenied = false
    @Published var errorMessage: String?

    let audio = AudioMeterService()
    private let history: DapHistoryStore
    private let sounds = TierSoundService()

    init(history: DapHistoryStore) {
        self.history = history
    }

    func startDapFlow() {
        sounds.playTap()
        // Subtle tactile "click" so the button feels alive alongside the
        // tap sound — fires even if the actual flow is gated below so the
        // press always registers physically.
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        guard phase == .idle else { return }
        // Free users get 3 daps/day. Premium users bypass this entirely.
        guard history.canDap else {
            errorMessage = "You're out of daps for today! Go Premium for unlimited."
            return
        }
        microphoneDenied = false
        errorMessage = nil
        Task { await runFlow() }
    }

    private func runFlow() async {
        if await audio.requestPermission() == false {
            microphoneDenied = true
            phase = .idle
            return
        }

        for n in stride(from: MeasurementConstants.countdownSeconds, through: 1, by: -1) {
            phase = .countdown(n)
            sounds.playTick()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        phase = .go
        sounds.playGo()
        try? await Task.sleep(nanoseconds: 400_000_000)

        phase = .listening
        audio.resetPeak()
        sounds.playDrumroll()
        do {
            let rawDb = try await audio.measurePeakDecibels()
            // Crispness-weighted scoring — a razor-sharp dap is rewarded,
            // a sloppy one is punished at the same raw loudness. Closes
            // the tier ceiling and creates an actual skill gradient.
            let crispness = audio.crispnessMultiplier()
            let peakDb = rawDb * crispness
            let tier = DapTier.tier(for: peakDb)
            let result = DapResult(peakDecibels: peakDb, tier: tier)
            history.record(result)
            phase = .result(result)
            HapticService.play(for: tier)
            sounds.playReveal(for: tier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.sounds.playTierMusic(for: tier)
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .idle
        }
    }

    func resetToIdle() {
        phase = .idle
    }

    func shouldShowInterstitialAfterResult() -> Bool {
        guard !history.adsRemoved else { return false }
        return history.totalDaps > 0 && history.totalDaps % Constants.dapsBetweenInterstitials == 0
    }
}
