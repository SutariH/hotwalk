import Foundation
import FirebaseFirestore
import FirebaseAuth

// Protocol defining the contract for any link service
protocol LinkServiceProtocol {
    func generateInvitationLink() async throws -> URL
    func handleInvitationLink(_ url: URL) async throws
}

// Base class for invitation handling
class BaseInvitationHandler {
    let db = Firestore.firestore()
    
    func createInvitation() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            print("Debug: No current user found in Auth.auth().currentUser")
            throw InvitationError.notAuthenticated
        }
        
        // Verify the user exists in Firestore
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard userDoc.exists else {
            print("Debug: User document not found in Firestore")
            throw InvitationError.userProfileNotFound
        }
        
        let invitationId = UUID().uuidString
        
        try await db.collection("invitations").document(invitationId).setData([
            "inviterId": currentUser.uid,
            "inviterEmail": currentUser.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "status": "pending"
        ])
        
        return invitationId
    }
    
    func handleInvitation(_ invitationId: String) async throws {
        let invitationDoc = try await db.collection("invitations").document(invitationId).getDocument()
        guard let invitation = invitationDoc.data() else {
            throw InvitationError.invitationNotFound
        }
        
        guard invitation["status"] as? String == "pending" else {
            throw InvitationError.invitationExpired
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            throw InvitationError.notAuthenticated
        }
        
        let friend = Friend(
            id: UUID().uuidString,
            userId: invitation["inviterId"] as! String,
            friendId: currentUser.uid,
            status: .pending,
            timestamp: Date()
        )
        
        try await db.collection("friends").document(friend.id).setData(from: friend)
        
        try await db.collection("invitations").document(invitationId).updateData([
            "status": "accepted",
            "acceptedAt": FieldValue.serverTimestamp(),
            "acceptedBy": currentUser.uid
        ])
    }
}

// Custom URL scheme implementation
class CustomLinkService: BaseInvitationHandler, LinkServiceProtocol {
    private let baseURL = "hotwalk://invite"
    
    func generateInvitationLink() async throws -> URL {
        let invitationId = try await createInvitation()
        guard let url = URL(string: "\(baseURL)?id=\(invitationId)") else {
            throw InvitationError.linkGenerationFailed
        }
        return url
    }
    
    func handleInvitationLink(_ url: URL) async throws {
        guard url.scheme == "hotwalk",
              url.host == "invite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let invitationId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            throw InvitationError.invalidLink
        }
        
        try await handleInvitation(invitationId)
    }
}

// Universal Links implementation
class UniversalLinkService: BaseInvitationHandler, LinkServiceProtocol {
    private let baseURL = "https://hotgirlsteps.com/invite"
    
    func generateInvitationLink() async throws -> URL {
        let invitationId = try await createInvitation()
        guard let url = URL(string: "\(baseURL)?id=\(invitationId)") else {
            throw InvitationError.linkGenerationFailed
        }
        return url
    }
    
    func handleInvitationLink(_ url: URL) async throws {
        guard url.host == "hotgirlsteps.com",
              url.path == "/invite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let invitationId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            throw InvitationError.invalidLink
        }
        
        try await handleInvitation(invitationId)
    }
}

// Factory to create the appropriate link service
enum LinkServiceFactory {
    static func createService(type: LinkServiceType = .custom) -> LinkServiceProtocol {
        switch type {
        case .custom:
            return CustomLinkService()
        case .universal:
            return UniversalLinkService()
        }
    }
}

enum LinkServiceType {
    case custom
    case universal
}

enum InvitationError: LocalizedError {
    case notAuthenticated
    case invalidDomain
    case linkGenerationFailed
    case invalidLink
    case invitationNotFound
    case invitationExpired
    case userProfileNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please complete your profile setup to invite friends"
        case .userProfileNotFound:
            return "Please complete your profile setup to invite friends"
        case .invalidDomain:
            return "Invalid domain configuration"
        case .linkGenerationFailed:
            return "Failed to generate invitation link"
        case .invalidLink:
            return "Invalid invitation link"
        case .invitationNotFound:
            return "Invitation not found"
        case .invitationExpired:
            return "This invitation has expired"
        }
    }
} 