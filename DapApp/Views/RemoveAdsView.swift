import SwiftUI

struct RemoveAdsView: View {
    @ObservedObject var store: StoreService
    @ObservedObject var history: DapHistoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Go ad-free")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))

                Text("Remove banner and interstitial ads for $0.99. One-time purchase.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if store.purchaseInFlight {
                    ProgressView()
                }

                Button {
                    Task {
                        do {
                            let ok = try await store.purchaseRemoveAds()
                            if ok { history.setAdsRemoved(true) }
                            dismiss()
                        } catch {
                            store.lastError = error.localizedDescription
                        }
                    }
                } label: {
                    Text("Purchase")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: 0x30D158))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)

                Button("Restore purchases") {
                    Task {
                        if try await store.restorePurchases() {
                            history.setAdsRemoved(true)
                            dismiss()
                        }
                    }
                }
                .padding(.top, 8)

                if let err = store.lastError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Remove Ads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await store.loadProducts()
            }
        }
    }
}
