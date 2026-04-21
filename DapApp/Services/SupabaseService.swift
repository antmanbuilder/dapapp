import Foundation
import Supabase

enum SupabaseConfig {
    // TODO: Replace with real Supabase project values
    static let url = URL(string: "https://YOUR_PROJECT.supabase.co")!
    static let anonKey = "YOUR_ANON_KEY"
}

struct LeaderboardEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var bestDapDb: Double
    var totalDaps: Int
    var currentStreak: Int
    var weeklyBestDb: Double
    var weekNumber: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, username
        case bestDapDb = "best_dap_db"
        case totalDaps = "total_daps"
        case currentStreak = "current_streak"
        case weeklyBestDb = "weekly_best_db"
        case weekNumber = "week_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Encodable payload for score updates — Supabase 2.x's `update(_:)` takes
/// an `Encodable` value (not `[String: Any]`), so we express the patch as
/// a typed struct with matching snake_case coding keys.
private struct ScoreUpdatePayload: Encodable {
    let bestDapDb: Double
    let totalDaps: Int
    let currentStreak: Int
    let weeklyBestDb: Double
    let weekNumber: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case bestDapDb = "best_dap_db"
        case totalDaps = "total_daps"
        case currentStreak = "current_streak"
        case weeklyBestDb = "weekly_best_db"
        case weekNumber = "week_number"
        case updatedAt = "updated_at"
    }
}

@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private let client: SupabaseClient
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var userEntry: LeaderboardEntry?
    @Published var isLoading = false

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    /// Fetch existing row for this user-id or create a new one. Throws on
    /// network/API failure so the onboarding flow can react; the main dap
    /// flow never calls this on the happy path.
    func ensureUser(username: String, userId: UUID) async throws {
        let existing: [LeaderboardEntry] = try await client
            .from("leaderboard")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        if let entry = existing.first {
            userEntry = entry
        } else {
            let new = LeaderboardEntry(
                id: userId,
                username: username,
                bestDapDb: 0,
                totalDaps: 0,
                currentStreak: 0,
                weeklyBestDb: 0,
                weekNumber: currentWeekNumber()
            )
            try await client.from("leaderboard").insert(new).execute()
            userEntry = new
        }
    }

    /// Push new score after a dap. Silent failure — the core flow must keep
    /// working fully offline.
    func updateScore(userId: UUID, bestDb: Double, totalDaps: Int, streak: Int) async {
        let payload = ScoreUpdatePayload(
            bestDapDb: bestDb,
            totalDaps: totalDaps,
            currentStreak: streak,
            weeklyBestDb: bestDb, // Simplified — ideally track weekly separately
            weekNumber: currentWeekNumber(),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        do {
            try await client.from("leaderboard")
                .update(payload)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            print("Leaderboard update failed: \(error)")
        }
    }

    /// Fetch the top 50 by best-ever dB (all-time) or by the current week's best.
    func fetchLeaderboard(weekly: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if weekly {
                leaderboard = try await client
                    .from("leaderboard")
                    .select()
                    .eq("week_number", value: currentWeekNumber())
                    .order("weekly_best_db", ascending: false)
                    .limit(50)
                    .execute()
                    .value
            } else {
                leaderboard = try await client
                    .from("leaderboard")
                    .select()
                    .order("best_dap_db", ascending: false)
                    .limit(50)
                    .execute()
                    .value
            }
        } catch {
            print("Leaderboard fetch failed: \(error)")
        }
    }

    /// Returns true if the username is unused (or if the check fails safely —
    /// we return false on error so we don't let users claim a colliding name).
    func isUsernameAvailable(_ username: String) async -> Bool {
        do {
            let results: [LeaderboardEntry] = try await client
                .from("leaderboard")
                .select()
                .eq("username", value: username)
                .execute()
                .value
            return results.isEmpty
        } catch {
            return false
        }
    }

    private func currentWeekNumber() -> Int {
        let cal = Calendar.current
        let now = Date()
        return cal.component(.weekOfYear, from: now) + cal.component(.year, from: now) * 100
    }
}
