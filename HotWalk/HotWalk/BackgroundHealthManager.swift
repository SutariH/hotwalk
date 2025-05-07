import Foundation
import HealthKit
import UserNotifications

class BackgroundHealthManager: ObservableObject {
    static let shared = BackgroundHealthManager()
    
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let userDefaults = UserDefaults.standard
    private let lastNotificationKey = "lastNotificationDate"
    private let lastMessageKey = "lastNotificationMessage"
    
    // Notification thresholds
    private let notificationThresholds: [(percentage: Double, key: String)] = [
        (0.5, "last50PercentNotificationDate"),
        (0.8, "last80PercentNotificationDate"),
        (1.0, "last100PercentNotificationDate")
    ]
    
    // Motivational messages for each milestone
    private let motivationalMessages: [Double: [String]] = [
        0.5: [
        "You're 50% there and already 100% iconic.",
            "Halfway, honey. Time to sashay the rest of that sidewalk.",
            "Midway through the walk, fully in your power.",
            "50% done? Baby, the glow-up is in motion.",
            "You've hit the halfway mark — keep strutting like the world is your stage.",
            "Half your goal, twice the fabulous. Keep going!",
            "That was the warm-up, darling. Let's give them something to gag on.",
            "50% of your steps and 100% that baddie.",
            "Halfway down the street, halfway to legendary.",
            "You just hit 50% — now flip your hair and finish strong."
        ],
        0.8: [
            "80% there and serving absolute excellence!",
            "Almost there, queen! The finish line is your runway.",
            "80% done? More like 100% slayage in progress.",
            "You're at 80% and the sidewalk is still trembling!",
            "Almost to the finish line, and you're still giving main character energy.",
            "80% of your goal met, 100% of the world's attention captured.",
            "The final stretch is here, and you're walking it like you own it.",
            "80% down, but your energy is at 200%!",
            "Almost there, hot stuff! The crown is within reach.",
            "80% complete and still turning heads like it's your job."
        ],
        1.0: [
            "GOALS ACHIEVED! You absolute queen! 👑",
            "Hot girl walk? Completed it, mastered it, owned it!",
            "Step count? SLAYED. Goals? ACHIEVED. Day? MADE.",
            "You did it! The sidewalk is officially your runway.",
            "Mission accomplished! Time to celebrate your hot girl victory!",
            "Goals? Met. Steps? Counted. Day? Dominated.",
            "You've reached 100% and the world is still catching up!",
            "Hot girl walk completed! Now go treat yourself, you deserve it!",
            "100% done and 100% that baddie!",
            "You've conquered your step goal! The crown looks good on you!"
        ]
    ]
    
    private init() {
        setupBackgroundDelivery()
        setupNotificationCategories()
    }
    
    private func setupBackgroundDelivery() {
        // Check if we have the necessary permissions
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // Request authorization for background delivery
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                // Enable background delivery
                self.healthStore.enableBackgroundDelivery(for: self.stepType, frequency: .immediate) { success, error in
                    if success {
                        self.setupObserverQuery()
                    }
                }
            }
        }
    }
    
    private func setupObserverQuery() {
        let observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error in observer query: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self.checkForGoalMilestones()
            completionHandler()
        }
        
        healthStore.execute(observerQuery)
    }
    
    private func checkForGoalMilestones() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // Check if we've already sent a notification today
        let lastNotificationDate = userDefaults.object(forKey: lastNotificationKey) as? Date
        let isSameDay = calendar.isDate(lastNotificationDate ?? Date.distantPast, inSameDayAs: now)
        
        // If we've already sent a notification today, don't proceed
        if isSameDay {
            return
        }
        
        let statisticsQuery = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] query, statistics, error in
            guard let self = self,
                  let statistics = statistics,
                  let sum = statistics.sumQuantity() else { return }
            
            let steps = sum.doubleValue(for: HKUnit.count())
            let dailyGoal = self.userDefaults.integer(forKey: "dailyGoal")
            
            // Check each threshold
            for (percentage, key) in self.notificationThresholds {
                let threshold = Double(dailyGoal) * percentage
                let lastNotificationDate = self.userDefaults.object(forKey: key) as? Date
                let hasNotifiedToday = calendar.isDate(lastNotificationDate ?? Date.distantPast, inSameDayAs: now)
            
                if steps >= threshold && !hasNotifiedToday {
                    // Save the notification date before sending
                    self.userDefaults.set(now, forKey: key)
                    self.userDefaults.set(now, forKey: self.lastNotificationKey)
                    self.sendMilestoneNotification(percentage: percentage)
                    break // Only send one notification per check
                }
            }
        }
        
        healthStore.execute(statisticsQuery)
    }
    
    private func sendMilestoneNotification(percentage: Double) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = self.getNotificationTitle(for: percentage)
            content.body = self.getRandomMessage(for: percentage)
            content.sound = .default
            content.categoryIdentifier = "STEP_GOAL_NOTIFICATION"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "step_goal_\(Int(percentage * 100))_percent_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
            // Set review prompt flag if 100% goal notification
            if percentage == 1.0 {
                UserDefaults.standard.set(true, forKey: "shouldPromptForReview")
            }
        }
    }
    
    private func getNotificationTitle(for percentage: Double) -> String {
        switch percentage {
        case 0.5:
            return "Hot Girl Alert! 🎉"
        case 0.8:
            return "Almost There! ✨"
        case 1.0:
            return "Goals Achieved! 👑"
        default:
            return "Step Update! 🚶‍♀️"
        }
    }
    
    private func getRandomMessage(for percentage: Double) -> String {
        guard let messages = motivationalMessages[percentage] else { return "" }
        
        // Get the last used message
        let lastMessage = userDefaults.string(forKey: lastMessageKey) ?? ""
        
        // Filter out the last used message
        let availableMessages = messages.filter { $0 != lastMessage }
        
        // If all messages were used, reset and use any message
        let selectedMessage = availableMessages.randomElement() ?? messages.randomElement() ?? ""
        
        // Save the selected message
        userDefaults.set(selectedMessage, forKey: lastMessageKey)
        
        return selectedMessage
    }
    
    // Add notification category setup
    private func setupNotificationCategories() {
        let category = UNNotificationCategory(
            identifier: "STEP_GOAL_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func checkAuthorizationStatus() -> Bool {
        let notificationCenter = UNUserNotificationCenter.current()
        var hasNotificationPermission = false
        
        let semaphore = DispatchSemaphore(value: 0)
        
        notificationCenter.getNotificationSettings { settings in
            hasNotificationPermission = settings.authorizationStatus == .authorized
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 1)
        
        return HKHealthStore.isHealthDataAvailable() &&
               healthStore.authorizationStatus(for: stepType) == .sharingAuthorized &&
               hasNotificationPermission
    }
} 
