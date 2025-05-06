import Foundation

class EpisodeManager: ObservableObject {
    @Published private(set) var unlockedEpisodes: [Episode] = []
    let availableEpisodes: [Episode]
    private let defaults = UserDefaults.standard
    private let unlockedEpisodesKey = "unlockedEpisodes"
    
    init() {
        self.availableEpisodes = episodes // Using the global episodes array
        resetUnlockedEpisodes() // Reset stored episodes
        loadUnlockedEpisodes()
    }
    
    private func resetUnlockedEpisodes() {
        defaults.removeObject(forKey: unlockedEpisodesKey)
    }
    
    private func loadUnlockedEpisodes() {
        if let data = defaults.data(forKey: unlockedEpisodesKey),
           let decoded = try? JSONDecoder().decode([Episode].self, from: data) {
            unlockedEpisodes = decoded
        }
    }
    
    private func saveUnlockedEpisodes() {
        if let encoded = try? JSONEncoder().encode(unlockedEpisodes) {
            defaults.set(encoded, forKey: unlockedEpisodesKey)
        }
    }
    
    func checkAndUnlockEpisodes(stepsToday: Int, streakCount: Int) {
        var newEpisodesUnlocked = false
        
        for episode in availableEpisodes {
            if !unlockedEpisodes.contains(where: { $0.id == episode.id }) {
                let shouldUnlock: Bool
                
                switch episode.unlockType {
                case .steps:
                    shouldUnlock = stepsToday >= episode.unlockValue
                case .streak:
                    shouldUnlock = streakCount >= episode.unlockValue
                case .invite:
                    shouldUnlock = false // Implement invite logic when needed
                case .returnAfterMiss:
                    shouldUnlock = stepsToday > 0 && streakCount == 1 // Unlock when returning after a missed streak
                }
                
                if shouldUnlock {
                    unlockedEpisodes.append(episode)
                    newEpisodesUnlocked = true
                }
            }
        }
        
        if newEpisodesUnlocked {
            saveUnlockedEpisodes()
        }
    }
    
    func getViewershipRating(steps: Int) -> String {
        switch steps {
        case 0:
            return "No one's watching… yet."
        case 1..<3000:
            return "She posted a teaser. Intrigue is building."
        case 3000..<7000:
            return "Mid-tier scandal energy. Viewers engaged."
        case 7000..<10000:
            return "Full storyline unlocked. You're trending."
        default:
            return "She broke the app. Ratings are astronomical."
        }
    }
} 