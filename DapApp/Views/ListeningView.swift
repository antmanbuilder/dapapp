import SwiftUI

/// Shazam-inspired listening visualizer — concentric organic rings that
/// undulate softly at rest and pulse dramatically with loud audio. No rigid
/// bars, no spokes. Pure bezier wobble driven by layered sine waves.
struct ListeningView: View {
    @ObservedObject var audio: AudioMeterService

    @State private var smoothLevel: Double = 0
    @State private var timerProgress: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Timer progress ring — outermost, subtle
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        Color(hex: 0x30D158).opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))

                // Ambient glow — breathes with the audio level. The blur
                // gives it a soft halo under the rings.
                Circle()
                    .fill(Color(hex: 0x30D158).opacity(0.06 + smoothLevel * 0.12))
                    .frame(
                        width: 200 + CGFloat(smoothLevel * 40),
                        height: 200 + CGFloat(smoothLevel * 40)
                    )
                    .blur(radius: 40)

                // The rings — 4 smooth organic circles, each warped by three
                // layered sine waves at different frequencies for a wobble
                // that never looks mechanical.
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    Canvas { context, size in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        let cx = size.width / 2
                        let cy = size.height / 2

                        let rings: [(radius: CGFloat, opacity: Double, width: CGFloat)] = [
                            (100, 0.5, 2.5),
                            (78, 0.4, 2.0),
                            (56, 0.3, 1.5),
                            (34, 0.5, 2.0)
                        ]

                        for (idx, ring) in rings.enumerated() {
                            let baseR = ring.radius + CGFloat(smoothLevel * 10)
                            var path = Path()
                            let points = 120
                            for p in 0...points {
                                let angle = (Double(p) / Double(points)) * Double.pi * 2
                                let wobble1 = sin(angle * 3 + t * 2.0 + Double(idx) * 1.5) * (3 + smoothLevel * 12)
                                let wobble2 = sin(angle * 5 + t * 3.5 + Double(idx) * 2.3) * (2 + smoothLevel * 8)
                                let wobble3 = sin(angle * 7 + t * 1.8 + Double(idx) * 0.7) * (1 + smoothLevel * 5)
                                let r = baseR + CGFloat(wobble1 + wobble2 + wobble3)

                                let x = cx + CGFloat(cos(angle)) * r
                                let y = cy + CGFloat(sin(angle)) * r

                                if p == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            path.closeSubpath()

                            // Glow layer — thicker + fainter
                            context.stroke(
                                path,
                                with: .color(Color(hex: 0x30D158).opacity(ring.opacity * 0.3)),
                                lineWidth: ring.width * 3
                            )
                            // Main ring stroke
                            context.stroke(
                                path,
                                with: .color(Color(hex: 0x30D158).opacity(ring.opacity)),
                                lineWidth: ring.width
                            )
                        }

                        // Center dot — gently pulses with level
                        let dotR: CGFloat = 4 + CGFloat(smoothLevel * 3)
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: cx - dotR,
                                y: cy - dotR,
                                width: dotR * 2,
                                height: dotR * 2
                            )),
                            with: .color(Color(hex: 0x30D158).opacity(0.7))
                        )
                    }
                }
                .frame(width: 260, height: 260)
            }
            .frame(width: 280, height: 280)

            Text("LISTENING...")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
                .tracking(4)
        }
        .onChange(of: audio.liveLinearPeak) { newValue in
            let clamped = min(1.0, newValue * 4)
            if clamped > smoothLevel {
                withAnimation(.linear(duration: 0.03)) { smoothLevel = clamped }
            } else {
                withAnimation(.linear(duration: 0.12)) { smoothLevel = clamped }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: MeasurementConstants.listeningDuration)) {
                timerProgress = 1.0
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
