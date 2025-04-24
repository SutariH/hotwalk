import Foundation
import HealthKit
import UserNotifications

class BackgroundHealthManager: ObservableObject {
    static let shared = BackgroundHealthManager()
    
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let userDefaults = UserDefaults.standard
    private let lastNotificationKey = "last50PercentNotificationDate"
    
    private let motivational50Messages = [
        "You're 50% there and already 100% iconic.",
            "Halfway, honey. Time to sashay the rest of that sidewalk.",
            "Midway through the walk, fully in your power.",
            "50% done? Baby, the glow-up is in motion.",
            "You've hit the halfway mark — keep strutting like the world is your stage.",
            "Half your goal, twice the fabulous. Keep going!",
            "That was the warm-up, darling. Let's give them something to gag on.",
            "50% of your steps and 100% that baddie.",
            "Halfway down the street, halfway to legendary.",
            "You just hit 50% — now flip your hair and finish strong.",
            "Midway milestone unlocked. The rest is your runway.",
            "You're only halfway but already turning heads.",
            "50% done? That walk is giving main character energy.",
            "Slayed half the day's steps — now let's dominate the rest.",
            "Halfway there and not a single step wasted.",
            "Keep going, hot stuff. The strut's just getting started.",
            "You're 50% in and fully serving.",
            "Half the steps, all the sparkle.",
            "You're halfway and the sidewalk is still trembling.",
            "Strutting into part two like a queen late to brunch.",
            "Midway? Mood: unstoppable.",
            "Halfway through and you're still a 10 outta 10.",
            "50% in and still giving life with every step.",
            "You've got that halfway hustle, baby.",
            "Half a walk, whole lotta hotness.",
            "The glow is getting stronger — you're at 50%!",
            "Half the steps, full throttle fab.",
            "You're halfway, and honestly? The ground's lucky to feel your footsteps.",
            "Halfway mark: hit. Aura: unmatched.",
            "You + 50% progress = absolute slay.",
            "Midway and still walking like you're holding a crown.",
            "Keep strutting — the world isn't ready for 100% you.",
            "Halfway steps but already legendary vibes.",
            "Only halfway? Feels like you've already conquered the world.",
            "Half your goal met. Full glam energy detected.",
            "You're halfway there. Now channel Beyoncé and finish it out.",
            "50% = the foreplay. Let's get to the main event.",
            "Halfway. Fabulous. Fierce. Finish it.",
            "Halfway and looking like a fitness goddess.",
            "50% down and radiating pure slay.",
            "Midway point reached. Now give 'em face, legs, and power.",
            "Halfway done? The world's just catching up to your pace.",
            "50% means the confetti is loading...",
            "That halfway mark never looked so hot.",
            "Halfway and hotter than a fresh blowout.",
            "You've made it halfway — now turn this walk into a performance.",
            "That's 50% of your goal and 100% sparkle.",
            "Halfway steps = halfway to Hot Girl legend status.",
            "You've hit 50%, now unleash the rest of the slay.",
            "Halfway there, and still not a single step wasted. You absolute queen."
    ]
    
    private init() {
        setupBackgroundDelivery()
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
            
            self.checkFor50PercentGoal()
            completionHandler()
        }
        
        healthStore.execute(observerQuery)
    }
    
    private func checkFor50PercentGoal() {
        // Get the current day's step count
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
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
            
            // Check if we've already sent a notification today
            let lastNotificationDate = self.userDefaults.object(forKey: self.lastNotificationKey) as? Date
            let isSameDay = calendar.isDate(lastNotificationDate ?? Date.distantPast, inSameDayAs: now)
            
            if steps >= Double(dailyGoal) * 0.5 && !isSameDay {
                self.send50PercentNotification()
            }
        }
        
        healthStore.execute(statisticsQuery)
    }
    
    private func send50PercentNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Hot Girl Alert! 🎉"
            content.body = "You're halfway to your daily goal! Keep slaying those steps, queen!"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
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
