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

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func resetPeak() {
        lock.lock()
        peakLinear = 0
        lock.unlock()
        DispatchQueue.main.async {
            self.liveLinearPeak = 0
        }
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
            let linear = buffer.peakLinearAmplitude()
            self?.lock.lock()
            self?.peakLinear = max(self?.peakLinear ?? 0, linear)
            self?.lock.unlock()
            DispatchQueue.main.async {
                self?.liveLinearPeak = max(self?.liveLinearPeak ?? 0, linear)
            }
        }

        try engine.start()

        let start = Date()
        while Date().timeIntervalSince(start) < duration {
            try await Task.sleep(nanoseconds: UInt64(MeasurementConstants.meteringInterval * 1_000_000_000))
        }

        engine.stop()
        input.removeTap(onBus: 0)
        try? session.setActive(false, options: [])

        let peak = currentPeakLinear()
        return peak.displayDecibelsFromLinearPeak()
    }
}
