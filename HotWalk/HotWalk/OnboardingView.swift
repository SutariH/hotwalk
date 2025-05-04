import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

struct OnboardingView: View {
    @State private var name: String = ""
    @State private var selectedCountry: String = ""
    @State private var email: String = ""
    @State private var wantsUpdates: Bool = true
    @State private var isWritingToFirestore = false
    @State private var showNotificationView = false
    @State private var currentStep = 1
    @State private var validationMessage: String? = nil
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userID") private var userID: String = ""
    @State private var birthdate = Date()
    
    // Computed property for lowercase email
    private var lowercaseEmail: Binding<String> {
        Binding(
            get: { email },
            set: { email = $0.lowercased() }
        )
    }
    
    // List of countries
    private let countries = [
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
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.pink : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                
                // Content
                Group {
                    switch currentStep {
                    case 1:
                        nameStep
                    case 2:
                        countryStep
                    case 3:
                        emailStep
                    case 4:
                        notificationStep
                    case 5:
                        birthdateStep
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
                Spacer()
                
                // Continue Button
                Button(action: handleContinue) {
                    HStack {
                        Text(currentStep == 5 ? "Finish" : "Continue")
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
    
    private var nameStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hello Gorgeous")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("So good to have you here! Let's get to know each other.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your name?")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        TextField("Enter your name", text: $name)
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
                    }
                    
                    if let message = validationMessage {
                        Text(message)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.pink)
                            .transition(.opacity)
                            .animation(.easeInOut, value: validationMessage)
                            .padding(.top, 8)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                    .frame(height: 20)
            }
        }
    }
    
    private var countryStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pick your country, superstar")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !selectedCountry.isEmpty {
                        Text("Your country is lucky to have you")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .transition(.opacity)
                            .animation(.easeInOut, value: selectedCountry)
                    }
                }
                .padding(.bottom, 8)
                
                Menu {
                    ForEach(countries, id: \.self) { country in
                        Button(action: {
                            selectedCountry = country
                        }) {
                            Text(country)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCountry.isEmpty ? "Select your country" : selectedCountry)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(selectedCountry.isEmpty ? .white.opacity(0.6) : .white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                    }
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
                }
                
                if let message = validationMessage {
                    Text(message)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.pink)
                        .transition(.opacity)
                        .animation(.easeInOut, value: validationMessage)
                        .padding(.top, 8)
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var emailStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Let's keep in touch?")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("We'll only drop into your inbox when it's something iconic — like major app updates, new features, or the occasional Hot Girl surprise.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 8)
                    
                    TextField("your.email@example.com", text: lowercaseEmail)
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
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Toggle(isOn: $wantsUpdates) {
                        Text("Yes, I want exclusive glow-up updates in my inbox")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.top, 8)
                    
                    if let message = validationMessage {
                        Text(message)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.pink)
                            .transition(.opacity)
                            .animation(.easeInOut, value: validationMessage)
                            .padding(.top, 8)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                    .frame(height: 20)
            }
        }
    }
    
    private var notificationStep: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Text("Stay on track, hot stuff")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("We'll ping you when you're halfway to your daily step goal. Motivation, but make it cute.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
            Spacer()
        }
    }
    
    private var birthdateStep: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Text("What's your birthday so we can put a star on the calendar?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("We'll celebrate your special day with extra motivation and surprises!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                
                DatePicker("Birthday", selection: $birthdate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
            Spacer()
        }
    }
    
    private func handleContinue() {
        validationMessage = nil
        
        switch currentStep {
        case 1:
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationMessage = "Please enter your name 💋"
                return
            }
            withAnimation {
                currentStep = 2
            }
            
        case 2:
            if selectedCountry.isEmpty {
                validationMessage = "Please select your country 💋"
                return
            }
            withAnimation {
                currentStep = 3
            }
            
        case 3:
            if !email.isEmpty {
                if !isValidEmail(email) || isSuspiciousEmail(email) {
                    validationMessage = "Babe, your future self wants real updates. Try again 💋"
                    return
                }
            }
            
            if !email.isEmpty && wantsUpdates {
                isWritingToFirestore = true
                
                // Generate a unique userID if it doesn't exist
                if userID.isEmpty {
                    userID = UUID().uuidString
                }
                
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "userID": userID,
                    "name": name,
                    "country": selectedCountry,
                    "email": email,
                    "birthdate": birthdate,
                    "timestamp": FieldValue.serverTimestamp(),
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastActive": FieldValue.serverTimestamp()
                ]
                
                // Create a document with the userID as the document ID
                db.collection("users").document(userID).setData(userData) { error in
                    isWritingToFirestore = false
                    if let error = error {
                        print("Error writing to Firestore: \(error.localizedDescription)")
                    } else {
                        print("Successfully wrote to Firestore!")
                        withAnimation { currentStep = 4 }
                    }
                }
            } else {
                // Even if user doesn't provide email, we still create a userID
                if userID.isEmpty {
                    userID = UUID().uuidString
                }
                
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "userID": userID,
                    "name": name,
                    "country": selectedCountry,
                    "birthdate": birthdate,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastActive": FieldValue.serverTimestamp()
                ]
                
                db.collection("users").document(userID).setData(userData) { error in
                    isWritingToFirestore = false
                    if let error = error {
                        print("Error writing to Firestore: \(error.localizedDescription)")
                    } else {
                        print("Successfully wrote to Firestore!")
                        withAnimation { currentStep = 4 }
                    }
                }
            }
            
        case 4:
            // Request notification permission and advance to step 5
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    withAnimation { currentStep = 5 }
                }
            }
            
        case 5:
            // Update Firestore with birthdate and complete onboarding
            let db = Firestore.firestore()
            db.collection("users").document(userID).updateData([
                "birthdate": birthdate,
                "lastActive": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error updating birthdate: \(error.localizedDescription)")
                } else {
                    print("Successfully updated birthdate!")
                    hasCompletedOnboarding = true
                }
            }
            
        default:
            break
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
