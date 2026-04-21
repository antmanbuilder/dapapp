import SwiftUI

/// Full-frame SwiftUI-rendered tier graphics — replaces the static emoji
/// and the previous `TierAnimationView` background. Each tier is its own
/// subview so entrance state (`animate`) is reset when the tier changes.
struct TierGraphicView: View {
    let tier: DapTier

    var body: some View {
        ZStack {
            switch tier {
            case .didYouEvenTouch: Tier1Ghost()
            case .weakSauce:       Tier2WeakSauce()
            case .respectable:     Tier3Respectable()
            case .crispy:          Tier4Crispy()
            case .thunderclap:     Tier5Thunderclap()
            case .earthquake:      Tier6Earthquake()
            }
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

// MARK: - Tier 1 — Did you even touch? (Ghost / broken)

private struct Tier1Ghost: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { _ in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    for _ in 0..<220 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let a = Double.random(in: 0.04...0.18)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                            with: .color(.white.opacity(a))
                        )
                    }
                }
            }

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 120))
                .foregroundStyle(.white)
                .opacity(0.08)
                .blur(radius: 8)

            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let seed = Int(t * 20)
                let jx = CGFloat(((seed &* 9301 &+ 49297) % 233280)) / 233280.0 * 14 - 7
                let jy = CGFloat(((seed &* 1597 &+ 51749) % 233280)) / 233280.0 * 6 - 3
                Text("???")
                    .font(AppFont.display(size: 68))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.55))
                    .offset(x: jx, y: jy)
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Tier 2 — Weak sauce (Deflated)

private struct Tier2WeakSauce: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<8 {
                        let phase = Double(i) * 0.31
                        let travel = fmod(t * 14 + phase * 120, Double(size.height + 60))
                        let y = size.height - CGFloat(travel)
                        let x = size.width * CGFloat(0.1 + (Double(i) * 0.11).truncatingRemainder(dividingBy: 0.8))
                        let r: CGFloat = 6 + CGFloat(i % 3) * 3
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                            with: .color(Color(hex: 0x8B7355).opacity(0.18))
                        )
                    }
                }
            }

            Image(systemName: "hand.thumbsdown.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color(hex: 0x8B7355))
                .rotationEffect(.degrees(animate ? 7 : -7))
                .offset(y: animate ? 4 : -2)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .saturation(0.7)
        .onAppear { animate = true }
    }
}

// MARK: - Tier 3 — Respectable (Clean, dignified)

private struct Tier3Respectable: View {
    @State private var animate = false
    @State private var sweepX: CGFloat = -1.2

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.35), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.55, height: geo.size.height)
                .offset(x: sweepX * geo.size.width)
                .blendMode(.plusLighter)

                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(Color(hex: 0x007AFF))
                    .opacity(0.5)
                    .blur(radius: 22)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animate)

                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(Color(hex: 0x007AFF))
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.55), value: animate)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                animate = true
                withAnimation(.easeInOut(duration: 1.4)) { sweepX = 1.2 }
            }
        }
    }
}

// MARK: - Tier 4 — Crispy (Fire)

private struct Tier4Crispy: View {
    @State private var animate = false

    private static let emberColors: [Color] = [
        Color(hex: 0xFFD700),
        Color(hex: 0xFF9500),
        Color(hex: 0xFF3B30)
    ]

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<40 {
                        let seed = Double(i) * 12.345
                        let speed = 32 + fmod(seed, 34)
                        let travel = fmod(t * speed + seed * 7, Double(size.height + 40))
                        let y = size.height - CGFloat(travel)
                        let xBase = CGFloat((i &* 97) % Int(max(1, size.width)))
                        let x = xBase + CGFloat(sin(t * 2 + seed)) * 6
                        let flick = 0.35 + sin(t * 6 + seed) * 0.3
                        let color = Self.emberColors[i % Self.emberColors.count]
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 6)),
                            with: .color(color.opacity(max(0.1, flick)))
                        )
                    }
                }
            }

            Image(systemName: "flame.fill")
                .font(.system(size: 140))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xFFD700),
                            Color(hex: 0xFF9500),
                            Color(hex: 0xFF3B30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: 0xFF6B35).opacity(0.85), radius: 30)
                .scaleEffect(animate ? 1.0 : 0.3)
                .animation(.spring(response: 0.55, dampingFraction: 0.5), value: animate)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Tier 5 — Thunderclap (Lightning)

private struct Tier5Thunderclap: View {
    @State private var animate = false
    @State private var flashOpacity: Double = 0.6

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    Canvas { ctx, size in
                        guard size.width > 1, size.height > 1 else { return }
                        let t = timeline.date.timeIntervalSinceReferenceDate

                        var bolt = Path()
                        let startX = size.width / 2
                        bolt.move(to: CGPoint(x: startX, y: 0))
                        let steps = 6
                        for i in 1...steps {
                            let progress = CGFloat(i) / CGFloat(steps)
                            let y = progress * size.height * 0.5
                            let jitter = CGFloat(sin(t * 18 + Double(i) * 1.7)) * 20
                            bolt.addLine(to: CGPoint(x: startX + jitter, y: y))
                        }
                        ctx.stroke(bolt, with: .color(Color(hex: 0xA29BFE).opacity(0.55)), lineWidth: 10)
                        ctx.stroke(bolt, with: .color(.white), lineWidth: 3)

                        for i in 0..<8 {
                            let onLeft = i < 4
                            let baseX: CGFloat = onLeft
                                ? CGFloat((i &* 13) % 32) + 4
                                : size.width - (CGFloat((i &* 11) % 32) + 4)
                            let baseY = CGFloat((i &* 73) % Int(max(1, size.height)))
                            var arc = Path()
                            arc.move(to: CGPoint(x: baseX, y: baseY))
                            arc.addLine(to: CGPoint(
                                x: baseX + CGFloat(cos(t * 10 + Double(i))) * 16,
                                y: baseY + 10
                            ))
                            arc.addLine(to: CGPoint(
                                x: baseX + CGFloat(sin(t * 11 + Double(i))) * 12,
                                y: baseY + 22
                            ))
                            let flicker = sin(t * 16 + Double(i) * 1.3) > 0 ? 0.85 : 0.1
                            ctx.stroke(
                                arc,
                                with: .color(Color(hex: 0xA29BFE).opacity(flicker)),
                                lineWidth: 2
                            )
                        }
                    }
                }

                Image(systemName: "bolt.fill")
                    .font(.system(size: 130))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xA29BFE), Color(hex: 0x6C5CE7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: 0x6C5CE7).opacity(0.85), radius: 25)
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55), value: animate)

                Color.white
                    .opacity(flashOpacity)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                animate = true
                withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
            }
        }
    }
}

// MARK: - Tier 6 — Earthquake (Destruction)

private struct Tier6Earthquake: View {
    @State private var animate = false
    @State private var flashOpacity: Double = 0.8
    @State private var startDate = Date()

    private static let confettiColors: [Color] = [
        Color(hex: 0xFF2D55),
        Color(hex: 0xFFD700),
        Color(hex: 0x30D158),
        .white
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1 — radial cracks growing outward
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    Canvas { ctx, size in
                        guard size.width > 1, size.height > 1 else { return }
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        let progress = min(1.0, CGFloat(elapsed / 1.5))
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let reach = max(size.width, size.height) * 0.6

                        for i in 0..<12 {
                            let angle = Double(i) / 12.0 * .pi * 2
                            let endX = center.x + CGFloat(cos(angle)) * reach * progress
                            let endY = center.y + CGFloat(sin(angle)) * reach * progress
                            let midX = center.x + (endX - center.x) * 0.55
                                + CGFloat(cos(angle * 3)) * 14
                            let midY = center.y + (endY - center.y) * 0.55
                                + CGFloat(sin(angle * 3)) * 14
                            var p = Path()
                            p.move(to: center)
                            p.addLine(to: CGPoint(x: midX, y: midY))
                            p.addLine(to: CGPoint(x: endX, y: endY))
                            ctx.stroke(p, with: .color(Color(hex: 0xFF2D55).opacity(0.55)), lineWidth: 6)
                            ctx.stroke(p, with: .color(.white), lineWidth: 2)
                        }
                    }
                }

                // Layer 2 — seismograph along the bottom 15%
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    Canvas { ctx, size in
                        guard size.width > 1, size.height > 1 else { return }
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        let bandTop = size.height * 0.85
                        let midY = bandTop + size.height * 0.075
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: midY))
                        var x: CGFloat = 0
                        let step: CGFloat = 3
                        while x <= size.width {
                            let phase = Double(x) * 0.09 + t * 7
                            let amp = sin(phase) * 28 + sin(phase * 2.3) * 12
                            p.addLine(to: CGPoint(x: x, y: midY + CGFloat(amp)))
                            x += step
                        }
                        ctx.stroke(p, with: .color(Color(hex: 0xFF2D55).opacity(0.35)), lineWidth: 6)
                        ctx.stroke(p, with: .color(Color(hex: 0xFFD700)), lineWidth: 2)
                    }
                }

                // Layer 3 — confetti exploding outward from center
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    Canvas { ctx, size in
                        guard size.width > 1, size.height > 1 else { return }
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        let cx = size.width / 2
                        let cy = size.height / 2
                        for i in 0..<80 {
                            let seed = Double(i)
                            let angle = seed * 0.7853 + sin(seed * 1.7) * 0.9
                            let speed = 180 + fmod(seed * 37.1, 220)
                            let dx = CGFloat(cos(angle)) * CGFloat(speed) * CGFloat(elapsed)
                            let dy = CGFloat(sin(angle)) * CGFloat(speed) * CGFloat(elapsed)
                                + 240 * CGFloat(elapsed * elapsed)
                            let rot = elapsed * (seed.truncatingRemainder(dividingBy: 6) + 2)
                            let x = cx + dx
                            let y = cy + dy
                            let color = Self.confettiColors[i % Self.confettiColors.count]
                            let rect = CGRect(x: -5, y: -3, width: 10, height: 6)
                            var shape = Path()
                            shape.addRoundedRect(in: rect, cornerSize: CGSize(width: 2, height: 2))
                            ctx.drawLayer { layer in
                                layer.translateBy(x: x, y: y)
                                layer.rotate(by: .radians(rot))
                                layer.fill(shape, with: .color(color.opacity(0.92)))
                            }
                        }
                    }
                }

                Image(systemName: "waveform.path")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xFF2D55), Color(hex: 0xFFD700)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: 0xFF2D55).opacity(0.7), radius: 20)
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(.spring(response: 0.45, dampingFraction: 0.4), value: animate)

                Color.white
                    .opacity(flashOpacity)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                startDate = Date()
                animate = true
                withAnimation(.easeOut(duration: 0.15)) { flashOpacity = 0 }
            }
        }
    }
}

#Preview("Earthquake") {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        TierGraphicView(tier: .earthquake)
            .frame(height: 250)
    }
}

#Preview("Thunderclap") {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        TierGraphicView(tier: .thunderclap)
            .frame(height: 250)
    }
}

#Preview("Crispy") {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        TierGraphicView(tier: .crispy)
            .frame(height: 250)
    }
}

#Preview("Ghost") {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()
        TierGraphicView(tier: .didYouEvenTouch)
            .frame(height: 250)
    }
}
