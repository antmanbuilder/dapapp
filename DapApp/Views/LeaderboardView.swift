import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @StateObject private var supabase = SupabaseService.shared

    @State private var mode: Mode = .allTime

    enum Mode: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case allTime = "All Time"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            VStack(spacing: 12) {
                header

                modeToggle

                if supabase.leaderboard.isEmpty && !supabase.isLoading {
                    emptyState
                } else {
                    list
                }
            }
        }
        .task {
            if supabase.leaderboard.isEmpty {
                await supabase.fetchLeaderboard(weekly: mode == .weekly)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("LEADERBOARD")
                .font(AppFont.display(size: 26))
                .tracking(3)
                .foregroundStyle(.white)
            Spacer()
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

    private var list: some View {
        List {
            ForEach(Array(supabase.leaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(
                    rank: index + 1,
                    entry: entry,
                    mode: mode,
                    isCurrentUser: entry.id == history.userId
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable {
            await supabase.fetchLeaderboard(weekly: mode == .weekly)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.25))
            Text("No daps yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text("Be the first to claim the top spot.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let mode: LeaderboardView.Mode
    let isCurrentUser: Bool

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
                Text(entry.username)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrentUser ? .black : .white)
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
