import Foundation
import AVFoundation

@MainActor
final class MusicManager {

    static let shared = MusicManager()

    enum Scene: String, Codable {
        case menu
        case game
    }

    private var player: AVAudioPlayer?
    private var currentScene: Scene?
    private var lastRequestedScene: Scene = .menu

    private var isEnabled: Bool = true
    private var pausedByAppLifecycle: Bool = false

    private init() {}

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if !enabled {
            stop()
            return
        }

        pausedByAppLifecycle = false
        play(scene: lastRequestedScene, forceRestart: true)
    }

    func play(scene: Scene, forceRestart: Bool = false) {
        lastRequestedScene = scene
        currentScene = scene

        guard isEnabled else {
            stop()
            return
        }

        if pausedByAppLifecycle {
            return
        }

        if !forceRestart, player?.isPlaying == true, currentScene == scene {
            return
        }

        guard let url = resolveURL(for: scene) else {
            stop()
            return
        }

        do {
            try configureAudioSessionIfNeeded()

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 1.0
            newPlayer.prepareToPlay()
            newPlayer.play()

            player?.stop()
            player = newPlayer
        } catch {
            stop()
        }
    }

    func pauseForAppLifecycle() {
        pausedByAppLifecycle = true
        player?.pause()
    }

    func resumeForAppLifecycleIfNeeded() {
        guard pausedByAppLifecycle else { return }
        pausedByAppLifecycle = false

        guard isEnabled else {
            stop()
            return
        }

        if let p = player {
            p.play()
        } else {
            play(scene: lastRequestedScene, forceRestart: true)
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func resolveURL(for scene: Scene) -> URL? {
        let fileName: String
        switch scene {
        case .menu: fileName = "menu_music"
        case .game: fileName = "game_music"
        }

        let exts = ["mp3", "m4a", "wav"]
        return exts.compactMap { Bundle.main.url(forResource: fileName, withExtension: $0) }.first
    }

    private func configureAudioSessionIfNeeded() throws {
        let session = AVAudioSession.sharedInstance()

        if session.category != .ambient {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }

        try session.setActive(true)
    }
}
