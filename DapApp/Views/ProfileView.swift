import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var history: DapHistoryStore

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    statsGrid

                    if history.currentStreak > 0 || history.longestStreak > 0 {
                        streakBlock
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text(history.username ?? "anonymous")
                .font(AppFont.display(size: 36))
                .tracking(2)
                .foregroundStyle(.white)
        }
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "TOTAL DAPS",
                    value: "\(history.totalDaps)",
                    tint: Color(hex: 0x30D158)
                )
                StatCard(
                    title: "BEST DAP",
                    value: history.bestDap.map { String(format: "%.1f dB", $0.peakDecibels) } ?? "—",
                    tint: Color(hex: 0xFF6B35)
                )
            }
        }
    }

    private var streakBlock: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "CURRENT STREAK",
                value: "\(history.currentStreak)",
                subtitle: history.currentStreak == 1 ? "day" : "days",
                tint: Color(hex: 0xFF6B35),
                icon: "flame.fill"
            )
            StatCard(
                title: "LONGEST",
                value: "\(history.longestStreak)",
                subtitle: history.longestStreak == 1 ? "day" : "days",
                tint: Color(hex: 0xFFD700),
                icon: "crown.fill"
            )
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let tint: Color
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text(value)
                .font(AppFont.display(size: 38))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(DapHistoryStore())
}
