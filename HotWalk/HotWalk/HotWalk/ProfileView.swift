import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var authManager = AuthManager()
    @State private var showingEditSheet = false
    @State private var showingLogoutAlert = false
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 44/255, green: 8/255, blue: 52/255),
                        Color(red: 0.4, green: 0.2, blue: 0.4),
                        Color(hue: 0.83, saturation: 0.4, brightness: 0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            VStack(spacing: 16) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                                
                                Text(userProfile?.displayName ?? "User")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(userProfile?.email ?? "")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            
                            // Stats Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your Stats")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 20) {
                                    StatCard(
                                        title: "Total Steps",
                                        value: "\(userProfile?.totalSteps ?? 0)",
                                        icon: "figure.walk"
                                    )
                                    
                                    StatCard(
                                        title: "Friends",
                                        value: "\(userProfile?.friendCount ?? 0)",
                                        icon: "person.2.fill"
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Settings Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Settings")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Button(action: { showingEditSheet = true }) {
                                    SettingsRow(
                                        title: "Edit Profile",
                                        icon: "pencil",
                                        color: .blue
                                    )
                                }
                                
                                Button(action: { showingLogoutAlert = true }) {
                                    SettingsRow(
                                        title: "Log Out",
                                        icon: "arrow.right.square",
                                        color: .red
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView(profile: userProfile) { updatedProfile in
                    userProfile = updatedProfile
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
        .onAppear {
            fetchUserProfile()
        }
    }
    
    private func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid, !userId.isEmpty else {
            print("Error: No valid user ID found")
            isLoading = false
            return
        }
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let data = snapshot?.data() {
                userProfile = UserProfile(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    totalSteps: data["totalSteps"] as? Int ?? 0,
                    friendCount: data["friendCount"] as? Int ?? 0
                )
            } else {
                // Create new profile if it doesn't exist
                createNewProfile(userId: userId)
            }
            isLoading = false
        }
    }
    
    private func createNewProfile(userId: String) {
        guard let email = Auth.auth().currentUser?.email else { return }
        
        let newProfile = UserProfile(
            id: userId,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            totalSteps: 0,
            friendCount: 0
        )
        
        do {
            try db.collection("users").document(userId).setData(from: newProfile)
            userProfile = newProfile
        } catch {
            print("Error creating user profile: \(error.localizedDescription)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let displayName: String
    var totalSteps: Int
    var friendCount: Int
}

struct EditProfileView: View {
    let profile: UserProfile?
    let onSave: (UserProfile) -> Void
    @State private var displayName: String
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    init(profile: UserProfile?, onSave: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _displayName = State(initialValue: profile?.displayName ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 44/255, green: 8/255, blue: 52/255),
                        Color(red: 0.4, green: 0.2, blue: 0.4),
                        Color(hue: 0.83, saturation: 0.4, brightness: 0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: saveProfile) {
                        Text("Save Changes")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.5, green: 0.2, blue: 0.5),
                                        Color(red: 0.4, green: 0.1, blue: 0.4)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(displayName.isEmpty)
                    .opacity(displayName.isEmpty ? 0.6 : 1)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid,
              !userId.isEmpty,
              let email = Auth.auth().currentUser?.email else { return }
        
        let updatedProfile = UserProfile(
            id: userId,
            email: email,
            displayName: displayName,
            totalSteps: profile?.totalSteps ?? 0,
            friendCount: profile?.friendCount ?? 0
        )
        
        do {
            try db.collection("users").document(userId).setData(from: updatedProfile)
            onSave(updatedProfile)
            dismiss()
        } catch {
            print("Error updating profile: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfileView()
} 