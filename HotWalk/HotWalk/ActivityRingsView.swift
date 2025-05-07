import SwiftUI

struct ActivityRingsView: View {
    let distance: Double // in kilometers
    let activeTime: TimeInterval // in seconds
    
    // Add property to check user's unit preference
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    // Add property to get distance unit
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    // Add property to convert distance
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371 // Convert km to miles
        }
        return kilometers
    }
    
    // Add property to format distance
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
    }
    
    // Distance goal in kilometers (will be converted to miles for non-metric users)
    private let distanceGoal: Double = 5.0 // 5 km or ~3.1 miles
    
    // Active time goal in minutes
    private let activeTimeGoal: TimeInterval = 30 * 60 // 30 minutes in seconds
    
    private var distanceProgress: Double {
        let convertedDistance = convertDistance(distance)
        let convertedGoal = convertDistance(distanceGoal)
        return min(convertedDistance / convertedGoal, 1.0)
    }
    
    private var activeTimeProgress: Double {
        min(activeTime / activeTimeGoal, 1.0)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Distance Ring
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: distanceProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text(formatDistance(distance))
                            .font(.system(size: 16, weight: .bold))
                        Text(distanceUnit)
                            .font(.system(size: 12))
                    }
                }
                .frame(width: 80, height: 80)
                
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Active Time Ring
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: activeTimeProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text(formatTime(activeTime))
                            .font(.system(size: 16, weight: .bold))
                        Text("active")
                            .font(.system(size: 12))
                    }
                }
                .frame(width: 80, height: 80)
                
                Text("Active Time")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ActivityRingsView(distance: 3.5, activeTime: 1800)
        .preferredColorScheme(.dark)
} 