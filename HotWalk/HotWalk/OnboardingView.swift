import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import AuthenticationServices
import CryptoKit

class OnboardingViewModel: ObservableObject {
    @Published var email = ""
    @Published var displayName = ""
    @Published var dateOfBirth = Date()
    @Published var country = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentStep = OnboardingStep.signIn
    @Published var hasCompletedProfile = false
    @Published var marketingConsent = true
    @Published var hasSelectedCountry = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Published var isValidEmail = false
    @Published var showEmailError = false
    
    private let db = Firestore.firestore()
    private var currentNonce: String?
    
    let countries = [
        "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", "Argentina", "Armenia", "Australia", "Austria",
        "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan",
        "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi", "Cabo Verde", "Cambodia",
        "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo", "Costa Rica",
        "Croatia", "Cuba", "Cyprus", "Czech Republic", "Denmark", "Djibouti", "Dominica", "Dominican Republic", "Ecuador", "Egypt",
        "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia", "Fiji", "Finland", "France", "Gabon",
        "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana",
        "Haiti", "Honduras", "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel",
        "Italy", "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya", "Kiribati", "Korea, North", "Korea, South", "Kosovo",
        "Kuwait", "Kyrgyzstan", "Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania",
        "Luxembourg", "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius",
        "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar", "Namibia",
        "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Macedonia", "Norway", "Oman",
        "Pakistan", "Palau", "Palestine", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal",
        "Qatar", "Romania", "Russia", "Rwanda", "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe",
        "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia",
        "South Africa", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria", "Taiwan",
        "Tajikistan", "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan",
        "Tuvalu", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan", "Vanuatu", "Vatican City",
        "Venezuela", "Vietnam", "Yemen", "Zambia", "Zimbabwe"
    ].sorted()
    
    enum OnboardingStep {
        case signIn
        case name
        case email
        case country
        case dateOfBirth
        case notifications
    }
    
    // Generate a random nonce for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    // Hash the nonce for Apple Sign In
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    await MainActor.run {
                        errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                        isLoading = false
                    }
                    return
                }
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    await MainActor.run {
                        errorMessage = "Unable to fetch identity token"
                        isLoading = false
                    }
                    return
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    await MainActor.run {
                        errorMessage = "Unable to serialize token string from data"
                        isLoading = false
                    }
                    return
                }
                
                // Get user info
                let email = appleIDCredential.email ?? ""
                let fullName = appleIDCredential.fullName
                let displayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                do {
                    // Create Firebase credential
                    let credential = OAuthProvider.credential(
                        withProviderID: "apple.com",
                        idToken: idTokenString,
                        rawNonce: nonce
                    )
                    
                    // Sign in with Firebase
                    let authResult = try await Auth.auth().signIn(with: credential)
                    let user = authResult.user
                    
                    // Create or update user profile in Firestore
                    let userData: [String: Any] = [
                        "email": email,
                        "displayName": displayName,
                        "lastLogin": FieldValue.serverTimestamp()
                    ]
                    
                    try await db.collection("users").document(user.uid).setData(userData, merge: true)
                    
                    await MainActor.run {
                        self.email = email
                        self.displayName = displayName
                        currentStep = .name
                        isLoading = false
                    }
                } catch {
                    print("Debug: Error signing in with Apple: \(error.localizedDescription)")
                    await MainActor.run {
                        errorMessage = "Error signing in with Apple. Please try again."
                        isLoading = false
                    }
                }
            }
        case .failure(let error):
            print("Debug: Apple sign in failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Sign in with Apple failed. Please try again."
                isLoading = false
            }
        }
    }
    
    func saveName() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        guard let user = Auth.auth().currentUser else {
            await MainActor.run {
                errorMessage = "No user found. Please sign in again."
                isLoading = false
            }
            return
        }
        
        do {
            let userData: [String: Any] = [
                "displayName": displayName,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
            
            await MainActor.run {
                currentStep = .email
                isLoading = false
            }
        } catch {
            print("Debug: Error saving name: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error saving name. Please try again."
                isLoading = false
            }
        }
    }
    
    func saveEmail() async {
        await MainActor.run { 
            isLoading = true
            errorMessage = nil
            showEmailError = false
        }
        
        // If email is not empty, validate it
        if !email.isEmpty && !isValidEmailFormat(email) {
            await MainActor.run {
                showEmailError = true
                isLoading = false
            }
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            await MainActor.run {
                errorMessage = "No user found. Please sign in again."
                isLoading = false
            }
            return
        }
        
        do {
            let userData: [String: Any] = [
                "email": email,
                "marketingConsent": marketingConsent,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
            
            await MainActor.run {
                currentStep = .country
                isLoading = false
            }
        } catch {
            print("Debug: Error saving email: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error saving email. Please try again."
                isLoading = false
            }
        }
    }
    
    func saveCountry() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        guard let user = Auth.auth().currentUser else {
            await MainActor.run {
                errorMessage = "No user found. Please sign in again."
                isLoading = false
            }
                return
        }
        
        do {
            let userData: [String: Any] = [
                "country": country,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
            
            // Save country to UserDefaults
            UserDefaults.standard.set(country, forKey: "userCountry")
            
            await MainActor.run {
                currentStep = .dateOfBirth
                isLoading = false
            }
        } catch {
            print("Debug: Error saving country: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error saving country. Please try again."
                isLoading = false
            }
        }
    }
    
    func saveDateOfBirth() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        guard let user = Auth.auth().currentUser else {
            await MainActor.run {
                errorMessage = "No user found. Please sign in again."
                isLoading = false
            }
            return
        }
        
        do {
            let userData: [String: Any] = [
                "dateOfBirth": dateOfBirth,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
            
            await MainActor.run {
                currentStep = .notifications
                isLoading = false
            }
        } catch {
            print("Debug: Error saving date of birth: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error saving date of birth. Please try again."
                isLoading = false
            }
        }
    }
    
    func requestNotifications() async {
        await MainActor.run { isLoading = true }
        
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                
                if granted {
                    await MainActor.run {
                        isAuthenticated = true
                        hasCompletedProfile = true
                        hasCompletedOnboarding = true
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isAuthenticated = true
                        hasCompletedProfile = true
                        hasCompletedOnboarding = true
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    isAuthenticated = true
                    hasCompletedProfile = true
                    hasCompletedOnboarding = true
                    isLoading = false
                }
            }
        } catch {
            print("Debug: Error requesting notifications: \(error.localizedDescription)")
            await MainActor.run {
                isAuthenticated = true
                hasCompletedProfile = true
                hasCompletedOnboarding = true
                isLoading = false
            }
        }
    }
    
    // Change from private to internal
    func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.9, green: 0.6, blue: 0.9),
                        Color(red: 0.7, green: 0.3, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch viewModel.currentStep {
                        case .signIn:
                            SignInView(viewModel: viewModel)
                        case .name:
                            NameView(viewModel: viewModel)
                        case .email:
                            EmailView(viewModel: viewModel)
                        case .country:
                            CountryView(viewModel: viewModel)
                        case .dateOfBirth:
                            DateOfBirthView(viewModel: viewModel)
                        case .notifications:
                            NotificationsView(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SignInView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Logo
            Image("HotGirlStepsLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            // Welcome Text
            VStack(spacing: 16) {
                Text("Welcome to Hot Girl Steps")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your daily steps just got a whole lot more interesting.")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            // Sign in with Apple button
            SignInWithAppleButton(
                onRequest: viewModel.handleSignInWithAppleRequest,
                onCompletion: { result in
                    Task {
                        await viewModel.handleSignInWithAppleCompletion(result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(25)
            .padding(.horizontal, 40)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
}

struct NameView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Don't worry, we won't judge if it's your real name or your alter ego. 😉")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            TextField("Your fabulous name", text: $viewModel.displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await viewModel.saveName()
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.purple)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .disabled(viewModel.displayName.isEmpty)
            .opacity(viewModel.displayName.isEmpty ? 0.6 : 1.0)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
}

struct EmailView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("Stay in the Loop!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 24) {
                TextField("Your email address", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 40)
                    .foregroundColor(.black)
                
                if viewModel.showEmailError {
                    Text("Oops! That doesn't look like a real email address. We need the real deal to keep you in the loop! 📧")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                } else {
                    Text("We promise to only send you the good stuff - no spam, just hot girl energy! ✨")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Toggle(isOn: $viewModel.marketingConsent) {
                    Text("Send me emails about new features and updates")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.7, green: 0.3, blue: 0.7)))
                .padding(.horizontal, 40)
            }
            
            Button(action: {
                Task {
                    await viewModel.saveEmail()
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.7, green: 0.3, blue: 0.7))
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
}

struct CountryView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("Where's Your Hot Girl Energy Coming From?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Don't worry, we're not stalking you - we just want to send you the right timezone vibes! 🌍")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                Picker("Select your country", selection: $viewModel.country) {
                    Text("Select a country").tag("")
                        .foregroundColor(.white.opacity(0.7))
                    ForEach(viewModel.countries, id: \.self) { country in
                        Text(country).tag(country)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.4, green: 0.2, blue: 0.4))
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .accentColor(.white)
                .onChange(of: viewModel.country) { newValue in
                    viewModel.hasSelectedCountry = !newValue.isEmpty
                }
                
                if viewModel.hasSelectedCountry {
                    Text("Your country is so lucky to have you")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }
            }
            
            Button(action: {
                Task {
                    await viewModel.saveCountry()
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.7, green: 0.3, blue: 0.7))
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .disabled(viewModel.country.isEmpty)
            .opacity(viewModel.country.isEmpty ? 0.6 : 1.0)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
}

struct DateOfBirthView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("When's Your Birthday?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Don't worry, we won't tell anyone your age - it's just between us! 🎂")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                DatePicker("Date of Birth", selection: $viewModel.dateOfBirth, in: ...Date(), displayedComponents: [.date])
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.4, green: 0.2, blue: 0.4))
                            .padding(.horizontal, 20)
                    )
                    .padding(.vertical, 20)
                    .colorScheme(.dark)
                    .accentColor(.white)
                    .foregroundColor(.white)
                
                Text("Swipe to select your birthday")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, -8)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.saveDateOfBirth()
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.7, green: 0.3, blue: 0.7))
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
}

struct NotificationsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("Stay in the Loop!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get reminded to take your daily steps and stay on track with your goals.")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.requestNotifications()
                }
            }) {
                Text("✨ Let's Get Notified! ✨")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.purple)
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingView()
} 
