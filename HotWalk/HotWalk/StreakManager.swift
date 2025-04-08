import Foundation

class StreakManager {
    static let shared = StreakManager()
    private let userDefaults = UserDefaults.standard
    
    private let streakCountKey = "streakCount"
    private let lastSuccessDateKey = "lastSuccessDate"
    
    private init() {}
    
    var currentStreak: Int {
        get {
            return userDefaults.integer(forKey: streakCountKey)
        }
        set {
            userDefaults.set(newValue, forKey: streakCountKey)
        }
    }
    
    private var lastSuccessDate: Date? {
        get {
            return userDefaults.object(forKey: lastSuccessDateKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: lastSuccessDateKey)
        }
    }
    
    func updateStreak(progress: Double) {
        guard progress >= 1.0 else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastSuccess = lastSuccessDate {
            let lastSuccessDay = calendar.startOfDay(for: lastSuccess)
            
            if calendar.isDate(lastSuccessDay, inSameDayAs: today) {
                // Already counted for today
                return
            } else if calendar.isDate(lastSuccessDay, equalTo: today, toGranularity: .day) {
                // Same day, do nothing
                return
            } else if let daysBetween = calendar.dateComponents([.day], from: lastSuccessDay, to: today).day,
                      daysBetween == 1 {
                // Next day, increment streak
                currentStreak += 1
            } else {
                // More than one day gap, reset streak
                currentStreak = 1
            }
        } else {
            // First time reaching goal
            currentStreak = 1
        }
        
        lastSuccessDate = today
    }
    
    func getStreakText() -> String {
        return "🔥 \(currentStreak)-day streak"
    }
} 