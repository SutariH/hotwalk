import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import AuthenticationServices
import CryptoKit

class OnboardingViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let db = Firestore.firestore()
    private var currentNonce: String?
    
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
                        isAuthenticated = true
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
    
    func signUp() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        // Validate inputs
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            await MainActor.run {
                errorMessage = "Please fill in all fields"
                isLoading = false
            }
            return
        }
        
        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            await MainActor.run {
                errorMessage = "Please enter a valid email address"
                isLoading = false
            }
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            await MainActor.run {
                errorMessage = "Password must be at least 6 characters"
                isLoading = false
            }
            return
        }
        
        do {
            print("Debug: Starting user creation with email: \(email)")
            
            // Create Firebase Auth user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = authResult.user
            print("Debug: Firebase Auth user created successfully with ID: \(user.uid)")
            
            // Create user profile in Firestore
            let userData: [String: Any] = [
                "email": email,
                "displayName": displayName,
                "createdAt": FieldValue.serverTimestamp(),
                "lastLogin": FieldValue.serverTimestamp()
            ]
            
            print("Debug: Attempting to create Firestore document for user: \(user.uid)")
            try await db.collection("users").document(user.uid).setData(userData)
            print("Debug: Firestore document created successfully")
            
            // Update display name in Auth
            print("Debug: Updating display name in Auth")
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            print("Debug: Display name updated successfully")
            
            await MainActor.run {
                isAuthenticated = true
                isLoading = false
            }
        } catch let error as NSError {
            print("Debug: Error occurred during sign up: \(error.localizedDescription)")
            print("Debug: Error domain: \(error.domain)")
            print("Debug: Error code: \(error.code)")
            
            let errorMessage: String
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "This email is already registered. Please sign in instead."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Please enter a valid email address."
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "Please choose a stronger password."
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "Network error. Please check your connection and try again."
            default:
                errorMessage = "An error occurred: \(error.localizedDescription)"
            }
            
            await MainActor.run {
                self.errorMessage = errorMessage
                isLoading = false
            }
        }
    }
    
    func signIn() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        // Validate inputs
        guard !email.isEmpty, !password.isEmpty else {
            await MainActor.run {
                errorMessage = "Please fill in all fields"
                isLoading = false
            }
            return
        }
        
        do {
            print("Debug: Attempting to sign in user: \(email)")
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = authResult.user
            print("Debug: User signed in successfully: \(user.uid)")
            
            // Update last login timestamp
            try await db.collection("users").document(user.uid).updateData([
                "lastLogin": FieldValue.serverTimestamp()
            ])
            print("Debug: Last login timestamp updated")
            
            await MainActor.run {
                isAuthenticated = true
                isLoading = false
            }
        } catch let error as NSError {
            print("Debug: Error occurred during sign in: \(error.localizedDescription)")
            print("Debug: Error domain: \(error.domain)")
            print("Debug: Error code: \(error.code)")
            
            let errorMessage: String
            switch error.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Incorrect password. Please try again."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Please enter a valid email address."
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "No account found with this email. Please sign up first."
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "Network error. Please check your connection and try again."
            default:
                errorMessage = "An error occurred: \(error.localizedDescription)"
            }
            
            await MainActor.run {
                self.errorMessage = errorMessage
                isLoading = false
            }
        }
    }
    
    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            print("Debug: User is already authenticated: \(user.uid)")
            isAuthenticated = true
        } else {
            print("Debug: No authenticated user found")
        }
    }
}

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var isSignUp = true
    
    var body: some View {
        NavigationView {
            ZStack {
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Sign in with Apple button
                        SignInWithAppleButton(
                            onRequest: viewModel.handleSignInWithAppleRequest,
                            onCompletion: { result in
                                Task {
                                    await viewModel.handleSignInWithAppleCompletion(result)
                                }
                            }
                        )
                        .frame(height: 50)
                        .padding(.horizontal)
                        
                        Text("or")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                        
                        VStack(spacing: 16) {
                            if isSignUp {
                                TextField("Display Name", text: $viewModel.displayName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            TextField("Email", text: $viewModel.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            
                            SecureField("Password", text: $viewModel.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            Task {
                                if isSignUp {
                                    await viewModel.signUp()
                                } else {
                                    await viewModel.signIn()
                                }
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.8),
                                    Color.purple.opacity(0.6)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(viewModel.isLoading)
                        
                        Button(action: { isSignUp.toggle() }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.checkAuthState()
        }
    }
}

struct SignInWithAppleButton: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButton
        
        init(_ parent: SignInWithAppleButton) {
            self.parent = parent
        }
        
        @objc func handleTap() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            parent.onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            UIApplication.shared.windows.first!
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }
    }
}

#Preview {
    OnboardingView()
} 
