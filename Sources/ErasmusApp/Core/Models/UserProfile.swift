import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    var id: String
    let email: String
    let displayName: String
    let username: String
    let createdAt: Date
    let lastLogin: Date
    var interests: [String]
    var destination: String
    var photoURL: String
    var bio: String
    var onboardingCompleted: Bool
    
    // Stats
    var postsCount: Int
    var eventsCount: Int
    var connectionsCount: Int
    
    // New onboarding fields
    var university: String
    var career: String
    var erasmusStatus: String
    var languages: [LanguageLevel]
    var groupCode: String?
    var groupType: String?
    var permissions: UserPermissions
    
    init(id: String, email: String, displayName: String, username: String, createdAt: Date, lastLogin: Date, interests: [String], destination: String, photoURL: String, bio: String = "", onboardingCompleted: Bool, university: String = "", career: String = "", erasmusStatus: String = "", languages: [LanguageLevel] = [], groupCode: String? = nil, groupType: String? = nil, permissions: UserPermissions = UserPermissions(), postsCount: Int = 0, eventsCount: Int = 0, connectionsCount: Int = 0) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.interests = interests
        self.destination = destination
        self.photoURL = photoURL
        self.bio = bio
        self.onboardingCompleted = onboardingCompleted
        self.university = university
        self.career = career
        self.erasmusStatus = erasmusStatus
        self.languages = languages
        self.groupCode = groupCode
        self.groupType = groupType
        self.permissions = permissions
        self.postsCount = postsCount
        self.eventsCount = eventsCount
        self.connectionsCount = connectionsCount
    }
    
    // Helper to convert to ExtendedUserProfile (for UI compatibility)
    func toExtendedUserProfile() -> ExtendedUserProfile {
        return ExtendedUserProfile(
            id: self.id,
            name: displayName,
            username: username,
            bio: bio,
            university: university,
            career: career,
            currentDestination: destination,
            erasmusStartDate: "Sept 2025", // Placeholder or derived from createdAt
            languages: languages.map { "\($0.language) (\($0.level))" },
            interests: interests,
            isVerified: false,
            postsCount: postsCount,
            eventsCount: eventsCount,
            connectionsCount: connectionsCount,
            userPosts: [], // TODO: Load real posts
            userEvents: [], // TODO: Load real events
            photoURL: photoURL
        )
    }
}

// MARK: - Supporting Models
struct LanguageLevel: Codable, Identifiable {
    let id: String
    let language: String
    let level: String
    
    init(id: String = UUID().uuidString, language: String, level: String) {
        self.id = id
        self.language = language
        self.level = level
    }
    
    enum CodingKeys: String, CodingKey {
        case id, language, level
    }
}

struct UserPermissions: Codable {
    var location: Bool = false
    var notifications: Bool = false
    var camera: Bool = false
}

// MARK: - Extended User Profile Model
struct ExtendedUserProfile: Identifiable {
    let id: String
    let name: String
    let username: String
    let bio: String?
    let university: String
    let career: String
    let currentDestination: String
    let erasmusStartDate: String
    let languages: [String]
    let interests: [String]
    let isVerified: Bool
    let postsCount: Int
    let eventsCount: Int
    let connectionsCount: Int
    let userPosts: [ErasmusPost]
    let userEvents: [Evento]
    let photoURL: String?
    
    // Sample data
    static let sampleUser = ExtendedUserProfile(
        id: "sample_user_id",
        name: "María González",
        username: "maria_erasmus",
        bio: "Estudiante de Erasmus en Roma 🇮🇹 | Amante de la cultura italiana y la pasta 🍝 | Siempre lista para nuevas aventuras ✈️",
        university: "Universidad Complutense Madrid",
        career: "Filología Italiana",
        currentDestination: "Roma, Italia",
        erasmusStartDate: "Sep 2025",
        languages: ["🇪🇸 Español", "🇮🇹 Italiano", "🇬🇧 Inglés"],
        interests: ["🎭 Cultura", "🍕 Gastronomía", "📸 Fotografía", "✈️ Viajes"],
        isVerified: false, 
        postsCount: 24,
        eventsCount: 8,
        connectionsCount: 156,
        userPosts: [],
        userEvents: [],
        photoURL: nil
    )
}
