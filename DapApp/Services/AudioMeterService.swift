import AVFoundation
import Combine
import Foundation

enum AudioMeterError: LocalizedError {
    case permissionDenied
    case engineFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access is off. Enable it in Settings → Dap App → Microphone."
        case .engineFailed(let message):
            return message
        }
    }
}

/// Measures peak level using `AVAudioEngine` tap — audio is not recorded.
final class AudioMeterService: NSObject, ObservableObject {
    @Published private(set) var liveLinearPeak: Double = 0

    private let engine = AVAudioEngine()
    private var peakLinear: Double = 0
    private let lock = NSLock()

    // Attack-detection state. All reads/writes must happen under `lock`
    // because they're touched from the real-time audio tap thread.
    private var attackStartTime: Date? = nil
    private var attackPeakTime: Date? = nil
    private var attackDetected: Bool = false
    private var noiseFloor: Double = 0

    /// Linear amplitude above which we declare "the dap has started". Tune
    /// on-device — 0.05 is ~-26 dBFS, well above ambient room noise.
    private let attackThreshold: Double = 0.05

    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func resetPeak() {
        lock.lock()
        peakLinear = 0
        attackStartTime = nil
        attackPeakTime = nil
        attackDetected = false
        noiseFloor = 0
        lock.unlock()
        DispatchQueue.main.async {
            self.liveLinearPeak = 0
        }
    }

    /// Time between first above-threshold sample and the sample at which
    /// the measured peak was reached, in milliseconds. Falls back to a
    /// middle-of-the-road 50ms if attack wasn't detected cleanly.
    func attackDurationMs() -> Double {
        lock.lock()
        let start = attackStartTime
        let peakTime = attackPeakTime
        lock.unlock()
        guard let start = start, let peakTime = peakTime else {
            return 50.0
        }
        return max(1.0, peakTime.timeIntervalSince(start) * 1000.0)
    }

    /// Maps attack duration to a crispness multiplier. Crisper attacks
    /// boost the effective dB; sloppy builds pull it down, so two daps at
    /// the same loudness can land in wildly different tiers.
    func crispnessMultiplier() -> Double {
        let attackMs = attackDurationMs()
        if attackMs < 5 { return 1.05 }
        if attackMs < 15 { return 1.0 }
        if attackMs < 30 { return 0.85 }
        if attackMs < 50 { return 0.75 }
        return 0.65
    }

    func currentPeakLinear() -> Double {
        lock.lock()
        let v = peakLinear
        lock.unlock()
        return v
    }

    /// Runs for `duration` seconds. Updates `liveLinearPeak` during capture. Returns peak display dB.
    func measurePeakDecibels(duration: TimeInterval = MeasurementConstants.listeningDuration) async throws -> Double {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: [])

        resetPeak()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let linear = buffer.peakLinearAmplitude()

            // One lock span covers both peak tracking and attack detection
            // so the two stay consistent with each other.
            self.lock.lock()
            // Mark the start of the dap the first time we punch above the
            // noise floor. Everything before this is ambient room hum.
            if linear > self.attackThreshold && !self.attackDetected {
                self.attackStartTime = Date()
                self.attackDetected = true
            }
            // Every time we observe a new maximum, restamp the peak time.
            // The final value is the timestamp of the loudest sample we
            // ever saw — the true peak of the attack envelope.
            if self.attackDetected && linear > self.peakLinear {
                self.attackPeakTime = Date()
            }
            self.peakLinear = max(self.peakLinear, linear)
            self.lock.unlock()

            DispatchQueue.main.async {
                self.liveLinearPeak = max(self.liveLinearPeak, linear)
            }
        }

        defer {
            engine.stop()
            input.removeTap(onBus: 0)
            try? session.setActive(false, options: [])
        }

        try engine.start()

        let start = Date()
        while Date().timeIntervalSince(start) < duration {
            try await Task.sleep(nanoseconds: UInt64(MeasurementConstants.meteringInterval * 1_000_000_000))
        }

        let peak = currentPeakLinear()
        return peak.displayDecibelsFromLinearPeak()
    }
}
