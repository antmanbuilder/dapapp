import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @StateObject private var supabase = SupabaseService.shared

    @State private var mode: Mode = .allTime
    @State private var pendingCount: Int = 0
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    enum Mode: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case allTime = "All Time"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0x1C1C1E).ignoresSafeArea()

                VStack(spacing: 12) {
                    header

                    modeToggle

                    scrollBody
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: shareItems)
            }
            .task {
                if supabase.leaderboard.isEmpty {
                    await supabase.fetchLeaderboard(weekly: mode == .weekly)
                }
            }
            .onAppear {
                refreshPendingCount()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("LEADERBOARD")
                .font(AppFont.display(size: 26))
                .tracking(3)
                .foregroundStyle(.white)

            Spacer()

            NavigationLink {
                FriendsView()
                    .environmentObject(history)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())

                    if pendingCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: 0x1C1C1E), lineWidth: 1.5)
                            )
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var modeToggle: some View {
        Picker("Mode", selection: $mode) {
            ForEach(Mode.allCases) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .onChange(of: mode) { newValue in
            Task { await supabase.fetchLeaderboard(weekly: newValue == .weekly) }
        }
    }

    // MARK: - Scrollable body (list + bottom buttons)

    private var scrollBody: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if supabase.leaderboard.isEmpty && !supabase.isLoading {
                    emptyState
                        .padding(.top, 60)
                } else {
                    ForEach(Array(supabase.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        let isMe = entry.id == history.userId
                        LeaderboardRow(
                            rank: index + 1,
                            entry: entry,
                            mode: mode,
                            isCurrentUser: isMe,
                            // We only know our own premium status locally,
                            // so the ✦ badge lights up only on our row. A
                            // future server-side `is_premium` column would
                            // extend this to everyone.
                            isPremium: isMe && history.adsRemoved
                        )
                    }
                }

                bottomButtons
                    .padding(.top, 18)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .refreshable {
            await supabase.fetchLeaderboard(weekly: mode == .weekly)
            refreshPendingCount()
        }
    }

    // MARK: - Bottom action buttons

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            NavigationLink {
                FriendsView()
                    .environmentObject(history)
            } label: {
                actionLabel(icon: "person.badge.plus", text: "Add Friend")
                    .foregroundStyle(Color(hex: 0x30D158))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: 0x30D158), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                shareFromBoard()
            } label: {
                actionLabel(icon: "square.and.arrow.up", text: "Share")
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: 0x30D158))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func actionLabel(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
    }

    // MARK: - Share

    @MainActor
    private func shareFromBoard() {
        let username = history.username ?? "someone"
        if let mostRecent = history.dapHistory.first {
            let streakCount = history.currentStreak
            if let image = ShareImageRenderer.renderCard(
                result: mostRecent,
                username: username,
                streak: streakCount
            ) {
                let text = "I just hit \(String(format: "%.1f", mostRecent.peakDecibels)) dB on Dap App! \(mostRecent.tier.emoji) Can you beat me? Add me: @\(username)"
                shareItems = [image, text] as [Any]
            } else {
                let text = "I just hit \(mostRecent.tier.displayTitle) (\(String(format: "%.1f", mostRecent.peakDecibels)) dB) on Dap App! \(mostRecent.tier.emoji) Can you beat me? Add me: @\(username)"
                shareItems = [text] as [Any]
            }
        } else {
            let text = "Dap your friends and see who hits the hardest! 💥 Add me on Dap App: @\(username)"
            shareItems = [text] as [Any]
        }
        // Defer the sheet presentation by one run loop so `shareItems` is fully
        // committed before SwiftUI reads it — avoids the "have to tap twice"
        // bug caused by the sheet flipping true in the same state-write batch.
        DispatchQueue.main.async {
            self.showShareSheet = true
        }
    }

    // MARK: - Pending count

    private func refreshPendingCount() {
        guard let userId = history.userId else { return }
        Task { @MainActor in
            pendingCount = await SupabaseService.shared.pendingRequestCount(for: userId)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.25))
            Text("No daps yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text("Be the first to claim the top spot.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let mode: LeaderboardView.Mode
    let isCurrentUser: Bool
    let isPremium: Bool

    private var dbValue: Double {
        mode == .weekly ? entry.weeklyBestDb : entry.bestDapDb
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(AppFont.display(size: 22))
                .frame(width: 40, alignment: .leading)
                .foregroundStyle(rankColor)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(entry.username)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isCurrentUser ? .black : .white)
                    if isPremium {
                        Text("✦")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: 0xFFD700))
                    }
                }
                if entry.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: 0xFF6B35))
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(isCurrentUser ? .black.opacity(0.7) : .white.opacity(0.6))
                    }
                }
            }

            Spacer()

            Text(String(format: "%.1f dB", dbValue))
                .font(AppFont.display(size: 22))
                .foregroundStyle(isCurrentUser ? .black : .white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isCurrentUser ? Color(hex: 0x30D158) : Color.white.opacity(0.06))
        )
    }

    private var rankColor: Color {
        if isCurrentUser { return .black }
        switch rank {
        case 1: return Color(hex: 0xFFD700)
        case 2: return Color(hex: 0xC0C0C0)
        case 3: return Color(hex: 0xCD7F32)
        default: return .white.opacity(0.5)
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(DapHistoryStore())
}
