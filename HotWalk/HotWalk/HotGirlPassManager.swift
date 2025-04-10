import Foundation

class HotGirlPassManager {
    static let shared = HotGirlPassManager()
    
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    
    private let passesKey = "hotGirlPasses"
    private let lastPassUsedKey = "lastPassUsedDate"
    private let lastPassEarnedKey = "lastPassEarnedDate"
    private let usedPassesKey = "usedPassesDates"
    private let lastMonthCheckedKey = "lastMonthChecked"
    private let lastMidnightCheckKey = "lastMidnightCheck"
    
    private init() {
        // Initialize passes if not set
        if defaults.object(forKey: passesKey) == nil {
            defaults.set(3, forKey: passesKey)
        }
        
        // Initialize used passes array if not set
        if defaults.object(forKey: usedPassesKey) == nil {
            defaults.set([String](), forKey: usedPassesKey)
        }
        
        // Check for monthly refill
        checkMonthlyRefill()
    }
    
    var currentPassCount: Int {
        get {
            checkMonthlyRefill()
            return defaults.integer(forKey: passesKey)
        }
    }
    
    private func checkMonthlyRefill() {
        let lastChecked = defaults.object(forKey: lastMonthCheckedKey) as? Date ?? Date()
        let currentDate = Date()
        
        // If we're in a new month, check for refill
        if !calendar.isDate(lastChecked, equalTo: currentDate, toGranularity: .month) {
            // Only refill if we have less than 3 passes
            if currentPassCount < 3 {
                let newCount = min(currentPassCount + 1, 3)
                defaults.set(newCount, forKey: passesKey)
            }
            defaults.set(currentDate, forKey: lastMonthCheckedKey)
        }
    }
    
    func checkAndApplyPassForPreviousDay(steps: Int, goal: Int) -> Bool {
        // Debug logging
        print("🔍 Checking pass usage for yesterday:")
        print("Steps: \(steps), Goal: \(goal)")
        
        // Guard against invalid data
        guard steps > 0, goal > 0 else {
            print("⚠️ Invalid data: steps or goal is 0")
            return false
        }
        
        let lastCheck = defaults.object(forKey: lastMidnightCheckKey) as? Date ?? Date()
        let currentDate = Date()
        
        // Only proceed if we haven't checked today
        guard !calendar.isDateInToday(lastCheck) else {
            print("⚠️ Already checked today")
            return false
        }
        
        // Get yesterday's date
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
            print("⚠️ Could not get yesterday's date")
            return false
        }
        
        // Check if we already used a pass for yesterday
        if wasPassUsed(on: yesterday) {
            print("⚠️ Pass already used for yesterday")
            return false
        }
        
        // If goal was met yesterday, no pass needed
        if Double(steps) >= Double(goal) {
            print("✅ Goal was met yesterday, no pass needed")
            return false
        }
        
        // If we have passes and goal wasn't met, use a pass
        if currentPassCount > 0 {
            print("💌 Using pass for yesterday")
            return usePass(for: yesterday)
        }
        
        print("⚠️ No passes available")
        return false
    }
    
    func usePass(for date: Date) -> Bool {
        guard currentPassCount > 0 else { return false }
        
        let newCount = currentPassCount - 1
        let dateString = getDailyKey(for: date)
        
        UserDefaults.standard.set(newCount, forKey: passesKey)
        
        var usedPasses = UserDefaults.standard.stringArray(forKey: usedPassesKey) ?? []
        usedPasses.append(dateString)
        UserDefaults.standard.set(usedPasses, forKey: usedPassesKey)
        
        UserDefaults.standard.set(Date(), forKey: lastMidnightCheckKey)
        UserDefaults.standard.synchronize()
        
        return true
    }
    
    func tryEarnPass(steps: Int, goal: Int) -> Bool {
        // Check if we already earned a pass today
        if let lastEarned = UserDefaults.standard.object(forKey: lastPassEarnedKey) as? Date,
           calendar.isDateInToday(lastEarned) {
            return false
        }
        
        // Check if we've reached 150% of the goal and have less than 3 passes
        if Double(steps) >= Double(goal) * 1.5 && currentPassCount < 3 {
            let newCount = min(currentPassCount + 1, 3)
            
            UserDefaults.standard.set(newCount, forKey: passesKey)
            UserDefaults.standard.set(Date(), forKey: lastPassEarnedKey)
            UserDefaults.standard.synchronize()
            
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
    
    private func getDailyKey(for date: Date) -> String {
        return DateFormatterManager.shared.dailyKeyFormatter.string(from: date)
    }
} 