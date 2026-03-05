import Foundation
import FirebaseFirestore

class UserManager: ObservableObject {
    static let shared = UserManager()
    private let db = Firestore.firestore()
    
    @Published var recommendedUsers: [Persona] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Fetch Recommended Users
    func fetchRecommendedUsers(destination: String? = nil) async {
        DispatchQueue.main.async { self.isLoading = true }
        
        do {
             // Simulate network fetch
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let fetchedUsers = [
                Persona(name: "Pablo, 19", imageName: "person1", commonInterests: 3),
                Persona(name: "Juan, 19", imageName: "person1", commonInterests: 3),
                Persona(name: "Pedro, 20", imageName: "person1", commonInterests: 3),
                Persona(name: "María, 21", imageName: "person2", commonInterests: 5),
                Persona(name: "Ana, 20", imageName: "person3", commonInterests: 2),
                Persona(name: "Carlos, 22", imageName: "person4", commonInterests: 4),
                Persona(name: "Sofia, 19", imageName: "person5", commonInterests: 6),
                Persona(name: "Diego, 23", imageName: "person6", commonInterests: 1)
            ]
            
            DispatchQueue.main.async {
                self.recommendedUsers = fetchedUsers.shuffled() // Shuffle to simulate "new" recommendations
                self.isLoading = false
            }
        } catch {
            print("Error fetching users: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}
