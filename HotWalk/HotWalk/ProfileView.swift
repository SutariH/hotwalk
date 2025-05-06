import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StoreKit

struct ProfileView: View {
    @State private var userData: [String: Any] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var viewModel = HotGirlStepsViewModel()
    @State private var showingGoalEditor = false
    
    private var currentUserID: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Text("Oops! Something went wrong")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text(error)
                        .foregroundColor(.white.opacity(0.8))
                    Button("Try Again") {
                        fetchUserData()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Text("Your Profile")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Profile Image Placeholder
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String((userData["name"] as? String ?? "U").prefix(1)))
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(.top, 32)
                        
                        // User Information Card
                        VStack(spacing: 20) {
                            InfoRow(title: "Name", value: userData["name"] as? String ?? "Not set")
                            
                            if let createdAt = userData["createdAt"] as? Timestamp {
                                InfoRow(
                                    title: "Member Since",
                                    value: formatDate(createdAt.dateValue())
                                )
                            }
                            
                            // Goal Editor Link
                            Button(action: {
                                showingGoalEditor = true
                            }) {
                                HStack {
                                    Text("Daily Step Goal")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.dailyGoal) steps")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Buttons Section
                        VStack(spacing: 16) {
                            // Edit Profile Button
                            Button(action: {
                                // Add edit profile action here
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Edit Profile")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Leave a Review Button
                            Button(action: {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    SKStoreReviewController.requestReview(in: windowScene)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow)
                                    
                                    Text("Leave a Review")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            fetchUserData()
        }
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView(viewModel: viewModel)
        }
    }
    
    private func fetchUserData() {
        guard !currentUserID.isEmpty else {
            errorMessage = "Please sign in to view your profile"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUserID).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            if let document = document, document.exists {
                userData = document.data() ?? [:]
            } else {
                errorMessage = "No user data found"
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ProfileView()
} 