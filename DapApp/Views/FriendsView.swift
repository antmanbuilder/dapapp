import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var history: DapHistoryStore

    // Add-Friend section
    @State private var addUsername: String = ""
    @State private var addFeedback: AddFeedback?
    @State private var isSending = false

    // Friend Requests section
    @State private var pending: [PendingFriendRequest] = []

    // Friends section
    @State private var friends: [LeaderboardEntry] = []
    @State private var isLoading = false

    private enum AddFeedback: Equatable {
        case success
        case failure

        var text: String {
            switch self {
            case .success: return "Request sent!"
            case .failure: return "User not found"
            }
        }

        var color: Color {
            switch self {
            case .success: return Color(hex: 0x30D158)
            case .failure: return Color(hex: 0xFF3B30)
            }
        }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    addFriendSection

                    if !pending.isEmpty {
                        requestsSection
                    }

                    friendsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .refreshable {
                await refresh()
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: 0x1C1C1E), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await refresh()
        }
    }

    // MARK: - Section: Add Friend

    private var addFriendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Add Friend", count: nil)

            HStack(spacing: 10) {
                TextField("", text: $addUsername, prompt: Text("Enter username").foregroundColor(.white.opacity(0.4)))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onChange(of: addUsername) { newValue in
                        addUsername = sanitize(newValue)
                    }
                    .onSubmit(submit)

                Button(action: submit) {
                    Text("Send")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0x30D158))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .opacity(canSubmit ? 1 : 0.4)
                }
                .disabled(!canSubmit)
            }

            if let feedback = addFeedback {
                Text(feedback.text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(feedback.color)
                    .transition(.opacity)
            }
        }
    }

    private var canSubmit: Bool {
        !isSending && !addUsername.trimmingCharacters(in: .whitespaces).isEmpty && history.userId != nil
    }

    private func sanitize(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let filtered = raw.unicodeScalars.filter { allowed.contains($0) }
        let cleaned = String(String.UnicodeScalarView(filtered)).lowercased()
        return String(cleaned.prefix(16))
    }

    private func submit() {
        let target = addUsername.trimmingCharacters(in: .whitespaces)
        guard !target.isEmpty, let userId = history.userId else { return }
        isSending = true
        Task { @MainActor in
            let ok = await SupabaseService.shared.sendFriendRequest(from: userId, toUsername: target)
            withAnimation { addFeedback = ok ? .success : .failure }
            isSending = false
            if ok { addUsername = "" }

            // Clear feedback after 3s.
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { addFeedback = nil }
        }
    }

    // MARK: - Section: Friend Requests

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Friend Requests", count: pending.count)

            VStack(spacing: 10) {
                ForEach(pending) { request in
                    PendingRequestRow(
                        request: request,
                        onAccept: { handle(request: request, accept: true) },
                        onDecline: { handle(request: request, accept: false) }
                    )
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
    }

    private func handle(request: PendingFriendRequest, accept: Bool) {
        Task { @MainActor in
            let ok: Bool
            if accept {
                ok = await SupabaseService.shared.acceptFriendRequest(requestId: request.requestId)
            } else {
                ok = await SupabaseService.shared.declineFriendRequest(requestId: request.requestId)
            }
            guard ok else { return }
            withAnimation {
                pending.removeAll { $0.requestId == request.requestId }
            }
            if accept {
                await refreshFriends()
            }
        }
    }

    // MARK: - Section: My Friends

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("My Friends", count: friends.isEmpty ? nil : friends.count)

            if friends.isEmpty {
                Text("No friends yet. Add someone above!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                        FriendRow(rank: index + 1, friend: friend)
                    }
                }
            }
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String, count: Int?) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(AppFont.display(size: 18))
                .tracking(2)
                .foregroundStyle(.white)
            if let count {
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: 0x30D158))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.bottom, 2)
    }

    // MARK: - Data

    private func refresh() async {
        guard let userId = history.userId else { return }
        isLoading = true
        async let pendingResult = SupabaseService.shared.fetchPendingRequests(for: userId)
        async let friendsResult = SupabaseService.shared.fetchFriends(for: userId)
        let (p, f) = await (pendingResult, friendsResult)
        await MainActor.run {
            withAnimation {
                pending = p
                friends = f
            }
            isLoading = false
        }
    }

    private func refreshFriends() async {
        guard let userId = history.userId else { return }
        let f = await SupabaseService.shared.fetchFriends(for: userId)
        await MainActor.run {
            withAnimation { friends = f }
        }
    }
}

// MARK: - Rows

private struct PendingRequestRow: View {
    let request: PendingFriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.requester.username)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(String(format: "%.1f dB", request.requester.bestDapDb))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Button(action: onAccept) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: 0x30D158))
            }
            .buttonStyle(.plain)

            Button(action: onDecline) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: 0xFF3B30))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct FriendRow: View {
    let rank: Int
    let friend: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(AppFont.display(size: 20))
                .frame(width: 32, alignment: .leading)
                .foregroundStyle(.white.opacity(0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if friend.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: 0xFF6B35))
                        Text("\(friend.currentStreak)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }

            Spacer()

            Text(String(format: "%.1f dB", friend.bestDapDb))
                .font(AppFont.display(size: 20))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    NavigationStack {
        FriendsView()
            .environmentObject(DapHistoryStore())
    }
}
