import Foundation

struct MotivationalMessage: Codable, Identifiable {
    let id: String
    let text: String
    let category: MessageCategory
    let lastShown: Date?
}

enum MessageCategory: String, Codable {
    case veryLow = "0-25%"
    case low = "26-50%"
    case medium = "51-75%"
    case high = "76-99%"
    case complete = "100-149%"
    case overachiever = "150-199%"
    case legendary = "200%+"
    
    var messages: [String] {
        switch self {
        case .veryLow:
            return [
                "Hot girls don't ghost their goals 👻",
                "Let's get those steps steppin', queen 👠",
                "Still warming up? No worries. Hotness takes time 🔥",
                "You can't scroll your way to hotness. Let's go! 📱➡️👟",
                "Girl math: 100 steps = 1 sip of iced coffee ☕️",
                "Consider this your ✨main character montage✨ prep"
            ]
        case .low:
            return [
                "Look at you go, cardio queen 💅",
                "You're halfway to 'I don't need him anyway' energy",
                "She believed she could, so she put on sneakers 👟",
                "Half-walked hottie energy unlocked 💖",
                "Sweat, slay, repeat 🩷"
            ]
        case .medium:
            return [
                "You're not walking. You're gliding. Like a hot cloud ☁️",
                "Certified sidewalk runway model 🕶️",
                "Every step is one less reason to answer his texts 📵",
                "Walking away from the haters 🚶‍♀️💨",
                "The sidewalk's lucky to have you 💋"
            ]
        case .high:
            return [
                "Close enough to call it… but we don't quit around here 😘",
                "You're one podcast episode away from greatness 🎧",
                "You're about to make your future self cry from pride 😭",
                "Your hotness bar is almost maxed out 🧃",
                "This walk? Oscar-worthy. Best Supporting Steps 🎬"
            ]
        case .complete:
            return [
                "Step queen crowned 👑",
                "You crushed it like a hot girl summer lemonade 🍋",
                "If slay was a sport, you'd be in the Olympics 🥇",
                "Tell your enemies to stay mad 😌",
                "Even your shoes are clapping 👏"
            ]
        case .overachiever:
            return [
                "You didn't just walk. You WERKED 🔥",
                "Somebody's trying to break the app. We see you 💻💀",
                "There's hot… and then there's YOU 🔥🔥🔥",
                "Overachiever alert 🚨 You just unlocked mythical status 🦄",
                "You walked 1.5x your goal and somehow still look cute. Unfair."
            ]
        case .legendary:
            return [
                "Okay, calm down Beyoncé 💃 We get it",
                "We're renaming the app after you, obviously",
                "That wasn't a walk, that was a world tour 🌍",
                "NASA just called. You broke gravity 🚀",
                "Your sneakers have applied for workers' rights 👟📝"
            ]
        }
    }
}

class MotivationalMessageManager {
    static let shared = MotivationalMessageManager()
    private let userDefaults = UserDefaults.standard
    private let messageHistoryKey = "motivationalMessageHistory"
    private let messageExpirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {}
    
    private var messageHistory: [MotivationalMessage] {
        get {
            guard let data = userDefaults.data(forKey: messageHistoryKey),
                  let messages = try? JSONDecoder().decode([MotivationalMessage].self, from: data) else {
                return []
            }
            return messages
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: messageHistoryKey)
            }
        }
    }
    
    func getMessage(for progress: Double) -> String {
        let category = getCategory(for: progress)
        let availableMessages = category.messages.filter { message in
            !messageHistory.contains { $0.text == message && 
                ($0.lastShown?.timeIntervalSinceNow ?? -messageExpirationInterval) > -messageExpirationInterval }
        }
        
        let messagesToChooseFrom = availableMessages.isEmpty ? category.messages : availableMessages
        let selectedMessage = messagesToChooseFrom.randomElement() ?? category.messages[0]
        
        // Update message history
        let newMessage = MotivationalMessage(id: UUID().uuidString, 
                                           text: selectedMessage, 
                                           category: category, 
                                           lastShown: Date())
        messageHistory.append(newMessage)
        
        // Clean up old messages
        cleanupMessageHistory()
        
        return selectedMessage
    }
    
    private func getCategory(for progress: Double) -> MessageCategory {
        switch progress {
        case ..<0.25:
            return .veryLow
        case 0.25..<0.5:
            return .low
        case 0.5..<0.75:
            return .medium
        case 0.75..<1.0:
            return .high
        case 1.0..<1.5:
            return .complete
        case 1.5..<2.0:
            return .overachiever
        default:
            return .legendary
        }
    }
    
    private func cleanupMessageHistory() {
        let now = Date()
        messageHistory = messageHistory.filter { message in
            guard let lastShown = message.lastShown else { return false }
            return now.timeIntervalSince(lastShown) < messageExpirationInterval
        }
    }
} 