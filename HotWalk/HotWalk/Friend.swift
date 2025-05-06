import Foundation
import FirebaseFirestore
import FirebaseAuth
import HealthKit

// Friend model for Hot Girl Steps app
struct Friend: Identifiable, Codable {
    let id: String
    let userId: String
    let friendId: String
    let status: FriendStatus
    let timestamp: Date
    var stepsToday: Int
    var lastStepsUpdate: Date
    
    enum FriendStatus: String, Codable {
        case pending
        case accepted
        case rejected
    }
}

// FriendManager handles all friend-related operations for Hot Girl Steps
class FriendManager: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var pendingInvites: [Friend] = []
    private let db = Firestore.firestore()
    private var updateTimer: Timer?
    private var shaylaTimer: Timer?
    private var friendsListener: ListenerRegistration?
    private var invitesListener: ListenerRegistration?
    private var lastShaylaUpdate: Date = Date()
    private let shaylaUpdateInterval: TimeInterval = 300 // 5 minutes
    
    init() {
        setupShayla()
        fetchFriends()
        fetchPendingInvites()
        setupStepUpdateTimer()
    }
    
    deinit {
        friendsListener?.remove()
        invitesListener?.remove()
        updateTimer?.invalidate()
        shaylaTimer?.invalidate()
    }
    
    private func setupStepUpdateTimer() {
        // Update every hour
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateFriendsSteps()
        }
        // Initial update
        updateFriendsSteps()
    }
    
    private func updateFriendsSteps() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        for friend in friends {
            // Skip Shayla bot as she's handled locally
            if friend.friendId == "shayla_bot" { continue }
            
            Task {
                do {
                    // Get friend's steps from HealthKit
                    let healthStore = HKHealthStore()
                    let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                    
                    // Request authorization if needed
                    if healthStore.authorizationStatus(for: stepsType) != .sharingAuthorized {
                        try await healthStore.requestAuthorization(toShare: [], read: [stepsType])
                    }
                    
                    // Get today's steps
                    let calendar = Calendar.current
                    let now = Date()
                    let startOfDay = calendar.startOfDay(for: now)
                    
                    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
                    
                    let query = HKStatisticsQuery(
                        quantityType: stepsType,
                        quantitySamplePredicate: predicate,
                        options: .cumulativeSum
                    ) { _, result, error in
                        if let result = result,
                           let sum = result.sumQuantity() {
                            let steps = Int(sum.doubleValue(for: HKUnit.count()))
                            
                            // Update Firestore
                            self.db.collection("friends").document(friend.id).updateData([
                                "stepsToday": steps,
                                "lastStepsUpdate": FieldValue.serverTimestamp()
                            ])
                        }
                    }
                    
                    healthStore.execute(query)
                } catch {
                    print("Error updating friend's steps: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupShayla() {
        // Update Shayla's steps every hour
        shaylaTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateShaylaSteps()
        }
    }
    
    private func updateShaylaSteps() {
        let now = Date()
        guard now.timeIntervalSince(lastShaylaUpdate) >= shaylaUpdateInterval else { return }
        
        ShaylaBot.shared.updateSteps()
        lastShaylaUpdate = now
        
        // Update Shayla in friends list locally
        if let index = friends.firstIndex(where: { $0.friendId == "shayla_bot" }) {
            var updatedFriends = friends
            updatedFriends[index].stepsToday = ShaylaBot.shared.stepsToday
            updatedFriends[index].lastStepsUpdate = ShaylaBot.shared.lastStepsUpdate
            friends = updatedFriends
        }
    }
    
    func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener
        friendsListener?.remove()
        
        friendsListener = db.collection("friends")
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: Friend.FriendStatus.accepted.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching friends: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var fetchedFriends = documents.compactMap { document in
                    try? document.data(as: Friend.self)
                }
                
                // Add Shayla to the list locally
                let shayla = Friend(
                    id: "shayla_bot",
                    userId: currentUserId,
                    friendId: "shayla_bot",
                    status: .accepted,
                    timestamp: Date(),
                    stepsToday: ShaylaBot.shared.stepsToday,
                    lastStepsUpdate: ShaylaBot.shared.lastStepsUpdate
                )
                
                // Remove Shayla if she exists in the list
                fetchedFriends.removeAll { $0.friendId == "shayla_bot" }
                // Add her back with current data
                fetchedFriends.append(shayla)
                
                self?.friends = fetchedFriends
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
        
        // Create a unique document ID using both user IDs
        let documentId = "\(currentUserId)_\(friendId)"
        
        let friend = Friend(
            id: documentId,
            userId: currentUserId,
            friendId: friendId,
            status: .pending,
            timestamp: Date(),
            stepsToday: 0,
            lastStepsUpdate: Date()
        )
        
        do {
            try db.collection("friends").document(documentId).setData(from: friend)
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
        
        // Create a new friend entry for the current user with a unique document ID
        let reverseDocumentId = "\(friend.userId)_\(currentUserId)"
        let newFriend = Friend(
            id: reverseDocumentId,
            userId: currentUserId,
            friendId: friend.userId,
            status: .accepted,
            timestamp: Date(),
            stepsToday: 0,
            lastStepsUpdate: Date()
        )
        
        do {
            try db.collection("friends").document(reverseDocumentId).setData(from: newFriend)
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
        // Skip if it's Shayla bot
        if friend.friendId == "shayla_bot" { return }
        
        db.collection("friends").document(friend.id).delete()
    }
} 