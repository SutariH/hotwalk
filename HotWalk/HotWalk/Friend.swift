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
    private var shaylaTimer: Timer?
    private var lastShaylaUpdate: Date = Date()
    private let shaylaUpdateInterval: TimeInterval = 300 // 5 minutes
    
    // Add UserDefaults keys for caching
    private enum UserDefaultsKeys {
        static let friends = "cachedFriends"
        static let pendingInvites = "cachedPendingInvites"
        static let lastFriendsUpdate = "lastFriendsUpdate"
        static let lastInvitesUpdate = "lastInvitesUpdate"
        static let lastAppOpen = "lastAppOpen"
    }
    
    init() {
        setupShayla()
        loadCachedData()
        checkAndUpdateData()
    }
    
    deinit {
        shaylaTimer?.invalidate()
    }
    
    private func checkAndUpdateData() {
        // Check if we need to update based on last app open
        if let lastOpen = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastAppOpen) as? Date {
            let hoursSinceLastOpen = Date().timeIntervalSince(lastOpen) / 3600
            
            // Update if more than 4 hours have passed since last open
            if hoursSinceLastOpen >= 4 {
                updateAllData()
            }
        } else {
            // First time opening the app
            updateAllData()
        }
        
        // Update last app open time
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastAppOpen)
    }
    
    private func updateAllData() {
        fetchFriends()
        fetchPendingInvites()
        updateFriendsSteps()
    }
    
    private func loadCachedData() {
        // Load cached friends
        if let friendsData = UserDefaults.standard.data(forKey: UserDefaultsKeys.friends),
           let cachedFriends = try? JSONDecoder().decode([Friend].self, from: friendsData) {
            self.friends = cachedFriends
        }
        
        // Load cached pending invites
        if let invitesData = UserDefaults.standard.data(forKey: UserDefaultsKeys.pendingInvites),
           let cachedInvites = try? JSONDecoder().decode([Friend].self, from: invitesData) {
            self.pendingInvites = cachedInvites
        }
    }
    
    private func cacheFriends(_ friends: [Friend]) {
        if let encodedData = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(encodedData, forKey: UserDefaultsKeys.friends)
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastFriendsUpdate)
        }
    }
    
    private func cachePendingInvites(_ invites: [Friend]) {
        if let encodedData = try? JSONEncoder().encode(invites) {
            UserDefaults.standard.set(encodedData, forKey: UserDefaultsKeys.pendingInvites)
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastInvitesUpdate)
        }
    }
    
    // Add a manual refresh function
    func refreshData() {
        updateAllData()
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
                            
                            // Update local cache instead of Firestore
                            if let index = self.friends.firstIndex(where: { $0.id == friend.id }) {
                                var updatedFriends = self.friends
                                updatedFriends[index].stepsToday = steps
                                updatedFriends[index].lastStepsUpdate = Date()
                                self.friends = updatedFriends
                                self.cacheFriends(updatedFriends)
                            }
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
            cacheFriends(updatedFriends)
        }
    }
    
    func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Check if we need to update (less than an hour old)
        if let lastUpdate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastFriendsUpdate) as? Date,
           Date().timeIntervalSince(lastUpdate) < 3600 {
            return
        }
        
        Task {
            do {
                let snapshot = try await db.collection("friends")
                    .whereField("userId", isEqualTo: currentUserId)
                    .whereField("status", isEqualTo: Friend.FriendStatus.accepted.rawValue)
                    .getDocuments()
                
                var fetchedFriends = snapshot.documents.compactMap { document in
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
                
                await MainActor.run {
                    self.friends = fetchedFriends
                    self.cacheFriends(fetchedFriends)
                }
            } catch {
                print("Error fetching friends: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchPendingInvites() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Check if we need to update (less than an hour old)
        if let lastUpdate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastInvitesUpdate) as? Date,
           Date().timeIntervalSince(lastUpdate) < 3600 {
            return
        }
        
        Task {
            do {
                let snapshot = try await db.collection("friends")
                    .whereField("friendId", isEqualTo: currentUserId)
                    .whereField("status", isEqualTo: Friend.FriendStatus.pending.rawValue)
                    .getDocuments()
                
                let fetchedInvites = snapshot.documents.compactMap { document in
                    try? document.data(as: Friend.self)
                }
                
                await MainActor.run {
                    self.pendingInvites = fetchedInvites
                    self.cachePendingInvites(fetchedInvites)
                }
            } catch {
                print("Error fetching pending invites: \(error.localizedDescription)")
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