import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Friend: Identifiable, Codable {
    let id: String
    let userId: String
    let friendId: String
    let status: FriendStatus
    let timestamp: Date
    
    enum FriendStatus: String, Codable {
        case pending
        case accepted
        case rejected
    }
}

class FriendManager: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var pendingInvites: [Friend] = []
    private let db = Firestore.firestore()
    
    init() {
        fetchFriends()
        fetchPendingInvites()
    }
    
    func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("friends")
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: Friend.FriendStatus.accepted.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching friends: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.friends = documents.compactMap { document in
                    try? document.data(as: Friend.self)
                }
            }
    }
    
    func fetchPendingInvites() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("friends")
            .whereField("friendId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: Friend.FriendStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching pending invites: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.pendingInvites = documents.compactMap { document in
                    try? document.data(as: Friend.self)
                }
            }
    }
    
    func sendFriendRequest(to friendId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let friend = Friend(
            id: UUID().uuidString,
            userId: currentUserId,
            friendId: friendId,
            status: .pending,
            timestamp: Date()
        )
        
        do {
            try db.collection("friends").document(friend.id).setData(from: friend)
        } catch {
            print("Error sending friend request: \(error.localizedDescription)")
        }
    }
    
    func acceptFriendRequest(_ friend: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Update the existing request
        db.collection("friends").document(friend.id).updateData([
            "status": Friend.FriendStatus.accepted.rawValue
        ])
        
        // Create a new friend entry for the current user
        let newFriend = Friend(
            id: UUID().uuidString,
            userId: currentUserId,
            friendId: friend.userId,
            status: .accepted,
            timestamp: Date()
        )
        
        do {
            try db.collection("friends").document(newFriend.id).setData(from: newFriend)
        } catch {
            print("Error accepting friend request: \(error.localizedDescription)")
        }
    }
    
    func rejectFriendRequest(_ friend: Friend) {
        db.collection("friends").document(friend.id).updateData([
            "status": Friend.FriendStatus.rejected.rawValue
        ])
    }
    
    func removeFriend(_ friend: Friend) {
        // Remove both friend entries
        db.collection("friends")
            .whereField("userId", isEqualTo: friend.userId)
            .whereField("friendId", isEqualTo: friend.friendId)
            .getDocuments { snapshot, error in
                snapshot?.documents.forEach { document in
                    document.reference.delete()
                }
            }
        
        db.collection("friends")
            .whereField("userId", isEqualTo: friend.friendId)
            .whereField("friendId", isEqualTo: friend.userId)
            .getDocuments { snapshot, error in
                snapshot?.documents.forEach { document in
                    document.reference.delete()
                }
            }
    }
} 