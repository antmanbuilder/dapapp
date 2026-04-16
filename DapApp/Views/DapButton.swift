import SwiftUI

struct DapButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 220, height: 220)
                .background(
                    Circle()
                        .fill(Color(hex: 0x30D158))
                        .shadow(color: Color(hex: 0x30D158).opacity(0.55), radius: 24, y: 8)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

#Preview {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        DapButton(title: "DAP IT", action: {})
    }
}
