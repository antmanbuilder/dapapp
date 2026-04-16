import WatchKit

enum WatchHaptics {
    static func play(for tier: DapTier) {
        let device = WKInterfaceDevice.current()
        switch tier {
        case .didYouEvenTouch, .weakSauce:
            break
        case .respectable:
            device.play(.click)
        case .crispy:
            device.play(.directionUp)
        case .thunderclap:
            device.play(.directionUp)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                device.play(.failure)
            }
        case .earthquake:
            device.play(.notification)
        }
    }
}
