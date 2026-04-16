import AVFoundation
import Foundation

/// Uses `AVAudioRecorder` metering on watchOS (input tap APIs are limited vs iOS).
final class WatchAudioService: NSObject, ObservableObject {
    @Published var liveMeterLevel: Double = 0

    private var recorder: AVAudioRecorder?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
    }

    /// Peak “display” dB mapped to the same tier scale as iOS (`MeasurementConstants`).
    func measurePeakDisplayDecibels(duration: TimeInterval = MeasurementConstants.listeningDuration) async throws -> Double {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dap-meter.caf")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        recorder?.record()

        let start = Date()
        var peakDisplay = 0.0

        while Date().timeIntervalSince(start) < duration {
            recorder?.updateMeters()
            let p = Double(recorder?.peakPower(forChannel: 0) ?? -160)
            let display = Self.displayDecibels(fromPeakPower: p)
            peakDisplay = max(peakDisplay, display)
            await MainActor.run {
                liveMeterLevel = min(1, max(0, (p + 80) / 80))
            }
            try await Task.sleep(nanoseconds: UInt64(MeasurementConstants.meteringInterval * 1_000_000_000))
        }

        recorder?.stop()
        recorder = nil
        try? session.setActive(false)
        return peakDisplay
    }

    /// Maps `peakPower` (roughly −160…0) to the app’s display scale; tune with iOS field tests.
    private static func displayDecibels(fromPeakPower p: Double) -> Double {
        100 + p
    }
}
