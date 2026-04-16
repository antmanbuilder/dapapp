import Foundation

/// Local persistence for stats (UserDefaults).
final class DapHistoryStore: ObservableObject {
    private let defaults: UserDefaults
    private let historyKey = "dapHistory"
    private let totalKey = "totalDaps"
    private let bestKey = "bestDap"
    private let adsRemovedKey = "adsRemoved"

    @Published private(set) var dapHistory: [DapResult] = []
    @Published private(set) var totalDaps: Int = 0
    @Published private(set) var bestDap: DapResult?
    @Published var adsRemoved: Bool = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func load() {
        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([DapResult].self, from: data) {
            dapHistory = decoded
        }
        totalDaps = defaults.integer(forKey: totalKey)
        if let data = defaults.data(forKey: bestKey),
           let best = try? JSONDecoder().decode(DapResult.self, from: data) {
            bestDap = best
        }
        adsRemoved = defaults.bool(forKey: adsRemovedKey)
    }

    func record(_ result: DapResult) {
        totalDaps += 1
        defaults.set(totalDaps, forKey: totalKey)

        var next = [result] + dapHistory
        if next.count > Constants.maxHistoryCount {
            next = Array(next.prefix(Constants.maxHistoryCount))
        }
        dapHistory = next
        if let data = try? JSONEncoder().encode(next) {
            defaults.set(data, forKey: historyKey)
        }

        if bestDap == nil || result.peakDecibels > (bestDap?.peakDecibels ?? 0) {
            bestDap = result
            if let data = try? JSONEncoder().encode(result) {
                defaults.set(data, forKey: bestKey)
            }
        }
    }

    func setAdsRemoved(_ value: Bool) {
        adsRemoved = value
        defaults.set(value, forKey: adsRemovedKey)
    }
}
