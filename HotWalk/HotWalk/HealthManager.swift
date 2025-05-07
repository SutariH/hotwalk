import Foundation
import HealthKit

class HealthManager: ObservableObject {
    private var healthStore: HKHealthStore?
    @Published var steps: Int = 0
    @Published var distance: Double = 0 // in kilometers
    @Published var activeTime: TimeInterval = 0 // in seconds
    @Published var historicalSteps: [Date: Int] = [:]
    @Published var historicalDistance: [Date: Double] = [:]
    @Published var historicalActiveTime: [Date: TimeInterval] = [:]
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(false)
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        healthStore.requestAuthorization(toShare: [], read: [stepType, distanceType, activeEnergyType]) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func fetchTodayData() {
        fetchTodaySteps()
        fetchTodayDistance()
        fetchTodayActiveTime()
    }
    
    private func fetchTodaySteps() {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                self.steps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayDistance() {
        guard let healthStore = healthStore,
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                // Convert meters to kilometers
                self.distance = sum.doubleValue(for: HKUnit.meter()) / 1000.0
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayActiveTime() {
        guard let healthStore = healthStore,
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                // Convert kilocalories to time (approximate)
                // Assuming average person burns 100 calories per 15 minutes of walking
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                self.activeTime = (calories / 100.0) * 15.0 * 60.0 // Convert to seconds
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchHistoricalData(completion: @escaping ([Date: (steps: Int, distance: Double, activeTime: TimeInterval)]) -> Void) {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion([:])
            return
        }
        
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let stepQuery = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        let distanceQuery = HKStatisticsCollectionQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        let activeEnergyQuery = HKStatisticsCollectionQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        var results: [Date: (steps: Int, distance: Double, activeTime: TimeInterval)] = [:]
        let group = DispatchGroup()
        
        group.enter()
        stepQuery.initialResultsHandler = { _, statisticsCollection, _ in
            statisticsCollection?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    let date = statistics.startDate
                    results[date] = (steps: steps, distance: 0, activeTime: 0)
                }
            }
            group.leave()
        }
        
        group.enter()
        distanceQuery.initialResultsHandler = { _, statisticsCollection, _ in
            statisticsCollection?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let distance = sum.doubleValue(for: HKUnit.meter()) / 1000.0
                    let date = statistics.startDate
                    if var existing = results[date] {
                        existing.distance = distance
                        results[date] = existing
                    }
                }
            }
            group.leave()
        }
        
        group.enter()
        activeEnergyQuery.initialResultsHandler = { _, statisticsCollection, _ in
            statisticsCollection?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    let activeTime = (calories / 100.0) * 15.0 * 60.0
                    let date = statistics.startDate
                    if var existing = results[date] {
                        existing.activeTime = activeTime
                        results[date] = existing
                    }
                }
            }
            group.leave()
        }
        
        healthStore.execute(stepQuery)
        healthStore.execute(distanceQuery)
        healthStore.execute(activeEnergyQuery)
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    func getStepsForDate(_ date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return historicalSteps[startOfDay] ?? 0
    }
    
    func getDistanceForDate(_ date: Date) -> Double {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return historicalDistance[startOfDay] ?? 0
    }
    
    func getActiveTimeForDate(_ date: Date) -> TimeInterval {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return historicalActiveTime[startOfDay] ?? 0
    }
    
    func fetchStepsForDate(_ date: Date, completion: @escaping (Int) -> Void) {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(Int(sum.doubleValue(for: HKUnit.count())))
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchDistanceForDate(_ date: Date, completion: @escaping (Double) -> Void) {
        guard let healthStore = healthStore,
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(0)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(sum.doubleValue(for: HKUnit.meter()) / 1000.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchActiveTimeForDate(_ date: Date, completion: @escaping (TimeInterval) -> Void) {
        guard let healthStore = healthStore,
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            DispatchQueue.main.async {
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                completion((calories / 100.0) * 15.0 * 60.0)
            }
        }
        
        healthStore.execute(query)
    }
} 
