import SwiftUI

public enum DapTier: Int, CaseIterable, Codable {
    case didYouEvenTouch = 1
    case weakSauce = 2
    case respectable = 3
    case crispy = 4
    case thunderclap = 5
    case earthquake = 6

    public var label: String {
        switch self {
        case .didYouEvenTouch: return "Did you even touch?"
        case .weakSauce: return "Weak sauce"
        case .respectable: return "Respectable"
        case .crispy: return "That boy CRISPY"
        case .thunderclap: return "Certified Thunderclap"
        case .earthquake: return "Registered as an earthquake"
        }
    }

    public var displayTitle: String {
        label.uppercased()
    }

    public var emoji: String {
        switch self {
        case .didYouEvenTouch: return "🫥"
        case .weakSauce: return "😐"
        case .respectable: return "🤝"
        case .crispy: return "🔥"
        case .thunderclap: return "💥"
        case .earthquake: return "🌋"
        }
    }

    public var color: Color {
        switch self {
        case .didYouEvenTouch: return Color(hex: 0x3A3A3C)
        case .weakSauce: return Color(hex: 0x8B7355)
        case .respectable: return Color(hex: 0x007AFF)
        case .crispy: return Color(hex: 0xFF6B35)
        case .thunderclap: return Color(hex: 0x6C5CE7)
        case .earthquake: return Color(hex: 0xFF2D55)
        }
    }

    public var gradientColors: [Color] {
        switch self {
        case .didYouEvenTouch:
            return [Color(hex: 0x1C1C1E), Color(hex: 0x2C2C2E)]
        case .weakSauce:
            return [Color(hex: 0x8B7355), Color(hex: 0x5C4A32)]
        case .respectable:
            return [Color(hex: 0x007AFF), Color(hex: 0x0051D5)]
        case .crispy:
            return [Color(hex: 0xFF6B35), Color(hex: 0xFF3B30)]
        case .thunderclap:
            return [Color(hex: 0x6C5CE7), Color(hex: 0x3B2EBF)]
        case .earthquake:
            return [Color(hex: 0xFF2D55), Color(hex: 0xFFD700)]
        }
    }

    public static func tier(for displayDecibels: Double) -> DapTier {
        if displayDecibels < MeasurementConstants.tier1Max { return .didYouEvenTouch }
        if displayDecibels < MeasurementConstants.tier2Max { return .weakSauce }
        if displayDecibels < MeasurementConstants.tier3Max { return .respectable }
        if displayDecibels < MeasurementConstants.tier4Max { return .crispy }
        if displayDecibels < MeasurementConstants.tier5Max { return .thunderclap }
        return .earthquake
    }
}
