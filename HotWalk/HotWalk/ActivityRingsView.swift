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
        HStack(spacing: 36) {
            // Distance Ring
            VStack {
                ZStack {
                    // Halo ring when closed
                    if distanceProgress >= 0.999 {
                        Circle()
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 16)
                            .frame(width: 96, height: 96)
                            .blur(radius: 8)
                    }
                    // Background ring with enhanced glow
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.purple.opacity(0.5),
                                    Color.pink.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 2)
                        .mask(Circle().stroke(Color.white, lineWidth: 8).frame(width: 80, height: 80))
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    Circle()
                        .stroke(Color.purple.opacity(0.18), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: distanceProgress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 1)
                    VStack(spacing: 4) {
                        Text(formatDistance(distance))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80, height: 80)
                .padding(.bottom, 0)
                Text("Distance")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 10)
            }
            .frame(minWidth: 44)
            
            // Active Time Ring
            VStack {
                ZStack {
                    // Halo ring when closed
                    if activeTimeProgress >= 0.999 {
                        Circle()
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 16)
                            .frame(width: 96, height: 96)
                            .blur(radius: 8)
                    }
                    // Background ring with enhanced glow
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.purple.opacity(0.5),
                                    Color.pink.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 2)
                        .mask(Circle().stroke(Color.white, lineWidth: 8).frame(width: 80, height: 80))
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    Circle()
                        .stroke(Color.purple.opacity(0.18), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: activeTimeProgress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 1)
                    VStack(spacing: 4) {
                        Text(formatTime(activeTime))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80, height: 80)
                .padding(.bottom, 0)
                Text("Active Time")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 10)
            }
            .frame(minWidth: 44)
        }
    }
}

#Preview {
    ActivityRingsView(distance: 3.5, activeTime: 1800)
        .preferredColorScheme(.dark)
} 