import SwiftUI
import AVFoundation

extension AVAudioPCMBuffer {
    /// Maximum absolute sample value in buffer (0...1 for normalized float).
    func peakLinearAmplitude() -> Double {
        guard let data = floatChannelData else { return 0 }
        let channels = Int(format.channelCount)
        let frames = Int(frameLength)
        var peak: Float = 0
        for ch in 0..<channels {
            let ptr = data[ch]
            for f in 0..<frames {
                peak = max(peak, abs(ptr[f]))
            }
        }
        return Double(peak)
    }
}

extension Double {
    /// Maps linear peak + global offset into a display dB value (tunable).
    func displayDecibelsFromLinearPeak() -> Double {
        let safe = max(self, MeasurementConstants.minimumLinearPeak)
        let dbfs = 20.0 * log10(safe)
        return dbfs + MeasurementConstants.dbDisplayOffset
    }
}
