import SwiftUI

/// Tier-specific background motion (1–1.5s feel; loops while on result).
struct TierAnimationView: View {
    let tier: DapTier

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                switch tier {
                case .didYouEvenTouch:
                    drawDim(context: context, size: size, t: t)
                case .weakSauce:
                    drawMildShakeDots(context: context, size: size, t: t)
                case .respectable:
                    drawNodBars(context: context, size: size, t: t)
                case .crispy:
                    drawSparks(context: context, size: size, t: t)
                case .thunderclap:
                    drawBolts(context: context, size: size, t: t)
                case .earthquake:
                    drawConfetti(context: context, size: size, t: t)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawDim(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        var context = context
        let wobble = sin(t * 4) * 6
        context.opacity = 0.35 + sin(t * 2) * 0.05
        context.fill(
            Path(ellipseIn: CGRect(x: wobble, y: 0, width: size.width, height: size.height)),
            with: .color(.gray.opacity(0.25))
        )
    }

    private func drawMildShakeDots(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        for i in 0..<8 {
            let x = CGFloat(i) / 8.0 * size.width
            let y = size.height * 0.3 + sin(t * 2 + Double(i)) * 10
            let r = CGRect(x: x, y: y, width: 4, height: 4)
            context.fill(Path(ellipseIn: r), with: .color(Color(hex: 0xC7A94F).opacity(0.5)))
        }
    }

    private func drawNodBars(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        let mid = size.width / 2
        let bounce = sin(t * 5) * 8
        var p = Path()
        p.addRoundedRect(in: CGRect(x: mid - 40, y: size.height * 0.25 + bounce, width: 80, height: 12), cornerSize: CGSize(width: 6, height: 6))
        context.fill(p, with: .color(Color(hex: 0x4A90D9).opacity(0.45)))
    }

    private func drawSparks(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        for i in 0..<24 {
            let angle = Double(i) / 24.0 * Double.pi * 2 + t * 2
            let len = 40 + CGFloat(i % 5) * 8
            let x = size.width * 0.5 + CGFloat(cos(angle)) * len
            let y = size.height * 0.2 + CGFloat(sin(angle)) * len
            var p = Path()
            p.addEllipse(in: CGRect(x: x, y: y, width: 3, height: 10))
            context.fill(p, with: .color(Color(hex: 0xFF9500).opacity(0.65)))
        }
    }

    private func drawBolts(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        for i in 0..<5 {
            let x = CGFloat(i) / 5.0 * size.width + 20
            let y = size.height * 0.12 + CGFloat(sin(t * 8 + Double(i * 13))) * size.height * 0.12
            var p = Path()
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + 6, y: y + 40))
            p.addLine(to: CGPoint(x: x - 4, y: y + 70))
            context.stroke(p, with: .color(Color(hex: 0xAF52DE).opacity(0.8)), lineWidth: 3)
        }
    }

    private func drawConfetti(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        for i in 0..<60 {
            let x = CGFloat((i * 37) % Int(size.width))
            let y = CGFloat(fmod(t * 120 + Double(i * 17), Double(size.height)))
            let c = [Color(hex: 0xFF3B30), Color(hex: 0xFFD700), Color(hex: 0x30D158)][i % 3]
            let r = CGRect(x: x, y: y, width: 6, height: 10)
            context.fill(Path(ellipseIn: r), with: .color(c.opacity(0.85)))
        }
    }
}
