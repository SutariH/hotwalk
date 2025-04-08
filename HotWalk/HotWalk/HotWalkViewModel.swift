import Foundation
import SwiftUI

class HotWalkViewModel: ObservableObject {
    @Published var dailyGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        }
    }
    
    init() {
        self.dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        if self.dailyGoal == 0 {
            self.dailyGoal = 10000 // Default goal
        }
    }
    
    func getMotivationalMessage(progress: Double) -> String {
        return MotivationalMessageManager.shared.getMessage(for: progress)
    }
    
    func calculateProgress(steps: Int) -> Double {
        return Double(steps) / Double(dailyGoal)
    }
} 