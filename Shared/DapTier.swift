import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

    #if canImport(UIKit)
    public var uiColor: UIColor {
        switch self {
        case .didYouEvenTouch: return UIColor(red: 0x3A/255, green: 0x3A/255, blue: 0x3C/255, alpha: 1)
        case .weakSauce: return UIColor(red: 0x8B/255, green: 0x73/255, blue: 0x55/255, alpha: 1)
        case .respectable: return UIColor(red: 0x00/255, green: 0x7A/255, blue: 0xFF/255, alpha: 1)
        case .crispy: return UIColor(red: 0xFF/255, green: 0x6B/255, blue: 0x35/255, alpha: 1)
        case .thunderclap: return UIColor(red: 0x6C/255, green: 0x5C/255, blue: 0xE7/255, alpha: 1)
        case .earthquake: return UIColor(red: 0xFF/255, green: 0x2D/255, blue: 0x55/255, alpha: 1)
        }
    }
    #endif

    /// Opacity for the dark frosted card that sits behind the result text.
    /// Quiet tiers need very little backdrop; loud tiers need more contrast
    /// so the title/dB stay readable on top of the intense animation.
    public var cardBackdropOpacity: Double {
        switch self {
        case .didYouEvenTouch, .weakSauce: return 0.3
        case .respectable, .crispy: return 0.4
        case .thunderclap, .earthquake: return 0.5
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
