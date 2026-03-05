import Foundation

struct SocialGroup: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let city: String
    let inviteCode: String
    let imageUrl: String?
    let memberIds: [String]
    let createdAt: Date
    
    // UI Helper - Sample Group
    static let sample = SocialGroup(
        id: "group_123",
        name: "Erasmus Roma 2025",
        description: "El grupo oficial para todos los que vamos a Roma este año 🇮🇹🍕",
        city: "Roma",
        inviteCode: "ROMA25",
        imageUrl: nil,
        memberIds: ["user_1", "user_2"],
        createdAt: Date()
    )
}
