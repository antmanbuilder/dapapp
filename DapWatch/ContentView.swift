import SwiftUI

private enum WatchPhase: Equatable {
    case idle
    case countdown(Int)
    case go
    case listening
    case result(DapResult)
}

struct ContentView: View {
    @StateObject private var audio = WatchAudioService()
    @State private var phase: WatchPhase = .idle
    @State private var micDenied = false

    var body: some View {
        Group {
            switch phase {
            case .idle:
                idle
            case .countdown(let n):
                Text("\(n)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
            case .go:
                Text("GO")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
            case .listening:
                listening
            case .result(let result):
                WatchResultView(result: result) {
                    phase = .idle
                }
            }
        }
        .background(Color(hex: 0x1C1C1E))
        .alert("Microphone", isPresented: $micDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn on the mic for Dap App in Settings on your iPhone (Watch app).")
        }
    }

    private var idle: some View {
        VStack(spacing: 8) {
            Text("DAP APP")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
            Button("DAP IT") {
                Task { await startFlow() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x30D158))
        }
    }

    private var listening: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hex: 0x30D158).opacity(0.25 + audio.liveMeterLevel * 0.55))
                .frame(width: 80 + CGFloat(audio.liveMeterLevel * 40), height: 80 + CGFloat(audio.liveMeterLevel * 40))
                .animation(.easeOut(duration: 0.08), value: audio.liveMeterLevel)
            Text("Listening…")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func startFlow() async {
        guard await audio.requestPermission() else {
            micDenied = true
            return
        }
        for n in stride(from: MeasurementConstants.countdownSeconds, through: 1, by: -1) {
            phase = .countdown(n)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        phase = .go
        try? await Task.sleep(nanoseconds: 400_000_000)
        phase = .listening
        do {
            let db = try await audio.measurePeakDisplayDecibels()
            let tier = DapTier.tier(for: db)
            let result = DapResult(peakDecibels: db, tier: tier)
            phase = .result(result)
            WatchHaptics.play(for: tier)
        } catch {
            phase = .idle
        }
    }
}

#Preview {
    ContentView()
}
