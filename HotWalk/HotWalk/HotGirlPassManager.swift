import Foundation

class HotGirlPassManager {
    static let shared = HotGirlPassManager()
    
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    
    private let passesKey = "hotGirlPasses"
    private let lastPassUsedKey = "lastPassUsedDate"
    private let lastPassEarnedKey = "lastPassEarnedDate"
    private let usedPassesKey = "usedPassesDates"
    
    private init() {
        // Initialize passes if not set
        if defaults.object(forKey: passesKey) == nil {
            defaults.set(3, forKey: passesKey)
        }
        
        // Initialize used passes array if not set
        if defaults.object(forKey: usedPassesKey) == nil {
            defaults.set([String](), forKey: usedPassesKey)
        }
        
        // Check if we need to reset passes for a new month
        checkAndResetPassesForNewMonth()
    }
    
    var currentPassCount: Int {
        get {
            checkAndResetPassesForNewMonth()
            return defaults.integer(forKey: passesKey)
        }
    }
    
    private func checkAndResetPassesForNewMonth() {
        let lastUsedDate = defaults.object(forKey: lastPassUsedKey) as? Date ?? Date()
        let currentDate = Date()
        
        // If we're in a new month, reset passes to 3
        if !calendar.isDate(lastUsedDate, equalTo: currentDate, toGranularity: .month) {
            defaults.set(3, forKey: passesKey)
        }
    }
    
    func usePass() -> Bool {
        guard currentPassCount > 0 else { return false }
        
        let newCount = currentPassCount - 1
        defaults.set(newCount, forKey: passesKey)
        
        // Store the date when the pass was used
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        var usedPasses = defaults.stringArray(forKey: usedPassesKey) ?? []
        usedPasses.append(today)
        defaults.set(usedPasses, forKey: usedPassesKey)
        
        defaults.set(Date(), forKey: lastPassUsedKey)
        return true
    }
    
    func tryEarnPass(steps: Int, goal: Int) -> Bool {
        // Check if we already earned a pass today
        if let lastEarned = defaults.object(forKey: lastPassEarnedKey) as? Date,
           calendar.isDateInToday(lastEarned) {
            return false
        }
        
        // Check if we've reached 125% of the goal
        if Double(steps) >= Double(goal) * 1.25 && currentPassCount < 3 {
            let newCount = min(currentPassCount + 1, 3)
            defaults.set(newCount, forKey: passesKey)
            defaults.set(Date(), forKey: lastPassEarnedKey)
            return true
        }
        
        return false
    }
    
    func wasPassUsed(on date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let usedPasses = defaults.stringArray(forKey: usedPassesKey) ?? []
        return usedPasses.contains(dateString)
    }
} 