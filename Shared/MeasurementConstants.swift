import Foundation

/// Shared between iOS and watchOS — tune dB tiers on real hardware.
enum MeasurementConstants {
    static let listeningDuration: TimeInterval = 3.0
    static let meteringInterval: TimeInterval = 0.05
    static let countdownSeconds: Int = 3
    static let dbDisplayOffset: Double = 100.0
    static let minimumLinearPeak: Double = 1e-7

    static let tier1Max: Double = 50.0
    static let tier2Max: Double = 60.0
    static let tier3Max: Double = 70.0
    static let tier4Max: Double = 80.0
    static let tier5Max: Double = 90.0
}
