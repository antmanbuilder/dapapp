import UIKit

enum HapticService {
    static func play(for tier: DapTier) {
        switch tier {
        case .didYouEvenTouch, .weakSauce:
            break
        case .respectable:
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred()
        case .crispy:
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare()
            g.impactOccurred()
        case .thunderclap:
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.prepare()
            g.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                g.impactOccurred()
            }
        case .earthquake:
            let g = UIImpactFeedbackGenerator(style: .heavy)
            let n = UINotificationFeedbackGenerator()
            g.prepare()
            n.prepare()
            g.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                g.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                g.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                n.notificationOccurred(.success)
            }
        }
    }
}
