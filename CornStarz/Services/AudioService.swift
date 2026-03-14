import AVFoundation

class AudioService {
    private var players: [String: AVAudioPlayer] = [:]

    func preload(sounds: [String]) {
        for name in sounds {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                print("Sound file not found: \(name).wav")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[name] = player
            } catch {
                print("Failed to load sound \(name): \(error)")
            }
        }
    }

    func play(_ name: String) {
        players[name]?.currentTime = 0
        players[name]?.play()
    }
}
