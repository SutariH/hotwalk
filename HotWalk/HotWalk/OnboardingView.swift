import SwiftUI
import FirebaseFirestore

struct OnboardingView: View {
    @State private var email: String = ""
    @State private var wantsUpdates: Bool = true
    @State private var isWritingToFirestore = false
    @State private var showNotificationView = false
    @State private var currentCompliment = "Typing that email like a CEO."
    @State private var validationMessage: String? = nil
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Compliments for the generator
    private let compliments = [
        "Typing that email like a CEO.",
        "You've got main character inbox energy.",
        "Email? More like VIP pass to sparkle."
    ]
    
    var body: some View {
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
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Email Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Let's keep in touch?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        Text("We'll only drop into your inbox when it's something iconic — like major app updates, new features, or the occasional Hot Girl surprise.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        // Email input field
                        TextField("your.email@example.com", text: $email)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.5),
                                                Color.pink.opacity(0.5)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        // Animated compliment
                        Text(currentCompliment)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .transition(.opacity)
                            .animation(.easeInOut, value: currentCompliment)
                            .padding(.top, 8)
                        
                        // Validation message if needed
                        if let message = validationMessage {
                            Text(message)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.pink)
                                .transition(.opacity)
                                .animation(.easeInOut, value: validationMessage)
                                .padding(.top, 8)
                        }
                        
                        Toggle(isOn: $wantsUpdates) {
                            Text("Yes, I want exclusive glow-up updates in my inbox")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue Button
                    Button(action: handleEmailSubmission) {
                        HStack {
                            Text("Continue")
                            Text("✨")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.pink.opacity(0.8),
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        .opacity(isWritingToFirestore ? 0.7 : 1.0)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isWritingToFirestore)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .fullScreenCover(isPresented: $showNotificationView) {
            NotificationPermissionView()
        }
        .onAppear {
            // Start compliment rotation timer
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation {
                    currentCompliment = compliments.randomElement() ?? compliments[0]
                }
            }
        }
    }
    
    private func handleEmailSubmission() {
        // Validate email if provided
        if !email.isEmpty {
            if !isValidEmail(email) || isSuspiciousEmail(email) {
                validationMessage = "Babe, your future self wants real updates. Try again 💋"
                return
            }
        }
        
        if !email.isEmpty && wantsUpdates {
            isWritingToFirestore = true
            
            let db = Firestore.firestore()
            let emailData = ["email": email]
            
            db.collection("emails").addDocument(data: emailData) { error in
                isWritingToFirestore = false
                if let error = error {
                    print("Error writing to Firestore: \(error.localizedDescription)")
                } else {
                    print("Successfully wrote to Firestore!")
                }
                showNotificationView = true
            }
        } else {
            showNotificationView = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isSuspiciousEmail(_ email: String) -> Bool {
        let suspiciousPatterns = [
            "asdf@",
            "test@",
            "123@",
            "@example.com",
            "@test.com"
        ]
        return suspiciousPatterns.contains { email.lowercased().contains($0.lowercased()) }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .pink : .white)
                .font(.system(size: 20))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

#Preview {
    OnboardingView()
} 