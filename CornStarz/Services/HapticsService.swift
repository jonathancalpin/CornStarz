import CoreHaptics

class HapticsService {
    private var engine: CHHapticEngine?

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }

    func playThrowRelease() {
        playPattern(intensity: 0.8, sharpness: 0.9, duration: 0.1)
    }

    func playLandingMiss() {
        playPattern(intensity: 0.4, sharpness: 0.3, duration: 0.2)
    }

    func playOnTarget() {
        playPattern(intensity: 0.6, sharpness: 0.6, duration: 0.15)
    }

    func playRinger() {
        // Celebration burst — multiple quick taps
        guard let engine = engine else { return }

        var events: [CHHapticEvent] = []
        for i in 0..<5 {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: Double(i) * 0.08
            )
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic playback failed: \(error)")
        }
    }

    private func playPattern(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard let engine = engine else { return }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: duration
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic playback failed: \(error)")
        }
    }
}
