import SwiftUI
import FirebaseFirestore

struct RealityShowView: View {
    let stepsToday: Int
    let streakCount: Int
    @StateObject private var episodeManager = EpisodeManager()
    @State private var selectedEpisode: Episode? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(alignment: .center, spacing: 16) {
                    Text("You Walk, the Plot Thickens.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Text("""
You thought you were walking for your health? Sweetie, you're walking for the storyline.

Every milestone brings the tea: walk it out, watch it unfold. Think fake friends, real betrayal, and love triangles that don't quit.

Badges are cute. But episodes? Iconic.
""")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(24)
                .background(
                    Color.white.opacity(0.15)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Episodes Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Episodes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    ForEach(episodeManager.availableEpisodes) { episode in
                        let isUnlocked = episodeManager.unlockedEpisodes.contains { $0.id == episode.id }
                        EpisodeCard(
                            episode: episode,
                            isUnlocked: isUnlocked,
                            stepsToday: stepsToday,
                            streakCount: streakCount
                        )
                        .onTapGesture {
                            if isUnlocked {
                                selectedEpisode = episode
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(
                    Color.white.opacity(0.15)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255), // Dark purple
                    Color(red: 0.4, green: 0.2, blue: 0.4), // Medium purple
                    Color(hue: 0.83, saturation: 0.4, brightness: 0.8) // Darker purple
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            episodeManager.checkAndUnlockEpisodes(stepsToday: stepsToday, streakCount: streakCount)
        }
        .overlay {
            if let episode = selectedEpisode {
                EpisodePopupCard(episode: episode, isPresented: $selectedEpisode)
            }
        }
    }
}

struct EpisodeCard: View {
    let episode: Episode
    let isUnlocked: Bool
    let stepsToday: Int
    let streakCount: Int
    
    private var episodeNumber: Int {
        Int(episode.id.dropFirst(2)) ?? 0
    }
    
    private var backgroundGradient: LinearGradient {
        switch episode.unlockType {
        case .steps:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.6, blue: 0.9),
                    Color(red: 0.7, green: 0.3, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .streak:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.8, green: 0.4, blue: 0.8),
                    Color(red: 0.6, green: 0.2, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .invite:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.4, blue: 0.9),
                    Color(red: 0.4, green: 0.2, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .returnAfterMiss:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.4, blue: 0.7),
                    Color(red: 0.7, green: 0.2, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var unlockRequirement: some View {
        let hotPink = Color(red: 255/255, green: 20/255, blue: 147/255)
        let neonBlue = Color(hue: 0.83, saturation: 0.5, brightness: 1.0)
        
        switch episode.unlockType {
        case .steps:
            let remaining = max(0, episode.unlockValue - stepsToday)
            return remaining > 0 ? 
                AnyView(Text("\(remaining) more steps")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? hotPink : .white.opacity(0.6))) :
                AnyView(Image(systemName: "lock.open.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(neonBlue)
                    .shadow(color: neonBlue.opacity(0.8), radius: 8, x: 0, y: 0)
                    .shadow(color: neonBlue.opacity(0.4), radius: 12, x: 0, y: 0))
        case .streak:
            let remaining = max(0, episode.unlockValue - streakCount)
            return remaining > 0 ? 
                AnyView(Text("\(remaining) more days")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? hotPink : .white.opacity(0.6))) :
                AnyView(Image(systemName: "lock.open.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(neonBlue)
                    .shadow(color: neonBlue.opacity(0.8), radius: 8, x: 0, y: 0)
                    .shadow(color: neonBlue.opacity(0.4), radius: 12, x: 0, y: 0))
        case .invite:
            return AnyView(Text("Invite friends")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isUnlocked ? hotPink : .white.opacity(0.6)))
        case .returnAfterMiss:
            return streakCount == 1 ? 
                AnyView(Image(systemName: "lock.open.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(neonBlue)
                    .shadow(color: neonBlue.opacity(0.8), radius: 8, x: 0, y: 0)
                    .shadow(color: neonBlue.opacity(0.4), radius: 12, x: 0, y: 0)) :
                AnyView(Text("Return after missing a streak")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? hotPink : .white.opacity(0.6)))
        }
    }
    
    private var backgroundColor: Color {
        switch episode.unlockType {
        case .steps:
            return isUnlocked ? Color(hex: "2a9db6") : Color(hex: "8ac4d6") // Darker blue when unlocked, darker light blue when locked
        case .streak:
            return isUnlocked ? Color(hex: "8b47bb") : Color(hex: "b886d3") // Darker purple when unlocked, darker light purple when locked
        case .invite:
            return isUnlocked ? Color(hex: "c05e9d") : Color(hex: "d489b2") // Darker pink when unlocked, darker light pink when locked
        case .returnAfterMiss:
            return isUnlocked ? Color(hex: "8b47bb") : Color(hex: "b886d3") // Darker purple when unlocked, darker light purple when locked
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Episode Number
                Text("Episode \(episodeNumber)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.6))
                
                Spacer()
                
                // Unlock Status
                unlockRequirement
            }
            
            Text(episode.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.6))
                .padding(.vertical, 4)
            
            if isUnlocked {
                Text(episode.synopsis)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .opacity(isUnlocked ? 1.0 : 0.8)
    }
}

struct EpisodePopupCard: View {
    let episode: Episode
    @Binding var isPresented: Episode?
    
    private var episodeNumber: Int {
        Int(episode.id.dropFirst(2)) ?? 0
    }
    
    private var backgroundColor: Color {
        switch episode.unlockType {
        case .steps:
            return Color(hex: "2a9db6") // Darker blue
        case .streak:
            return Color(hex: "8b47bb") // Darker purple
        case .invite:
            return Color(hex: "c05e9d") // Darker pink
        case .returnAfterMiss:
            return Color(hex: "8b47bb") // Darker purple
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = nil
                }
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Episode \(episodeNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        isPresented = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                // Episode Title
                Text(episode.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Synopsis
                ScrollView {
                    Text(episode.synopsis)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                }
                
                // Unlock Info
                HStack {
                    Image(systemName: episode.unlockType == .steps ? "figure.walk" : "flame.fill")
                        .foregroundColor(.white)
                    Text("Unlocked at \(episode.unlockValue) \(episode.unlockType == .steps ? "steps" : "days")")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(backgroundColor)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isPresented != nil)
    }
}

#Preview {
    RealityShowView(stepsToday: 8500, streakCount: 3)
}

// Add Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
