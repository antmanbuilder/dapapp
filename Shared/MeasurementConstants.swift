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

    // Thresholds are calibrated against CRISPNESS-weighted dB
    // (`rawDb * crispnessMultiplier`), not raw SPL. Raw claps land 80-115,
    // crispness is 0.65-1.05, so effective scores span ~52-120.
    // Reaching Tier 6 now requires the dap be BOTH loud AND crispy.
    static let tier1Max: Double = 55.0   // "Did you even touch?" — barely registered
    static let tier2Max: Double = 65.0   // "Weak sauce" — sloppy or very quiet
    static let tier3Max: Double = 75.0   // "Respectable" — decent dap
    static let tier4Max: Double = 85.0   // "That boy CRISPY" — clean and solid
    static let tier5Max: Double = 98.0   // "Certified Thunderclap" — impressive
    // 98+ = "Registered as an earthquake" — loud AND crispy, rare by design
}
