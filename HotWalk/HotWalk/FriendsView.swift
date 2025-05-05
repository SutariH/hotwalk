import SwiftUI
import FirebaseAuth

struct FriendsView: View {
    @StateObject private var friendManager = FriendManager()
    @StateObject private var invitationService = InvitationService()
    @State private var showingInviteSheet = false
    @State private var inviteEmail = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingShareSheet = false
    @State private var invitationLink: URL?
    @State private var isGeneratingLink = false
    
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
                        // Invite Friends Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Invite Friends")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                Button(action: { showingInviteSheet = true }) {
                                    VStack {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 24))
                                        Text("Email")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                Button(action: generateInvitationLink) {
                                    VStack {
                                        if isGeneratingLink {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "link")
                                                .font(.system(size: 24))
                                            Text("Link")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(isGeneratingLink)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Pending Invites Section
                        if !friendManager.pendingInvites.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Pending Invites")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                ForEach(friendManager.pendingInvites) { invite in
                                    PendingInviteCard(invite: invite) { accepted in
                                        if accepted {
                                            friendManager.acceptFriendRequest(invite)
                                        } else {
                                            friendManager.rejectFriendRequest(invite)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Friends List Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Friends")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if friendManager.friends.isEmpty {
                                Text("No friends yet. Invite someone to start walking together!")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            } else {
                                ForEach(friendManager.friends) { friend in
                                    FriendCard(friend: friend) {
                                        friendManager.removeFriend(friend)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingInviteSheet) {
                InviteFriendView(
                    inviteEmail: $inviteEmail,
                    onInvite: sendInvite,
                    onDismiss: { showingInviteSheet = false }
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let link = invitationLink {
                    ShareSheet(activityItems: [link])
                }
            }
            .alert("Invite Status", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func generateInvitationLink() {
        isGeneratingLink = true
        
        Task {
            do {
                let link = try await invitationService.generateInvitationLink()
                await MainActor.run {
                    invitationLink = link
                    showingShareSheet = true
                    isGeneratingLink = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isGeneratingLink = false
                }
            }
        }
    }
    
    private func sendInvite() {
        // Here you would typically:
        // 1. Look up the user by email in Firebase
        // 2. Send the friend request
        // 3. Show appropriate success/error message
        
        // For now, we'll just show a placeholder message
        alertMessage = "Invite sent to \(inviteEmail)"
        showingAlert = true
        showingInviteSheet = false
        inviteEmail = ""
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PendingInviteCard: View {
    let invite: Friend
    let onResponse: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend Request")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text("From: \(invite.userId)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { onResponse(true) }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                }
                
                Button(action: { onResponse(false) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 24))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FriendCard: View {
    let friend: Friend
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text("ID: \(friend.friendId)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "person.fill.xmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InviteFriendView: View {
    @Binding var inviteEmail: String
    let onInvite: () -> Void
    let onDismiss: () -> Void
    
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
                
                VStack(spacing: 24) {
                    Text("Invite a Friend")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    TextField("Friend's Email", text: $inviteEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal)
                    
                    Button(action: onInvite) {
                        Text("Send Invite")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
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
                    }
                    .disabled(inviteEmail.isEmpty)
                    .opacity(inviteEmail.isEmpty ? 0.6 : 1)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    FriendsView()
} 