import Foundation
import Supabase

enum SupabaseConfig {
    // TODO: Replace with real Supabase project values
    static let url = URL(string: "https://jkfyckavvfxnijthmmvc.supabase.co")!
    static let anonKey = "sb_publishable_P-VeHlP27BPrISR7hFsTew_EzRvNBxM"
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

/// Insert payload for the `friend_requests` table. Snake-case keys match the
/// Postgres column names; status defaults to `pending` so a recipient can
/// later accept/decline.
private struct FriendRequestPayload: Encodable {
    let fromUserId: UUID
    let toUserId: UUID
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case status
        case createdAt = "created_at"
    }
}

/// Patch payload for flipping a friend request's status (accepted/declined).
private struct FriendRequestStatusPayload: Encodable {
    let status: String
}

/// Row shape returned by SELECTs on the `friend_requests` table. `id` is the
/// request primary key (required for accept/decline).
private struct FriendRequestRow: Codable, Identifiable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case status
    }
}

/// UI-facing model: a pending incoming request enriched with the requester's
/// profile info (username, best dB) so the row can render without a second
/// lookup.
struct PendingFriendRequest: Identifiable, Equatable {
    let requestId: UUID
    let requester: LeaderboardEntry
    var id: UUID { requestId }
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

    /// Returns true if the username is unused. On network/API error we
    /// optimistically return true so the onboarding flow isn't blocked when
    /// Supabase is unreachable or the table doesn't exist yet — collisions
    /// will be resolved server-side on insert.
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
            return true
        }
    }

    /// Send a friend request from `senderId` to the user with `toUsername`.
    /// Returns `true` if a matching user was found and the row was inserted,
    /// `false` if the user doesn't exist or the call failed (network down,
    /// table missing, duplicate request, etc.) — silent failure mode so the
    /// app never crashes on a flaky network.
    func sendFriendRequest(from senderId: UUID, toUsername: String) async -> Bool {
        do {
            let recipients: [LeaderboardEntry] = try await client
                .from("leaderboard")
                .select()
                .eq("username", value: toUsername)
                .limit(1)
                .execute()
                .value

            guard let recipient = recipients.first else { return false }
            // Self-friending is a no-op.
            guard recipient.id != senderId else { return false }

            let payload = FriendRequestPayload(
                fromUserId: senderId,
                toUserId: recipient.id,
                status: "pending",
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            try await client.from("friend_requests").insert(payload).execute()
            return true
        } catch {
            return false
        }
    }

    /// Count of pending friend requests addressed to `userId`. Returns 0 on
    /// any error so the UI gracefully degrades when offline.
    func pendingRequestCount(for userId: UUID) async -> Int {
        do {
            let response = try await client
                .from("friend_requests")
                .select("*", head: true, count: .exact)
                .eq("to_user_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .execute()
            return response.count ?? 0
        } catch {
            return 0
        }
    }

    /// Fetch incoming pending requests for `userId`, hydrated with the
    /// requester's leaderboard row (for username + best dB display). Returns
    /// an empty list on any error so the UI degrades gracefully offline.
    func fetchPendingRequests(for userId: UUID) async -> [PendingFriendRequest] {
        do {
            let rows: [FriendRequestRow] = try await client
                .from("friend_requests")
                .select()
                .eq("to_user_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value

            guard !rows.isEmpty else { return [] }

            // Batch-fetch the requester profiles in one round-trip.
            let requesterIds = rows.map { $0.fromUserId.uuidString }
            let profiles: [LeaderboardEntry] = try await client
                .from("leaderboard")
                .select()
                .in("id", values: requesterIds)
                .execute()
                .value

            let profileById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            return rows.compactMap { row in
                guard let profile = profileById[row.fromUserId] else { return nil }
                return PendingFriendRequest(requestId: row.id, requester: profile)
            }
        } catch {
            return []
        }
    }

    /// Fetch the list of accepted friends for `userId`. Friendship is
    /// symmetric: a row with `status == accepted` where the user is on either
    /// side counts as a friend. Returns leaderboard rows for each friend.
    func fetchFriends(for userId: UUID) async -> [LeaderboardEntry] {
        do {
            // Rows where I'm the sender and they accepted.
            let outgoing: [FriendRequestRow] = try await client
                .from("friend_requests")
                .select()
                .eq("from_user_id", value: userId.uuidString)
                .eq("status", value: "accepted")
                .execute()
                .value

            // Rows where I'm the recipient and I accepted.
            let incoming: [FriendRequestRow] = try await client
                .from("friend_requests")
                .select()
                .eq("to_user_id", value: userId.uuidString)
                .eq("status", value: "accepted")
                .execute()
                .value

            let friendIds = Set(outgoing.map { $0.toUserId } + incoming.map { $0.fromUserId })
            guard !friendIds.isEmpty else { return [] }

            let profiles: [LeaderboardEntry] = try await client
                .from("leaderboard")
                .select()
                .in("id", values: friendIds.map { $0.uuidString })
                .order("best_dap_db", ascending: false)
                .execute()
                .value
            return profiles
        } catch {
            return []
        }
    }

    /// Flip a pending request to `accepted`. Returns true on success.
    func acceptFriendRequest(requestId: UUID) async -> Bool {
        await updateRequestStatus(requestId: requestId, status: "accepted")
    }

    /// Flip a pending request to `declined`. Returns true on success. (We
    /// keep the row around for audit rather than hard-deleting it.)
    func declineFriendRequest(requestId: UUID) async -> Bool {
        await updateRequestStatus(requestId: requestId, status: "declined")
    }

    private func updateRequestStatus(requestId: UUID, status: String) async -> Bool {
        do {
            try await client.from("friend_requests")
                .update(FriendRequestStatusPayload(status: status))
                .eq("id", value: requestId.uuidString)
                .execute()
            return true
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
