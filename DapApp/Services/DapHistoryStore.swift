import Foundation

/// Local persistence for stats (UserDefaults).
final class DapHistoryStore: ObservableObject {
    private let defaults: UserDefaults
    private let historyKey = "dapHistory"
    private let totalKey = "totalDaps"
    private let bestKey = "bestDap"
    private let adsRemovedKey = "adsRemoved"
    private let lastDapDateKey = "lastDapDate"
    private let currentStreakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"
    private let userIdKey = "userId"
    private let usernameKey = "username"

    @Published private(set) var dapHistory: [DapResult] = []
    @Published private(set) var totalDaps: Int = 0
    @Published private(set) var bestDap: DapResult?
    @Published var adsRemoved: Bool = false
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var userId: UUID?
    @Published private(set) var username: String?

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
        currentStreak = defaults.integer(forKey: currentStreakKey)
        longestStreak = defaults.integer(forKey: longestStreakKey)
        if let idString = defaults.string(forKey: userIdKey),
           let uuid = UUID(uuidString: idString) {
            userId = uuid
        }
        username = defaults.string(forKey: usernameKey)
        checkStreakOnLaunch()
    }

    /// Persist the identity produced by the onboarding flow.
    func setUserIdentity(userId: UUID, username: String) {
        self.userId = userId
        self.username = username
        defaults.set(userId.uuidString, forKey: userIdKey)
        defaults.set(username, forKey: usernameKey)
    }

    var hasUsername: Bool {
        userId != nil && (username?.isEmpty == false)
    }

    func checkStreakOnLaunch() {
        guard let lastDate = defaults.object(forKey: lastDapDateKey) as? Date else { return }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastDate),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        if daysSince > 1 {
            currentStreak = 0
            defaults.set(0, forKey: currentStreakKey)
        }
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = defaults.object(forKey: lastDapDateKey) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysSince == 0 {
                return
            } else if daysSince == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
            defaults.set(longestStreak, forKey: longestStreakKey)
        }

        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(Date(), forKey: lastDapDateKey)
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

        updateStreak()
        pushScoreToLeaderboard()
    }

    /// Fire-and-forget push to Supabase. Silent failure — the core flow must
    /// keep working fully offline, so this is wrapped in a detached task and
    /// `SupabaseService.updateScore` already absorbs any error internally.
    private func pushScoreToLeaderboard() {
        guard let userId else { return }
        let best = bestDap?.peakDecibels ?? 0
        let total = totalDaps
        let streak = currentStreak
        Task { @MainActor in
            await SupabaseService.shared.updateScore(
                userId: userId,
                bestDb: best,
                totalDaps: total,
                streak: streak
            )
        }
    }

    func setAdsRemoved(_ value: Bool) {
        adsRemoved = value
        defaults.set(value, forKey: adsRemovedKey)
    }
}
