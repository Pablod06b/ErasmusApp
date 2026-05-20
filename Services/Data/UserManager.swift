import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()
    private let db = Firestore.firestore()

    @Published var recommendedProfiles: [UserProfile] = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Fetch Recommended Users from Firebase
    func fetchRecommendedUsers(destination: String? = nil) async {
        isLoading = true

        do {
            let currentUid = Auth.auth().currentUser?.uid ?? ""
            var query: Query = db.collection("users")

            if let dest = destination, !dest.isEmpty {
                query = query.whereField("destination", isEqualTo: dest)
            }

            query = query.limit(to: PageSize.users)
            let snapshot = try await query.getDocuments()

            let profiles: [UserProfile] = snapshot.documents.compactMap { doc in
                guard doc.documentID != currentUid else { return nil }
                return try? doc.data(as: UserProfile.self)
            }

            recommendedProfiles = profiles.shuffled()
            isLoading = false
        } catch {
            print("Error fetching users: \(error)")
            isLoading = false
        }
    }

    // MARK: - Search Users by display name
    func searchUsers(query searchQuery: String) async -> [UserProfile] {
        guard !searchQuery.isEmpty else { return [] }
        do {
            let snapshot = try await db.collection("users")
                .whereField("displayName", isGreaterThanOrEqualTo: searchQuery)
                .whereField("displayName", isLessThan: searchQuery + "\u{f8ff}")
                .limit(to: PageSize.users)
                .getDocuments()

            return snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
        } catch {
            print("Error searching users: \(error)")
            return []
        }
    }
}
