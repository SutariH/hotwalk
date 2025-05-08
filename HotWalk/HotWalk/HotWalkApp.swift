import SwiftUI
import FirebaseCore
import FirebaseAuth
import Mixpanel

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    
    init() {
        // Check initial auth state
        if let _ = Auth.auth().currentUser {
            isAuthenticated = true
        }
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
            }
        }
    }
}

@main
struct HotWalkApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var invitationService = InvitationService()
    
    init() {
        FirebaseApp.configure()
        Mixpanel.initialize(token: "7e548ac53a395d3a60177f024398bfba", trackAutomaticEvents: true)
    }
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if appState.isAuthenticated {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        Task {
            do {
                try await invitationService.handleInvitationLink(url)
            } catch {
                print("Error handling deep link: \(error.localizedDescription)")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize BackgroundHealthManager
        _ = BackgroundHealthManager.shared
        return true
    }
} 