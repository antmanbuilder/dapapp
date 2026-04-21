import Foundation
import SwiftUI

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
        guard phase == .idle else { return }
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
            let peakDb = try await audio.measurePeakDecibels()
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
