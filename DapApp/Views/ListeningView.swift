import SwiftUI

struct ListeningView: View {
    @ObservedObject var audio: AudioMeterService

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 6)
                    .frame(width: 200, height: 200)

                let scale = 0.35 + min(1.0, audio.liveLinearPeak * 12.0) * 0.65
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x30D158).opacity(0.9), Color(hex: 0x30D158).opacity(0.2)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200 * scale, height: 200 * scale)
                    .animation(.easeOut(duration: 0.08), value: audio.liveLinearPeak)

                WaveformBars(level: audio.liveLinearPeak)
                    .frame(width: 160, height: 72)
            }

            Text("LISTENING…")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }
}

private struct WaveformBars: View {
    let level: Double
    private let barCount = 12

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<barCount, id: \.self) { i in
                let t = Double(i) / Double(barCount)
                let wave = 0.35 + sin(t * .pi * 2 + level * 10) * 0.15
                let h = max(8, (0.2 + level * 3 + wave) * 72)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 8, height: h)
                    .animation(.easeOut(duration: 0.06), value: level)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        ListeningView(audio: AudioMeterService())
    }
}
