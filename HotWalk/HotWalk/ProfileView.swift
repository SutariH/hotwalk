import SwiftUI

struct ProfileView: View {
    @State private var showingEditSheet = false
    @State private var showingLogoutAlert = false
    @State private var userProfile: UserProfile
    @State private var selectedUnit: String = UserDefaults.standard.bool(forKey: UserDefaultsKeys.useMetricSystem) ? "Metric" : "Imperial"
    @State private var bioText: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.userBio) ?? ""
    @State private var isEditingBio: Bool = false
    @State private var isEditingName: Bool = false
    @State private var nameText: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? ""
    @State private var isShowingGoalEditor = false
    @StateObject private var goalViewModel = HotGirlStepsViewModel()
    
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
        static let userBio = "userBio"
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
                            
                            Text(nameText.isEmpty ? "Add your name" : nameText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding()
                        
                        // Name Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Name")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Button(action: { isEditingName.toggle() }) {
                                    Image(systemName: isEditingName ? "checkmark" : "pencil")
                                        .foregroundColor(.white)
                                }
                            }
                            if isEditingName {
                                TextEditor(text: $nameText)
                                    .frame(minHeight: 32, maxHeight: 60)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(Color(red: 44/255, green: 8/255, blue: 52/255))
                                    .onChange(of: nameText) { _ in
                                        saveName()
                                    }
                            } else {
                                Text(nameText.isEmpty ? "Add your name" : nameText)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.top, 2)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        
                        // Bio Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Bio")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Button(action: { isEditingBio.toggle() }) {
                                    Image(systemName: isEditingBio ? "checkmark" : "pencil")
                                        .foregroundColor(.white)
                                }
                            }
                            if isEditingBio {
                                TextEditor(text: $bioText)
                                    .frame(minHeight: 60, maxHeight: 120)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(Color(red: 44/255, green: 8/255, blue: 52/255))
                                    .onChange(of: bioText) { _ in
                                        saveBio()
                                    }
                            } else {
                                Text(bioText.isEmpty ? "Add a short bio about yourself" : bioText)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.top, 2)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        // Goal Editor Link
                        Button(action: { isShowingGoalEditor = true }) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.purple)
                                Text("Edit Daily Step Goal")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(10)
                        }
                        .padding(.top, 4)
                        .sheet(isPresented: $isShowingGoalEditor) {
                            GoalEditorView(viewModel: goalViewModel)
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
                    
                    // Legal Links Section
                    VStack(spacing: 12) {
                        Divider().background(Color.white.opacity(0.2))
                        HStack(spacing: 24) {
                            Link(destination: URL(string: "https://hotgirlsteps.com/privacy")!) {
                                Text("Privacy Policy")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            Link(destination: URL(string: "https://hotgirlsteps.com/terms")!) {
                                Text("Terms of Use")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .underline()
                            }
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView(profile: userProfile) { updatedProfile in
                    userProfile = updatedProfile
                    saveProfile(updatedProfile)
                }
            }
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        logout()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
    
    private func saveBio() {
        UserDefaults.standard.set(bioText, forKey: UserDefaultsKeys.userBio)
    }
    
    private func saveName() {
        UserDefaults.standard.set(nameText, forKey: UserDefaultsKeys.userName)
        userProfile = UserProfile(
            id: userProfile.id,
            email: userProfile.email,
            displayName: nameText,
            totalSteps: userProfile.totalSteps,
            friendCount: userProfile.friendCount,
            memberSince: userProfile.memberSince,
            bio: userProfile.bio
        )
    }
    
    private func logout() {
        clearLocalData()
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
    var bio: String? = nil
    
    init(id: String, email: String, displayName: String, totalSteps: Int, friendCount: Int, memberSince: Date = Date(), bio: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.totalSteps = totalSteps
        self.friendCount = friendCount
        self.memberSince = memberSince
        self.bio = bio
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
            memberSince: profile.memberSince,
            bio: profile.bio
        )
        
        onSave(updatedProfile)
        dismiss()
    }
}

#Preview {
    ProfileView()
} 
