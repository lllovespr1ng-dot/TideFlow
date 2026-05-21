import AVFoundation
import UIKit

/// Plays a soft piano-like note and triggers haptic feedback.
/// Uses a singleton so the AVAudioEngine is never torn down between taps.
class FeedbackManager {

    static let shared = FeedbackManager()

    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    private init() {
        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    // MARK: - Public actions

    /// Light haptic + C5 note — adding a task or tapping a preset.
    func taskAdded() {
        impact(.light)
        playNote(frequency: 523.25, decaySpeed: 7.0, volume: 0.28)   // C5
    }

    /// Medium haptic + E5 note — completing a task.
    func taskCompleted() {
        impact(.medium)
        playNote(frequency: 659.25, decaySpeed: 6.0, volume: 0.30)   // E5
    }

    // MARK: - Private helpers

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    /// Renders a brief piano-like tone (sine wave + second harmonic, exponential decay).
    private func playNote(frequency: Float, decaySpeed: Float, volume: Float) {
        let frameCount = AVAudioFrameCount(sampleRate * 0.5)   // 0.5 s max
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData?[0]
        let sr   = Float(sampleRate)

        for i in 0..<Int(frameCount) {
            let t        = Float(i) / sr
            let envelope = exp(-t * decaySpeed) * volume
            let fundamental = sin(2 * .pi * frequency * t)
            let harmonic    = sin(2 * .pi * frequency * 2 * t) * 0.18
            data?[i] = (fundamental + harmonic) * envelope
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }
}
