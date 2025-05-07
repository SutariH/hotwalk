import SwiftUI

struct ProfileView: View {
    @State private var showingEditSheet = false
    @State private var showingLogoutAlert = false
    @State private var userProfile: UserProfile
    @State private var selectedUnit: String = UserDefaults.standard.bool(forKey: UserDefaultsKeys.useMetricSystem) ? "Metric" : "Imperial"
    
    // Add UserDefaults keys
    private enum UserDefaultsKeys {
        static let userProfile = "cachedUserProfile"
        static let memberSince = "memberSince"
        static let userEmail = "userEmail"
        static let userName = "userName"
        static let totalSteps = "totalSteps"
        static let friendCount = "friendCount"
        static let userCountry = "userCountry"
        static let useMetricSystem = "useMetricSystem"
    }
    
    private let unitOptions = ["Metric", "Imperial"]
    
    init() {
        // Load profile synchronously during initialization
        if let cachedData = UserDefaults.standard.data(forKey: UserDefaultsKeys.userProfile),
           let cachedProfile = try? JSONDecoder().decode(UserProfile.self, from: cachedData) {
            _userProfile = State(initialValue: cachedProfile)
        } else {
            // Create new profile if none exists
            let newProfile = UserProfile(
                id: UUID().uuidString,
                email: UserDefaults.standard.string(forKey: UserDefaultsKeys.userEmail) ?? "user@example.com",
                displayName: UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? "User",
                totalSteps: UserDefaults.standard.integer(forKey: UserDefaultsKeys.totalSteps),
                friendCount: UserDefaults.standard.integer(forKey: UserDefaultsKeys.friendCount),
                memberSince: Date()
            )
            _userProfile = State(initialValue: newProfile)
            saveProfile(newProfile)
        }
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            
                            Text(userProfile.displayName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(userProfile.email)
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
                                    value: "\(userProfile.totalSteps)",
                                    icon: "figure.walk"
                                )
                                
                                StatCard(
                                    title: "Friends",
                                    value: "\(userProfile.friendCount)",
                                    icon: "person.2.fill"
                                )
                            }
                            
                            // Member Since Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Member Since")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(formatDate(userProfile.memberSince))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            
                            // Unit Preference Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Distance Units")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Picker("Select Unit System", selection: $selectedUnit) {
                                    ForEach(unitOptions, id: \.self) { unit in
                                        Text(unit).tag(unit)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.4, green: 0.2, blue: 0.4))
                                .cornerRadius(10)
                                .accentColor(.white)
                                .onChange(of: selectedUnit) { newValue in
                                    let useMetric = newValue == "Metric"
                                    UserDefaults.standard.set(useMetric, forKey: UserDefaultsKeys.useMetricSystem)
                                }
                                
                                Text(selectedUnit == "Metric" ? "Distances shown in kilometers" : "Distances shown in miles")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Edit Profile Button
                        Button(action: { showingEditSheet = true }) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                Text("Edit Profile")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Logout Button
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 20))
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView(profile: userProfile) { updatedProfile in
                    userProfile = updatedProfile
                    saveProfile(updatedProfile)
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    clearLocalData()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func saveProfile(_ profile: UserProfile) {
        if let encodedData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encodedData, forKey: UserDefaultsKeys.userProfile)
            UserDefaults.standard.set(profile.memberSince, forKey: UserDefaultsKeys.memberSince)
            UserDefaults.standard.set(profile.email, forKey: UserDefaultsKeys.userEmail)
            UserDefaults.standard.set(profile.displayName, forKey: UserDefaultsKeys.userName)
            UserDefaults.standard.set(profile.totalSteps, forKey: UserDefaultsKeys.totalSteps)
            UserDefaults.standard.set(profile.friendCount, forKey: UserDefaultsKeys.friendCount)
        }
    }
    
    private func clearLocalData() {
        // Clear all profile-related data
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userProfile)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.memberSince)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.totalSteps)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.friendCount)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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

struct UserProfile: Codable {
    let id: String
    let email: String
    let displayName: String
    var totalSteps: Int
    var friendCount: Int
    let memberSince: Date
    
    init(id: String, email: String, displayName: String, totalSteps: Int, friendCount: Int, memberSince: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.totalSteps = totalSteps
        self.friendCount = friendCount
        self.memberSince = memberSince
    }
}

struct EditProfileView: View {
    let profile: UserProfile
    let onSave: (UserProfile) -> Void
    @State private var displayName: String
    @Environment(\.dismiss) private var dismiss
    
    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _displayName = State(initialValue: profile.displayName)
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
        let updatedProfile = UserProfile(
            id: profile.id,
            email: profile.email,
            displayName: displayName,
            totalSteps: profile.totalSteps,
            friendCount: profile.friendCount,
            memberSince: profile.memberSince
        )
        
        onSave(updatedProfile)
        dismiss()
    }
}

#Preview {
    ProfileView()
} 