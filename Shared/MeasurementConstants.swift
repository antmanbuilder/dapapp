import Foundation

/// Shared between iOS and watchOS — tune dB tiers on real hardware.
enum MeasurementConstants {
    static let listeningDuration: TimeInterval = 3.0
    static let meteringInterval: TimeInterval = 0.05
    static let countdownSeconds: Int = 3

    // TUNING: Adjust dbDisplayOffset after real-device testing.
    // Quiet room = 25-35 display dB
    // Normal clap = 55-70
    // Solid dap = 70-85
    // LOUD dap = 95-105+
    static let dbDisplayOffset: Double = 110.0
    static let minimumLinearPeak: Double = 1e-7

    // WIDER tier spread — makes progression feel earned
    static let tier1Max: Double = 40.0   // "Did you even touch?"
    static let tier2Max: Double = 55.0   // "Weak sauce"
    static let tier3Max: Double = 70.0   // "Respectable"
    static let tier4Max: Double = 85.0   // "That boy CRISPY"
    static let tier5Max: Double = 100.0  // "Certified Thunderclap"
    // 100+ = "Registered as an earthquake" — should be rare
}
