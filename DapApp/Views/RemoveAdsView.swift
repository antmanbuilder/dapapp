import SwiftUI

/// Full-screen premium paywall presented whenever the user bumps into a
/// free-tier wall (top bar button, daily dap cap, custom avatar, etc.). We
/// keep the type name `RemoveAdsView` for source-compat with the rest of
/// the app, but the visual presentation is a modern upgrade paywall.
struct RemoveAdsView: View {
    @ObservedObject var store: StoreService
    @ObservedObject var history: DapHistoryStore
    @Environment(\.dismiss) private var dismiss

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
    }

    private let features: [Feature] = [
        Feature(
            icon: "infinity",
            title: "Unlimited Daps",
            description: "Free users get 3 daps per day. Go unlimited."
        ),
        Feature(
            icon: "sparkles",
            title: "Ad-Free Experience",
            description: "No interruptions. Pure dapping."
        ),
        Feature(
            icon: "crown.fill",
            title: "Premium Badge",
            description: "Stand out on the leaderboard with a ✦ next to your name."
        ),
        Feature(
            icon: "paintbrush.fill",
            title: "Custom Profile Picture",
            description: "Express yourself with a custom avatar."
        )
    ]

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topDismissBar

                ScrollView {
                    VStack(spacing: 28) {
                        headline

                        VStack(spacing: 16) {
                            ForEach(features) { feature in
                                featureRow(feature)
                            }
                        }
                        .padding(.top, 12)

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }

                ctaStack
            }
        }
        .task {
            await store.loadProducts()
        }
    }

    // MARK: - Layers

    private var background: some View {
        ZStack {
            Color(hex: 0x0D0D0E).ignoresSafeArea()

            // Subtle green gradient halo up top — aspirational, not garish.
            LinearGradient(
                colors: [
                    Color(hex: 0x30D158).opacity(0.18),
                    Color(hex: 0x30D158).opacity(0.04),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 320)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    private var topDismissBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var headline: some View {
        VStack(spacing: 10) {
            Text("GO PREMIUM")
                .font(AppFont.display(size: 36))
                .tracking(4)
                .foregroundStyle(.white)

            Text("Unlock the full potential of Dap App")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x30D158).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0x30D158))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(feature.description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ctaStack: some View {
        VStack(spacing: 10) {
            Text("Just $0.99 — one time, forever.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Button(action: purchase) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: 0x30D158))
                    if store.purchaseInFlight {
                        ProgressView().tint(.black)
                    } else {
                        Text("UNLOCK PREMIUM")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.black)
                    }
                }
                .frame(height: 54)
                .shadow(color: Color(hex: 0x30D158).opacity(0.35), radius: 18, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(store.purchaseInFlight)

            Button(action: restore) {
                Text("Restore Purchase")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if let err = store.lastError {
                Text(err)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0xFF3B30))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
    }

    // MARK: - Actions

    private func purchase() {
        Task {
            do {
                let ok = try await store.purchaseRemoveAds()
                if ok {
                    history.setAdsRemoved(true)
                    dismiss()
                }
            } catch {
                store.lastError = error.localizedDescription
            }
        }
    }

    private func restore() {
        Task {
            do {
                if try await store.restorePurchases() {
                    history.setAdsRemoved(true)
                    dismiss()
                }
            } catch {
                store.lastError = error.localizedDescription
            }
        }
    }
}

#Preview {
    RemoveAdsView(store: StoreService(), history: DapHistoryStore())
}
