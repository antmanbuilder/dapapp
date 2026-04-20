import AVFoundation

// NOTE: Add tier4.caf, tier5.caf, tier6.caf to DapApp/Sounds/ for reveal sounds.
// Without these files the app works fine — it just skips the audio flourish.

/// Short tier reveal sounds (optional — bundle `Sounds/*.caf` or `*.m4a` when added).
final class TierSoundService {
    private var player: AVAudioPlayer?

    func playReveal(for tier: DapTier) {
        guard tier.rawValue >= 4 else { return }
        let name: String
        switch tier {
        case .crispy: name = "tier4"
        case .thunderclap: name = "tier5"
        case .earthquake: name = "tier6"
        default: return
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "Sounds") else {
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            player = p
            p.play()
        } catch {
            player = nil
        }
    }
}
