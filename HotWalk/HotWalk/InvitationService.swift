import Foundation
import FirebaseFirestore
import FirebaseAuth

class InvitationService: ObservableObject {
    @Published var isGeneratingLink = false
    @Published var error: Error?
    
    private let linkService: LinkServiceProtocol
    
    init(linkServiceType: LinkServiceType = .custom) {
        self.linkService = LinkServiceFactory.createService(type: linkServiceType)
    }
    
    func generateInvitationLink() async throws -> URL {
        return try await linkService.generateInvitationLink()
    }
    
    func handleInvitationLink(_ url: URL) async throws {
        try await linkService.handleInvitationLink(url)
    }
} 