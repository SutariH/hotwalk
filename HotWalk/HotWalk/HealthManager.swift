import Foundation
import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var steps: Int = 0
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchTodaySteps()
            }
        }
    }
    
    func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                self.steps = Int(sum.doubleValue(for: .count()))
            }
        }
        
        healthStore.execute(query)
    }
} 