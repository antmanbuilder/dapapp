import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var history: DapHistoryStore
    @StateObject private var store = StoreService()

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var cameraImage: UIImage? = nil
    @State private var showPremium = false
    @State private var showPremiumForPhoto = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    usernameLabel
                    profilePicture
                    premiumBadge
                    statsGrid

                    if !history.adsRemoved {
                        freePlanCard
                    }

                    #if DEBUG
                    // Dev-only escape hatch — wipes the daily counter so
                    // we can re-exercise the paywall / limit UI without
                    // reinstalling. Stripped from Release builds by the
                    // compiler flag, so it'll never ship to the Store.
                    Button("Reset Daily Daps (Testing)") {
                        UserDefaults.standard.set(0, forKey: "dailyDapCount")
                        UserDefaults.standard.set("", forKey: "dailyDapDate")
                        history.load()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 40)
                    #endif

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showPremium) {
            RemoveAdsView(store: store, history: history)
        }
        .fullScreenCover(isPresented: $showPremiumForPhoto) {
            RemoveAdsView(store: store, history: history)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newItem in
            handlePhotoPick(newItem)
        }
        .onChange(of: cameraImage) { newImage in
            handleCameraImage(newImage)
        }
    }

    // MARK: - Header

    private var usernameLabel: some View {
        Text("@\(history.username ?? "anonymous")")
            .font(AppFont.display(size: 24))
            .tracking(2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
    }

    private var profilePicture: some View {
        // The circle itself isn't a tap target anymore — we pin a small
        // Menu-anchored pencil badge to the bottom-right so the Menu's
        // hit area matches its visual footprint, rather than covering
        // the whole avatar.
        ZStack {
            profileCircle

            Menu {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                Button {
                    showPhotoLibrary = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
            } label: {
                Circle()
                    .fill(Color(hex: 0x30D158))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    )
                    .overlay(
                        Circle().stroke(Color(hex: 0x1C1C1E), lineWidth: 2)
                    )
            }
            .menuStyle(.borderlessButton)
            // Anchor relative to the 90pt circle so the badge hangs off
            // its bottom-right corner, Instagram-style.
            .offset(x: 30, y: 30)
        }
    }

    private var profileCircle: some View {
        ZStack {
            if let data = history.profileImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.35))
                    )
            }
        }
        .overlay(
            Circle()
                .stroke(Color(hex: 0x30D158), lineWidth: 2)
        )
    }

    @ViewBuilder
    private var premiumBadge: some View {
        if history.adsRemoved {
            HStack(spacing: 6) {
                Text("✦")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0xFFD700))
                Text("Premium Member")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(hex: 0x30D158).opacity(0.18))
            )
            .overlay(
                Capsule().stroke(Color(hex: 0x30D158).opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        let columns: [GridItem] = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return LazyVGrid(columns: columns, spacing: 12) {
            ColoredStatCard(
                label: "TOTAL DAPS",
                value: "\(history.totalDaps)",
                color: Color(hex: 0x30D158),
                icon: "waveform"
            )
            ColoredStatCard(
                label: "BEST DAP",
                value: history.bestDap.map { String(format: "%.1f", $0.peakDecibels) } ?? "—",
                color: Color(hex: 0xFF6B35),
                icon: "flame.fill"
            )
            ColoredStatCard(
                label: "CURRENT STREAK",
                value: "\(history.currentStreak)",
                color: Color(hex: 0xFF2D55),
                icon: "bolt.fill"
            )
            ColoredStatCard(
                label: "LONGEST STREAK",
                value: "\(history.longestStreak)",
                color: Color(hex: 0x6C5CE7),
                icon: "crown.fill"
            )
        }
    }

    // MARK: - Free plan card

    private var freePlanCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Free Plan")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(history.dapsRemaining)/\(history.dailyDapLimit) daps left")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        history.dapsRemaining <= 1
                            ? Color(hex: 0xFF3B30)
                            : .white.opacity(0.6)
                    )
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: 0x30D158))
                        .frame(
                            width: geo.size.width
                                * CGFloat(history.dailyDapsUsed)
                                / CGFloat(max(1, history.dailyDapLimit)),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            Button {
                showPremium = true
            } label: {
                Text("✦ Upgrade to Premium")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0x30D158))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: 0x30D158).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Photo handling

    private func handleCameraImage(_ newImage: UIImage?) {
        guard let img = newImage else { return }
        // Gate behind premium — same rules as library picks. Clear the
        // state so a re-take after upgrade triggers this branch again.
        if !history.adsRemoved {
            cameraImage = nil
            DispatchQueue.main.async { showPremiumForPhoto = true }
            return
        }
        let resized = img.preparingThumbnail(of: CGSize(width: 200, height: 200))
        if let data = resized?.jpegData(compressionQuality: 0.8) {
            history.setProfileImage(data)
        }
        cameraImage = nil
    }

    private func handlePhotoPick(_ newItem: PhotosPickerItem?) {
        guard let newItem else { return }
        // Gate behind premium. Clear the selection so the picker can be
        // re-triggered after upgrade without thinking we already have a
        // pending selection.
        if !history.adsRemoved {
            selectedPhoto = nil
            DispatchQueue.main.async { showPremiumForPhoto = true }
            return
        }
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let resized = uiImage.preparingThumbnail(
                    of: CGSize(width: 200, height: 200)
                )
                if let jpegData = resized?.jpegData(compressionQuality: 0.8) {
                    await MainActor.run {
                        history.setProfileImage(jpegData)
                        selectedPhoto = nil
                    }
                }
            }
        }
    }
}

// MARK: - Colored stat card

private struct ColoredStatCard: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(color)

            Text(value)
                .font(AppFont.display(size: 28))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(color.opacity(0.3))
                .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.15))
        )
    }
}

/// Thin wrapper around `UIImagePickerController` so SwiftUI can present
/// the system camera. We only surface the finished `UIImage` — the
/// caller handles resize and persistence.
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(DapHistoryStore())
}
