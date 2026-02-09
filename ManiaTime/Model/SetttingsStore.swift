
import Foundation
import Combine

@MainActor
final class SettingStore: ObservableObject {
    
    @Published private(set) var musicEnabled: Bool {
        didSet {
            ud.set(musicEnabled, forKey: keyMusicEnabled)
            MusicManager.shared.setEnabled(musicEnabled)
        }
    }
    
    private let ud: UserDefaults
    private let keyMusicEnabled = "mania.settings.musicEnabled.v1"
    
    init(userDefaults: UserDefaults = .standard) {
        self.ud = userDefaults
        self.musicEnabled = userDefaults.object(forKey: keyMusicEnabled) as? Bool ?? true
        
        MusicManager.shared.setEnabled(musicEnabled)
    }
    
    func toggleMusic() {
        musicEnabled.toggle()
    }
}

