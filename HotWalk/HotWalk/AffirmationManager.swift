import Foundation

class AffirmationManager {
    static let shared = AffirmationManager()
    
    private let defaults = UserDefaults.standard
    private let lastShownIndexKey = "lastShownAffirmationIndex"
    private let affirmations: [String]
    private var shuffledIndices: [Int]
    
    private init() {
        // Initialize affirmations list
        self.affirmations = [
            "The universe is obsessed with my strides today",
            "I radiate confidence with every step I take",
            "I am magnetic and glowing from the inside out",
            "Every step I take brings me closer to my dream life",
            "I walk like I already have everything I want",
            "My energy is irresistible and inspiring",
            "I move with purpose, power, and poise",
            "Today, I choose to be my highest self",
            "I am becoming the woman I've always dreamed of",
            "There's nothing I can't do when I believe in myself",
            "I walk away from fear and into my power",
            "I attract love, abundance, and peace with every step",
            "I'm not just hot—I'm healing, growing, and glowing",
            "My footsteps echo confidence and self-love",
            "I am aligned, grounded, and glowing",
            "The world adjusts to my energy, not the other way around",
            "Walking clears my mind and charges my spirit",
            "I am exactly where I'm meant to be",
            "I'm walking in my purpose and owning my power",
            "Every step fuels my body and feeds my soul"
            // Add more affirmations here...
        ]
        
        // Initialize shuffled indices
        self.shuffledIndices = Array(0..<affirmations.count).shuffled()
        
        // If we've shown all affirmations, reshuffle
        if let lastIndex = defaults.integer(forKey: lastShownIndexKey) as Int?,
           lastIndex >= affirmations.count - 1 {
            reshuffleIndices()
        }
    }
    
    private func reshuffleIndices() {
        shuffledIndices = Array(0..<affirmations.count).shuffled()
        defaults.set(-1, forKey: lastShownIndexKey)
    }
    
    func getNextAffirmation() -> String {
        let lastIndex = defaults.integer(forKey: lastShownIndexKey)
        let nextIndex = lastIndex + 1
        
        // If we've shown all affirmations, reshuffle
        if nextIndex >= affirmations.count {
            reshuffleIndices()
            return getNextAffirmation()
        }
        
        // Get the next affirmation
        let affirmationIndex = shuffledIndices[nextIndex]
        defaults.set(nextIndex, forKey: lastShownIndexKey)
        
        return affirmations[affirmationIndex]
    }
} 