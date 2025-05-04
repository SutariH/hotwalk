import Foundation
import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var steps: Int = 0
    @Published var historicalSteps: [Date: Int] = [:]
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchTodaySteps()
                self.fetchHistoricalSteps()
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
    
    func fetchHistoricalSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else { return }
            
            var stepsByDate: [Date: Int] = [:]
            
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                let date = statistics.startDate
                stepsByDate[date] = steps
            }
            
            DispatchQueue.main.async {
                self.historicalSteps = stepsByDate
            }
        }
        
        healthStore.execute(query)
    }
    
    func getStepsForDate(_ date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return historicalSteps[startOfDay] ?? 0
    }
} 