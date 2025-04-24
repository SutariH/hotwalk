import SwiftUI
import FirebaseFirestore

struct OnboardingView: View {
    @State private var email: String = ""
    @State private var wantsUpdates: Bool = true
    @State private var isWritingToFirestore = false
    @State private var showNotificationView = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Email Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Let's keep in touch?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("We'll only drop into your inbox when it's something iconic — like major app updates, new features, or the occasional Hot Girl surprise.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                    
                    TextField("your.email@example.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.top, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                    
                    Toggle(isOn: $wantsUpdates) {
                        Text("Yes, I want exclusive glow-up updates in my inbox")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
                .padding()
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
        .fullScreenCover(isPresented: $showNotificationView) {
            NotificationPermissionView()
        }
    }
    
    private func handleEmailSubmission() {
        if !email.isEmpty && wantsUpdates && isValidEmail(email) {
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