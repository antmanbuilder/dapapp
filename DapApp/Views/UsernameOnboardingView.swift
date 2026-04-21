import SwiftUI

/// First-launch flow: pick a username, validate locally + against Supabase
/// (debounced), then persist the `userId` + `username` to `DapHistoryStore`.
/// If the network is down the user can still continue — we just skip the
/// remote uniqueness check and let conflict resolution happen later.
struct UsernameOnboardingView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @StateObject private var supabase = SupabaseService.shared

    @State private var username: String = ""
    @State private var availability: Availability = .idle
    @State private var isSubmitting = false
    @State private var checkTask: Task<Void, Never>?

    enum Availability {
        case idle
        case checking
        case available
        case taken
        case invalid(String)
    }

    private var trimmed: String {
        username.trimmingCharacters(in: .whitespaces)
    }

    private var canSubmit: Bool {
        if isSubmitting { return false }
        switch availability {
        case .available, .idle: return isLocallyValid(trimmed)
        default: return false
        }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("DAP APP")
                    .font(AppFont.display(size: 54))
                    .tracking(4)
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("Pick a name")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("16 chars max · letters, numbers, underscores")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 10) {
                    TextField("", text: $username, prompt: Text("username").foregroundColor(.white.opacity(0.35)))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(AppFont.display(size: 32))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: 1.5)
                        )
                        .onChange(of: username) { newValue in
                            let sanitized = sanitize(newValue)
                            if sanitized != newValue {
                                username = sanitized
                                return
                            }
                            scheduleAvailabilityCheck()
                        }

                    statusLabel
                        .frame(height: 18)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: submit) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: 0x30D158))
                        if isSubmitting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("DAP ON")
                                .font(AppFont.display(size: 32))
                                .tracking(3)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(height: 64)
                    .shadow(color: Color(hex: 0x30D158).opacity(0.4), radius: 18, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1.0 : 0.45)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private var borderColor: Color {
        switch availability {
        case .available: return Color(hex: 0x30D158).opacity(0.7)
        case .taken, .invalid: return Color(hex: 0xFF3B30).opacity(0.7)
        default: return Color.white.opacity(0.15)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch availability {
        case .idle:
            Text(" ")
                .font(.system(size: 13, design: .rounded))
        case .checking:
            Text("Checking…")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        case .available:
            Text("✓ available")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x30D158))
        case .taken:
            Text("already taken")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xFF3B30))
        case .invalid(let msg):
            Text(msg)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xFF6B35))
        }
    }

    private func sanitize(_ raw: String) -> String {
        let allowed = raw.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "_"
        }
        return String(String.UnicodeScalarView(allowed)).prefix(16).lowercased()
    }

    private func isLocallyValid(_ value: String) -> Bool {
        guard value.count >= 3 else { return false }
        guard value.count <= 16 else { return false }
        let set = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return value.unicodeScalars.allSatisfy { set.contains($0) }
    }

    private func scheduleAvailabilityCheck() {
        checkTask?.cancel()
        let value = trimmed
        if value.isEmpty {
            availability = .idle
            return
        }
        if value.count < 3 {
            availability = .invalid("at least 3 chars")
            return
        }
        guard isLocallyValid(value) else {
            availability = .invalid("invalid characters")
            return
        }
        availability = .checking
        checkTask = Task { [value] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }
            let available = await supabase.isUsernameAvailable(value)
            if Task.isCancelled { return }
            await MainActor.run {
                // Only apply the result if the input hasn't changed since.
                guard value == self.trimmed else { return }
                self.availability = available ? .available : .taken
            }
        }
    }

    private func submit() {
        let name = trimmed
        guard isLocallyValid(name), !isSubmitting else { return }
        isSubmitting = true
        let userId = UUID()
        Task {
            try? await supabase.ensureUser(username: name, userId: userId)
            await MainActor.run {
                history.setUserIdentity(userId: userId, username: name)
                isSubmitting = false
            }
        }
    }
}

#Preview {
    UsernameOnboardingView()
        .environmentObject(DapHistoryStore())
}
