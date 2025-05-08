import Foundation

// ShaylaBot is the AI companion for Hot Girl Steps
class ShaylaBot: ObservableObject {
    static let shared = ShaylaBot()
    private let botName = "Shayla (Not Real But Still Obsessed With You)"
    @Published var userGoal: Int {
        didSet {
            if oldValue != userGoal {
                updateSteps() // Only update if goal actually changed
            }
        }
    }
    
    @Published var stepsToday: Int = 0
    @Published var lastStepsUpdate: Date = Date()
    @Published var todaysMessage: String = ""
    @Published var showMessageButton: Bool = false
    private var lastMessageDate: Date?
    private var lastMessageShown: Bool = false
    private var lastGoalCheck: Date = Date()
    private let goalCheckInterval: TimeInterval = 3600 // Check every hour for morning time
    private var morningCheckTimer: Timer?
    
    private init() {
        // Get goal from UserDefaults
        self.userGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        if self.userGoal == 0 {
            self.userGoal = 5000 // Default goal changed from 10000 to 5000
        }
        
        // Start with initial steps
        updateSteps()
        
        // Set up timer for periodic updates
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateSteps()
            self?.checkForMessage()
        }
        
        // Set up morning check timer
        setupMorningCheckTimer()
    }
    
    private func setupMorningCheckTimer() {
        // Check every hour for morning time
        morningCheckTimer = Timer.scheduledTimer(withTimeInterval: goalCheckInterval, repeats: true) { [weak self] _ in
            self?.checkForMorningGoalUpdate()
        }
    }
    
    private func checkForMorningGoalUpdate() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Check if it's morning (between 6 AM and 7 AM)
        if hour == 6 {
            // Check if we haven't updated the goal today
            let lastCheckDay = calendar.component(.day, from: lastGoalCheck)
            let currentDay = calendar.component(.day, from: now)
            
            if lastCheckDay != currentDay {
                let newGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
                if newGoal != userGoal && newGoal > 0 {
                    userGoal = newGoal
                    lastGoalCheck = now
                }
            }
        }
    }
    
    private func checkForMessage() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we already sent a message today
        if let lastMessage = lastMessageDate {
            let lastMessageDay = calendar.component(.day, from: lastMessage)
            let currentDay = calendar.component(.day, from: now)
            if lastMessageDay == currentDay {
                return // Already sent a message today
            }
        }
        
        let hour = calendar.component(.hour, from: now)
        let progress = Double(stepsToday) / Double(userGoal)
        
        // Send message if it's afternoon (2 PM or later) or user has reached 50% of their goal
        if hour >= 14 || progress >= 0.5 {
            todaysMessage = getMotivationalMessage()
            lastMessageDate = now
            lastMessageShown = false
            showMessageButton = true
        }
    }
    
    func getMessage() -> String? {
        let calendar = Calendar.current
        let now = Date()
        
        // If no message has been set for today, return nil
        guard let lastMessage = lastMessageDate else { return nil }
        
        // Check if the message is from today
        let lastMessageDay = calendar.component(.day, from: lastMessage)
        let currentDay = calendar.component(.day, from: now)
        
        if lastMessageDay == currentDay && !lastMessageShown {
            lastMessageShown = true
            showMessageButton = false // Hide the button after showing the message
            return todaysMessage
        }
        
        return nil
    }
    
    func generateSteps() -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Morning boost (6 AM - 12 PM)
        let isMorning = hour >= 6 && hour < 12
        let baseProgress = isMorning ? 0.6 : 0.4 // 60% of goal in morning, 40% in afternoon
        
        // Random factor for variation
        let randomFactor = Double.random(in: 0...1)
        let finalMultiplier: Double
        
        if randomFactor < 0.8 {
            // 80% chance of reaching goal
            finalMultiplier = baseProgress
        } else if randomFactor < 0.9 {
            // 10% chance of missing goal
            finalMultiplier = baseProgress * 0.7
        } else {
            // 10% chance of exceeding goal
            finalMultiplier = baseProgress * 1.5
        }
        
        // Generate base steps
        let baseSteps = Int(Double(userGoal) * finalMultiplier)
        
        // Add random variation to make it look more natural
        let randomVariation = Int.random(in: -247...389) // Random number that doesn't end in 0
        
        // Ensure the final number doesn't end in 0
        var finalSteps = baseSteps + randomVariation
        while finalSteps % 10 == 0 {
            finalSteps += Int.random(in: 1...9)
        }
        
        return finalSteps
    }
    
    func updateSteps() {
        stepsToday = generateSteps()
        lastStepsUpdate = Date()
    }
    
    func getMotivationalMessage() -> String {
        let messages = [
            "Omg babe, your steps are poppin' off today 🔥",
            "Just saw your count — are you WALKING or levitating?? 💫",
            "Not me needing a nap just watching you slay these steps 😮‍💨",
            "You're literally main character-ing all over this sidewalk rn 🎬",
            "Did your shoes just hit turbo mode?? 💨👟",
            "Ok wow… that streak?? Legendary behavior. 👑",
            "I swear, your step count just gave me goosebumps",
            "Walking like you've got somewhere to be and someone to impress. Love it. 💅",
            "Friendly reminder: you're out here SERVING with every step 🍽️",
            "I'm gonna need to catch up — you're leaving us all in the dust!",
            "That's it. I'm giving your sneakers a standing ovation rn. 👏",
            "Are you… training for something? Or just casually being iconic?",
            "Girl. GIRL. I saw your progress today and gasped. 😭",
            "You're making me wanna lace up and get my life together",
            "Step count is giving: unstoppable, untouchable, unreal",
            "That sidewalk should be thanking YOU tbh",
            "I'd text you more but I don't wanna slow you down 😉",
            "Honestly, if this were a race, you already won 🏁",
            "Shayla here, just hyping up your excellence as always 💕",
            "Every time I check your steps, I get a little more obsessed 🥹",
            "Keep walking, queen! 👑"
        ]
        return messages.randomElement() ?? "Keep walking, queen! 👑"
    }
} 
