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
                "Halfway there and looking fabulous 💅",
                "You're giving main character energy 🌟",
                "The sidewalk is your runway, bestie 👠",
                "Your steps are giving influencer vibes 📱",
                "You're in your element and it shows 💫",
                "This walk? A whole mood board 🎨",
                "Serving steps with a side of style 💃",
                "The concrete can't handle your confidence 💅",
                "You're walking like rent is due tomorrow 💸",
                "Your steps are giving 'that girl' energy ✨",
                "Walking like you own the block (you do) 👑",
                "This isn't a walk, it's a moment 📸",
                "Your steps are giving 'it girl' vibes 💅",
                "You're walking like you've got tea to spill ☕️",
                "Strutting like you've got insider info 🤫"
            ]
        case .high:
            return [
                "Close enough to call it… but we don't quit around here 😘",
                "You're one podcast episode away from greatness 🎧",
                "You're about to make your future self cry from pride 😭",
                "Your hotness bar is almost maxed out 🧃",
                "This walk? Oscar-worthy. Best Supporting Steps 🎬",
                "This isn't a walk. This is your acceptance speech 👑",
                "You're walking like the sidewalk owes you rent 💸",
                "Almost there — make the concrete jealous 💅",
                "Every step is a slay. Keep the camera rolling 🎥",
                "Only a few steps away from being legally iconic 💼✨",
                "Your aura is glowing and your steps are showing 💖",
                "Finish strong, sugarplum. The crown's within reach 👠",
                "You're at 90%. That's legally a diva entrance 💃",
                "Walk faster — your future self is waiting with confetti 🎉",
                "Don't stop now — you're making the sidewalk emotional 😭"
            ]
        case .complete:
            return [
                "Step queen crowned 👑",
                "You crushed it like a hot girl summer lemonade 🍋",
                "If slay was a sport, you'd be in the Olympics 🥇",
                "Tell your enemies to stay mad 😌",
                "Even your shoes are clapping 👏",
                "Your walk just earned a five-star Yelp review from the universe ⭐️⭐️⭐️⭐️⭐️",
                "Achievement: unlocked. Outfit: immaculate. Vibes: undefeated 🔓👗🌟",
                "The runway called — it wants its walk back 💃📞",
                "You didn't just walk. You closed the show in couture 👠✨",
                "Stepped your way into legend status. Again. 🔥",
                "Today's walk has been nominated for Best Motion Picture 🎬🏆",
                "Every step was a serve and you didn't even break a sweat 💅",
                "That strut was so smooth, GPS lost track of you 📍💨",
                "You just invented a new genre of fabulous 🚀👑",
                "Hot Girl Steps? More like Hot Girl HISTORY 📖💖"
            ]
        case .overachiever:
            return [
                "You didn't just walk. You WERKED 🔥",
                "Somebody's trying to break the app. We see you 💻💀",
                "There's hot… and then there's YOU 🔥🔥🔥",
                "Overachiever alert 🚨 You just unlocked mythical status 🦄",
                "You walked 1.5x your goal and somehow still look cute. Unfair.",
                "You didn't just go the extra mile — you moonwalked it 🌕👟",
                "Over 150%? You're in rare air, babe 💨👑",
                "The sidewalk filed a complaint — you're too powerful 💅🚷",
                "You hit 1.5x and still had time to save the world 🦸‍♀️✨",
                "Overachiever? More like over-iconic 🔥",
                "You just turned a walk into a performance art piece 🎭",
                "That wasn't fitness, that was a spiritual awakening 🔮",
                "Step count? Maxed out. Energy? Unmatched 🔋",
                "You walked so far, Google Maps asked for directions 🗺️📍"
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