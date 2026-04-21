import AVFoundation

/// Short UX + tier-reveal sounds. Place files in `DapApp/Sounds/` (bundled as a folder reference).
/// Accepts `.caf` (preferred), `.m4a`, or `.mp3`. Missing files are a no-op — the flow still works.
final class TierSoundService {
    private var players: [AVAudioPlayer] = []

    private func play(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds") else {
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            players.removeAll { !$0.isPlaying }
            players.append(p)
            p.play()
        } catch {}
    }

    func playTap() { play("tap") }
    func playTick() { play("tick") }
    func playGo() { play("go") }
    func playDrumroll() { play("drumroll") }

    func playReveal(for tier: DapTier) {
        switch tier {
        case .didYouEvenTouch, .weakSauce: play("reveal-low")
        case .respectable: play("reveal-mid")
        case .crispy: play("reveal-fire")
        case .thunderclap: play("reveal-thunder")
        case .earthquake: play("reveal-quake")
        }
    }

    func playTierMusic(for tier: DapTier) {
        switch tier {
        case .didYouEvenTouch, .weakSauce: play("music-low")
        case .respectable: break // chime is enough
        case .crispy, .thunderclap: play("music-hype")
        case .earthquake: play("music-legendary")
        }
    }
}
