import SwiftUI

/// Full-screen, Canvas-driven tier graphic. Every tier is its own private
/// subview so state (`animate`, flashes, shake timers) resets cleanly when
/// the tier changes. All drawing is done with `Canvas` paths and shapes —
/// no SF Symbols, no emoji, no system imagery anywhere in the stack.
struct TierGraphicView: View {
    let tier: DapTier

    var body: some View {
        ZStack {
            switch tier {
            case .didYouEvenTouch: Tier1View()
            case .weakSauce:       Tier2View()
            case .respectable:     Tier3View()
            case .crispy:          Tier4View()
            case .thunderclap:     Tier5View()
            case .earthquake:      Tier6View()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Determinstic PRNG helpers

/// Hash an integer seed to a deterministic Double in [0, 1). Fast enough
/// to call thousands of times per frame without dropping frames. Stable
/// across frames — only the frame-time component varies what gets fed in.
@inline(__always)
private func rand01(_ seed: Int) -> Double {
    // SplitMix64 variant — good dispersion for small-integer seeds.
    var x = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
    x ^= x &>> 30
    x = x &* 0xBF58476D1CE4E5B9
    x ^= x &>> 27
    x = x &* 0x94D049BB133111EB
    x ^= x &>> 31
    return Double(x % 1_000_000) / 1_000_000.0
}

/// Floating-point positive modulo — `truncatingRemainder` returns signed,
/// which breaks wrap-around for particles with negative drift.
@inline(__always)
private func posMod(_ v: Double, _ m: Double) -> Double {
    let r = v.truncatingRemainder(dividingBy: m)
    return r < 0 ? r + m : r
}

// MARK: - Tier 1 — "Did you even touch?" (Dead signal)

private struct Tier1View: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0A0A0A)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    // 1) TV static — 320 flickering 2x2 specks spread across
                    //    the entire screen. A 30Hz frame index is fed into
                    //    the seed so they reshuffle twice per video frame.
                    let staticFrame = Int(t * 30)
                    for i in 0..<320 {
                        let s = i &* 7919 &+ staticFrame &* 104729
                        let x = rand01(s) * Double(size.width)
                        let y = rand01(s &+ 1) * Double(size.height)
                        let a = 0.02 + rand01(s &+ 2) * 0.04
                        ctx.fill(
                            Path(CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(.white.opacity(a))
                        )
                    }

                    // 2) Slow scanline drifting top → bottom over 4 seconds.
                    let cycle = t.truncatingRemainder(dividingBy: 4.0) / 4.0
                    let scanY = CGFloat(cycle) * size.height
                    ctx.fill(
                        Path(CGRect(x: 0, y: scanY, width: size.width, height: 1)),
                        with: .color(.white.opacity(0.04))
                    )

                    // 3) Flatline across the middle third with a 0.5s glitch
                    //    jitter. Three-state hash keeps it feeling unstable.
                    let glitchSlot = Int(t * 2) // new jitter every 0.5s
                    let jitter = CGFloat((glitchSlot % 3) - 1) * 2.0 // -2, 0, 2
                    let lineY = size.height / 2 + jitter
                    let startX = size.width / 3
                    let endX = size.width * 2 / 3
                    var flat = Path()
                    flat.move(to: CGPoint(x: startX, y: lineY))
                    flat.addLine(to: CGPoint(x: endX, y: lineY))
                    ctx.stroke(flat, with: .color(.white.opacity(0.06)), lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tier 2 — "Weak sauce" (Fading out)

private struct Tier2View: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1A1408), Color(hex: 0x0D0A04)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let mud = Color(hex: 0x8B7355)

                    // 1) 18 mud-colored orbs sinking. Position/size/opacity
                    //    all seeded per-particle so they stay distinct.
                    for i in 0..<18 {
                        let radius = 20.0 + rand01(i &+ 100) * 40.0
                        let xPos = rand01(i &+ 200) * Double(size.width)
                        let speed = 15.0 + rand01(i &+ 300) * 15.0
                        let opacity = 0.08 + rand01(i &+ 400) * 0.07
                        let trackH = Double(size.height) + radius * 2.0
                        let phase = rand01(i) * trackH
                        let y = posMod(t * speed + phase, trackH) - radius

                        ctx.fill(
                            Path(ellipseIn: CGRect(
                                x: xPos - radius / 2,
                                y: y,
                                width: radius,
                                height: radius
                            )),
                            with: .color(mud.opacity(opacity))
                        )
                    }

                    // 2) Paint-drip lines slowly extending downward. Each
                    //    drip runs on its own 6s loop so they stagger.
                    for i in 0..<4 {
                        let xPos = rand01(i &+ 500) * Double(size.width)
                        let topY = rand01(i &+ 600) * 80.0
                        let period = 5.5 + rand01(i &+ 700) * 1.5
                        let phase = rand01(i &+ 800) * period
                        let cycle = posMod(t + phase, period) / period
                        let len = CGFloat(cycle) * size.height * 0.7

                        var drip = Path()
                        drip.move(to: CGPoint(x: xPos, y: topY))
                        drip.addLine(to: CGPoint(x: xPos, y: topY + len))
                        ctx.stroke(drip, with: .color(mud.opacity(0.1)), lineWidth: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tier 3 — "Respectable" (Clean pulse)

private struct Tier3View: View {
    @State private var startDate = Date()
    @State private var sweepProgress: CGFloat = 0

    private let ringColor = Color(hex: 0x007AFF)
    private let streakColor = Color(hex: 0x89D4FF)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(
                    colors: [Color(hex: 0x002855), Color(hex: 0x0A0A1A)],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.75
                )

                // 1) Blueprint grid — static, 40pt spacing, both axes.
                Canvas { ctx, size in
                    let spacing: CGFloat = 40
                    var x: CGFloat = 0
                    while x < size.width {
                        var v = Path()
                        v.move(to: CGPoint(x: x, y: 0))
                        v.addLine(to: CGPoint(x: x, y: size.height))
                        ctx.stroke(v, with: .color(.white.opacity(0.02)), lineWidth: 1)
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        var h = Path()
                        h.move(to: CGPoint(x: 0, y: y))
                        h.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(h, with: .color(.white.opacity(0.02)), lineWidth: 1)
                        y += spacing
                    }
                }

                // 2) Radar pings — 4 rings spawning 0.7s apart on a 2.8s loop.
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    Canvas { ctx, size in
                        guard size.width > 1, size.height > 1 else { return }
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let maxRadius = max(size.width, size.height) * 0.9
                        let loop = 2.8
                        let stagger = 0.7

                        for ring in 0..<4 {
                            let phase = elapsed - Double(ring) * stagger
                            if phase < 0 { continue }
                            let progress = posMod(phase, loop) / loop
                            let r = 20 + CGFloat(progress) * maxRadius
                            let op = 0.3 * (1.0 - progress)
                            ctx.stroke(
                                Path(ellipseIn: CGRect(
                                    x: center.x - r,
                                    y: center.y - r,
                                    width: r * 2,
                                    height: r * 2
                                )),
                                with: .color(ringColor.opacity(op)),
                                lineWidth: 2
                            )
                        }
                    }
                }

                // 3) Single L→R light streak that wipes across on entrance.
                LinearGradient(
                    colors: [.clear, streakColor.opacity(0.55), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.35, height: geo.size.height)
                .blur(radius: 10)
                .offset(x: (sweepProgress * 2 - 1) * geo.size.width)
                .blendMode(.plusLighter)
            }
        }
        .onAppear {
            startDate = Date()
            withAnimation(.easeOut(duration: 0.6)) {
                sweepProgress = 1
            }
        }
    }
}

// MARK: - Tier 4 — "That boy CRISPY" (Heat rising)

private struct Tier4View: View {
    @State private var glowPulse = false

    private static let emberColors: [Color] = [
        Color(hex: 0xFFD700),
        Color(hex: 0xFF6B35),
        Color(hex: 0xFF3B30)
    ]

    var body: some View {
        ZStack {
            // Deeper, richer amber base so the embers read as hot sparks
            // against real darkness — not faint orange on faint orange.
            LinearGradient(
                colors: [Color(hex: 0x1A0800), Color(hex: 0x4A1800)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 1) Heat shimmer — 3 oversized transparent orbs drifting up.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<3 {
                        let radius = 80.0 + rand01(i) * 40.0           // 80–120
                        let xBase = Double(size.width) * (0.2 + Double(i) * 0.3)
                        let wobble = sin(t * 0.7 + Double(i) * 1.3) * 30.0
                        let cx = xBase + wobble
                        let trackH = Double(size.height) + radius * 2.0
                        let phase = rand01(i &+ 50) * trackH
                        let drift = posMod(t * 22 + phase, trackH)
                        let cy = Double(size.height) + radius - drift

                        ctx.fill(
                            Path(ellipseIn: CGRect(
                                x: cx - radius,
                                y: cy - radius,
                                width: radius * 2,
                                height: radius * 2
                            )),
                            with: .color(Color(hex: 0xFF6B35).opacity(0.08))
                        )
                    }
                }
            }

            // 2) 50 rising embers — chunkier (4x8) and much brighter
            //    (0.4–0.9 flicker) so they read as real sparks.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    guard size.width > 1, size.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<50 {
                        let speed = 50.0 + rand01(i) * 50.0            // 50–100
                        let xBase = rand01(i &+ 100) * Double(size.width)
                        let wobble = sin(t * 1.5 + Double(i) * 0.37) * 20.0
                        let trackH = Double(size.height) + 40.0
                        let phase = rand01(i &+ 200) * trackH
                        let y = Double(size.height) - posMod(t * speed + phase, trackH)
                        let x = xBase + wobble
                        // 0.4 → 0.9 flicker on a per-particle sin phase.
                        let flicker = 0.4 + (sin(t * 5 + Double(i) * 2.1) + 1) * 0.25
                        let color = Self.emberColors[i % Self.emberColors.count]

                        ctx.fill(
                            Path(CGRect(x: x, y: y, width: 4, height: 8)),
                            with: .color(color.opacity(flicker))
                        )
                    }
                }
            }

            // 3) Left/right 30pt edge glows at 0.12 opacity.
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: 0xFF6B35).opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 30)

                Spacer(minLength: 0)

                LinearGradient(
                    colors: [.clear, Color(hex: 0xFF6B35).opacity(0.12)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 30)
            }

            // 4) Central pulsing radial glow — radius 200, 0.1 ↔ 0.2.
            RadialGradient(
                colors: [Color(hex: 0xFF6B35).opacity(glowPulse ? 0.2 : 0.1), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: glowPulse
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { glowPulse = true }
    }
}

// MARK: - Tier 5 — "Certified Thunderclap" (Electric storm)

private struct Tier5View: View {
    @State private var flashOpacity: Double = 0.7
    @State private var glowRadius: CGFloat = 200

    private let boltColor = Color(hex: 0xA29BFE)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(
                    colors: [Color(hex: 0x1A0A30), Color(hex: 0x0A0510)],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.75
                )

                // 1) Pulsing ambient energy field from the center.
                RadialGradient(
                    colors: [boltColor.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: glowRadius
                )

                // 2) Lightning bolts (3) + ambient arc crackles (15).
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    Canvas { ctx, size in
                        guard size.width > 1, size.height > 1 else { return }
                        let t = timeline.date.timeIntervalSinceReferenceDate

                        // Bolts regenerate every 0.3s — the frame index is
                        // fed into the seed so each window picks new endpoints.
                        let boltFrame = Int(t / 0.3)
                        for b in 0..<3 {
                            let seed = boltFrame &* 1_000 &+ b &* 31
                            let startX = rand01(seed) * Double(size.width)
                            let endX = rand01(seed &+ 1) * Double(size.width)
                            let segments = 7

                            var path = Path()
                            path.move(to: CGPoint(x: startX, y: 0))
                            for seg in 1...segments {
                                let progress = Double(seg) / Double(segments)
                                let baseX = startX + (endX - startX) * progress
                                let jitter = (rand01(seed &+ seg &* 17) - 0.5) * 80
                                path.addLine(to: CGPoint(
                                    x: baseX + jitter,
                                    y: Double(size.height) * progress
                                ))
                            }

                            ctx.stroke(path, with: .color(boltColor.opacity(0.3)), lineWidth: 8)
                            ctx.stroke(path, with: .color(boltColor), lineWidth: 2)
                        }

                        // Ambient arc sparks — 15 short segments flickering
                        // on/off at varied cadences to feel random.
                        let arcSlot = Int(t * 6) // ~6 state changes per second
                        for i in 0..<15 {
                            let onHash = rand01(arcSlot &+ i &* 13)
                            if onHash < 0.4 { continue }
                            let xs = rand01(i &+ 600) * Double(size.width)
                            let ys = rand01(i &+ 700) * Double(size.height)
                            let len = 20.0 + rand01(i &+ 800) * 20.0
                            let angle = rand01(i &+ 900) * .pi * 2
                            let x2 = xs + cos(angle) * len
                            let y2 = ys + sin(angle) * len

                            var arc = Path()
                            arc.move(to: CGPoint(x: xs, y: ys))
                            arc.addLine(to: CGPoint(x: x2, y: y2))
                            ctx.stroke(arc, with: .color(boltColor.opacity(0.55)), lineWidth: 1.5)
                        }
                    }
                }

                // 3) Entrance flash — quick 0.2s dissolve.
                Color.white
                    .opacity(flashOpacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                flashOpacity = 0
            }
            withAnimation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
            ) {
                glowRadius = 350
            }
        }
    }
}

// MARK: - Tier 6 — "Registered as an earthquake" (Total destruction)

private struct Tier6View: View {
    @State private var startDate = Date()
    @State private var flashOpacity: Double = 0.9
    @State private var shakeOffset: CGSize = .zero

    private static let confettiColors: [Color] = [
        Color(hex: 0xFF2D55),
        Color(hex: 0xFFD700),
        Color(hex: 0x30D158),
        .white
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // The shake + 1.3x overscan are applied to the inner content
                // so the edges never reveal the dark parent during quakes.
                content(in: geo.size)
                    .scaleEffect(1.3)
                    .offset(shakeOffset)
                    .clipped()

                // White entrance flash — sits on top so it whites out
                // everything including the shake-offset content. Short.
                Color.white
                    .opacity(flashOpacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startDate = Date()
            withAnimation(.easeOut(duration: 0.15)) {
                flashOpacity = 0
            }
            startShaking()
        }
    }

    private func content(in size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x4A0010), Color(hex: 0x8B0000)],
                startPoint: .top,
                endPoint: .bottom
            )

            // 1) Crack lines — 12 jagged spokes that grow from center over 1.5s.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, cs in
                    guard cs.width > 1, cs.height > 1 else { return }
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    let progress = min(1.0, CGFloat(elapsed / 1.5))
                    let center = CGPoint(x: cs.width / 2, y: cs.height / 2)
                    let maxReach = max(cs.width, cs.height) * 0.85

                    for i in 0..<12 {
                        let baseAngle = Double(i) / 12.0 * .pi * 2
                        let angleJitter = (rand01(i &+ 10) - 0.5) * 0.4
                        let angle = baseAngle + angleJitter
                        let segments = 8

                        var path = Path()
                        path.move(to: center)
                        for seg in 1...segments {
                            let segProgress = CGFloat(seg) / CGFloat(segments)
                            let len = maxReach * progress * segProgress
                            let segAngle = angle + (rand01(i &* 100 &+ seg) - 0.5) * 0.35
                            let x = center.x + CGFloat(cos(segAngle)) * len
                            let y = center.y + CGFloat(sin(segAngle)) * len
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        ctx.stroke(path, with: .color(Color(hex: 0xFF2D55).opacity(0.4)), lineWidth: 6)
                        ctx.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 2)
                    }
                }
            }

            // 2) Confetti burst — 60 rotating rectangles exploding from center,
            //    with gravity and a 3s fade to black.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, cs in
                    guard cs.width > 1, cs.height > 1 else { return }
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    let cx = cs.width / 2
                    let cy = cs.height / 2

                    for i in 0..<60 {
                        let angle = rand01(i) * .pi * 2
                        let speed = 200.0 + rand01(i &+ 1_000) * 300.0
                        let dx = cos(angle) * speed * elapsed
                        // a = 200 px/s² → displacement = 0.5·a·t² = 100·t²
                        let dy = sin(angle) * speed * elapsed + 100.0 * elapsed * elapsed
                        let x = cx + CGFloat(dx)
                        let y = cy + CGFloat(dy)

                        let rot = elapsed * (rand01(i &+ 2_000) * 4.0 + 2.0)
                        let op = max(0.0, 1.0 - elapsed / 3.0)
                        let color = Self.confettiColors[i % Self.confettiColors.count]
                        let rect = CGRect(x: -3, y: -1.5, width: 6, height: 3)
                        var shape = Path()
                        shape.addRect(rect)

                        ctx.drawLayer { layer in
                            layer.translateBy(x: x, y: y)
                            layer.rotate(by: .radians(rot))
                            layer.fill(shape, with: .color(color.opacity(op)))
                        }
                    }
                }
            }

            // 3) Seismograph strip — bottom 12% of the screen, amplitude
            //    decays 30 → 5 over 4 seconds, draws fresh each frame.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, cs in
                    guard cs.width > 1, cs.height > 1 else { return }
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    let decay = max(0.0, 1.0 - elapsed / 4.0)
                    let amp = 5.0 + 25.0 * decay
                    let bandTop = cs.height * 0.88
                    let midY = bandTop + cs.height * 0.06

                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: midY))
                    var x: CGFloat = 0
                    while x <= cs.width {
                        let phase = Double(x) * 0.18 + elapsed * 14.0
                        let y = midY + CGFloat(sin(phase) * amp)
                        p.addLine(to: CGPoint(x: x, y: y))
                        x += 2
                    }
                    ctx.stroke(p, with: .color(Color(hex: 0xFF2D55).opacity(0.9)), lineWidth: 2)
                }
            }

            // 4) Aftershock particles — 20 red dots drifting slowly in
            //    random directions, fading in and out forever.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                Canvas { ctx, cs in
                    guard cs.width > 1, cs.height > 1 else { return }
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let wrapW = Double(cs.width) + 40
                    let wrapH = Double(cs.height) + 40

                    for i in 0..<20 {
                        let baseX = rand01(i &+ 3_000) * Double(cs.width)
                        let baseY = rand01(i &+ 4_000) * Double(cs.height)
                        let speed = 10.0 + rand01(i &+ 5_000) * 10.0
                        let dirX = (rand01(i &+ 6_000) - 0.5) * 2.0
                        let dirY = (rand01(i &+ 7_000) - 0.5) * 2.0
                        let x = posMod(baseX + dirX * speed * t + 20, wrapW) - 20
                        let y = posMod(baseY + dirY * speed * t + 20, wrapH) - 20
                        let op = 0.3 + (sin(t * 2.0 + Double(i)) + 1.0) * 0.25

                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)),
                            with: .color(Color(hex: 0xFF2D55).opacity(op))
                        )
                    }
                }
            }
        }
    }

    /// Re-randomizes `shakeOffset` every 50ms for 3 seconds, then snaps
    /// back to zero. `Timer` is self-invalidating so no cleanup needed.
    private func startShaking() {
        let begin = Date()
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(begin)
            if elapsed >= 3.0 {
                timer.invalidate()
                shakeOffset = .zero
                return
            }
            shakeOffset = CGSize(
                width: CGFloat.random(in: -15...15),
                height: CGFloat.random(in: -15...15)
            )
        }
    }
}

// MARK: - Previews

#Preview("Tier 1 — Dead") {
    TierGraphicView(tier: .didYouEvenTouch)
}

#Preview("Tier 2 — Weak") {
    TierGraphicView(tier: .weakSauce)
}

#Preview("Tier 3 — Respectable") {
    TierGraphicView(tier: .respectable)
}

#Preview("Tier 4 — Crispy") {
    TierGraphicView(tier: .crispy)
}

#Preview("Tier 5 — Thunderclap") {
    TierGraphicView(tier: .thunderclap)
}

#Preview("Tier 6 — Earthquake") {
    TierGraphicView(tier: .earthquake)
}
