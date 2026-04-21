import SwiftUI

struct DapButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @State private var breathe = false
    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                pressed = false
                action()
            }
        } label: {
            ZStack {
                // Pulsing glow behind button
                Circle()
                    .fill(Color(hex: 0x30D158).opacity(0.2))
                    .frame(width: 240, height: 240)
                    .scaleEffect(breathe ? 1.1 : 0.95)
                    .blur(radius: 20)

                // Main circle
                Circle()
                    .fill(Color(hex: 0x30D158))
                    .frame(width: 220, height: 220)
                    .shadow(color: Color(hex: 0x30D158).opacity(0.55), radius: 24, y: 8)

                Text(title)
                    .font(AppFont.display(size: 42))
                    .foregroundStyle(.black)
                    .tracking(2)
            }
            .scaleEffect(pressed ? 0.9 : 1.0)
            .scaleEffect(breathe ? 1.02 : 0.98)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        DapButton(title: "DAP IT", action: {})
    }
}
