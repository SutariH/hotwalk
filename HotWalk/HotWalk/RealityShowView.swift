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
                    Text("The Camera's Rolling.\nYou're Already Late.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                    
                    Text("You thought this was just a walk? Think again.")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    Text("Every step writes a new episode in the most iconic fake reality show the internet's never seen.\n\nClaudia's spiraling. Diego's watching. You're walking straight into your main character era.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(20)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                
                // Episodes Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Episodes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                    
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
                .padding(20)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255),
                    Color.purple.opacity(0.3),
                    Color(hue: 0.83, saturation: 0.3, brightness: 0.9)
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
    
    private var unlockRequirement: some View {
        let hotPink = Color(red: 255/255, green: 20/255, blue: 147/255)
        let neonBlue = Color(hue: 0.83, saturation: 0.5, brightness: 1.0)
        
        switch episode.unlockType {
        case .steps:
            let remaining = max(0, episode.unlockValue - stepsToday)
            return remaining > 0 ? 
                AnyView(Text("\(remaining) more steps")
                    .font(.subheadline)
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
                    .foregroundColor(isUnlocked ? hotPink : .white.opacity(0.6))) :
                AnyView(Image(systemName: "lock.open.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(neonBlue)
                    .shadow(color: neonBlue.opacity(0.8), radius: 8, x: 0, y: 0)
                    .shadow(color: neonBlue.opacity(0.4), radius: 12, x: 0, y: 0))
        case .invite:
            return AnyView(Text("Invite friends")
                .font(.subheadline)
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
                    .foregroundColor(isUnlocked ? hotPink : .white.opacity(0.6)))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Episode Number
                Text("Episode \(episodeNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.6))
                
                Spacer()
                
                // Unlock Status
                unlockRequirement
            }
            
            Text(episode.title)
                .font(.headline)
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
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.8)
    }
}

struct EpisodePopupCard: View {
    let episode: Episode
    @Binding var isPresented: Episode?
    
    private var episodeNumber: Int {
        Int(episode.id.dropFirst(2)) ?? 0
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
                        .foregroundColor(.purple)
                    Text("Unlocked at \(episode.unlockValue) \(episode.unlockType == .steps ? "steps" : "days")")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color(red: 44/255, green: 8/255, blue: 52/255))
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