import Foundation

public struct DapResult: Identifiable, Codable, Equatable {
    public let id: UUID
    public let peakDecibels: Double
    public let tier: DapTier
    public let timestamp: Date

    public init(id: UUID = UUID(), peakDecibels: Double, tier: DapTier, timestamp: Date = Date()) {
        self.id = id
        self.peakDecibels = peakDecibels
        self.tier = tier
        self.timestamp = timestamp
    }
}
