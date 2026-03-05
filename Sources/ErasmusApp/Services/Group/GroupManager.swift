import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GroupManager: ObservableObject {
    static let shared = GroupManager()
    
    @Published var currentGroup: SocialGroup?
    @Published var isLoading = false
    @Published var error: String?
    
    @Published var groupMembers: [UserProfile] = []
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Join Group
    func joinGroup(code: String) async -> Bool {
        isLoading = true
        error = nil
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.error = "No authenticated user"
            isLoading = false
            return false
        }
        
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        do {
            let snapshot = try await db.collection("groups")
                .whereField("inviteCode", isEqualTo: cleanCode)
                .limit(to: 1)
                .getDocuments()
            
            if let doc = snapshot.documents.first {
                var group = try doc.data(as: SocialGroup.self)
                // Add user to memberIds if not already there
                if !group.memberIds.contains(currentUserId) {
                    try await db.collection("groups").document(doc.documentID).updateData([
                        "memberIds": FieldValue.arrayUnion([currentUserId])
                    ])
                    let mutableIds = group.memberIds + [currentUserId]
                    group = SocialGroup(id: group.id, name: group.name, description: group.description, city: group.city, inviteCode: group.inviteCode, imageUrl: group.imageUrl, memberIds: mutableIds, createdAt: group.createdAt)
                }
                
                // Update local currentUser Profile as well to link them to the group
                try await db.collection("users").document(currentUserId).updateData([
                    "groupIds": FieldValue.arrayUnion([group.id])
                ])
                
                self.currentGroup = group
                isLoading = false
                return true
            } else {
                self.error = "Código inválido o grupo no encontrado"
                isLoading = false
                return false
            }
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Create Group
    func createGroup(name: String, code: String) async -> Bool {
        isLoading = true
        error = nil
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.error = "No authenticated user"
            isLoading = false
            return false
        }
        
        let newGroup = SocialGroup(
            id: UUID().uuidString,
            name: name,
            description: "Grupo Privado",
            city: "General", // Se podría vincular al destino del usuario
            inviteCode: code,
            imageUrl: nil,
            memberIds: [currentUserId],
            createdAt: Date()
        )
        
        do {
            try db.collection("groups").document(newGroup.id).setData(from: newGroup)
            
            // Link to user profile
            try await db.collection("users").document(currentUserId).updateData([
                "groupIds": FieldValue.arrayUnion([newGroup.id])
            ])
            
            self.currentGroup = newGroup
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Leave Group
    func leaveGroup() async -> Bool {
        isLoading = true
        error = nil
        
        guard let currentUserId = Auth.auth().currentUser?.uid, let groupId = currentGroup?.id else {
            self.error = "No grupo o usuario activo"
            isLoading = false
            return false
        }
        
        do {
            // Remove user from group
            try await db.collection("groups").document(groupId).updateData([
                "memberIds": FieldValue.arrayRemove([currentUserId])
            ])
            
            // Remove group from user
            try await db.collection("users").document(currentUserId).updateData([
                "groupIds": FieldValue.arrayRemove([groupId])
            ])
            
            self.currentGroup = nil
            self.groupMembers = []
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Fetch User Group
    func fetchUserGroup() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let snapshot = try await db.collection("groups")
                .whereField("memberIds", arrayContains: currentUserId)
                .limit(to: 1)
                .getDocuments()
            
            if let doc = snapshot.documents.first {
                self.currentGroup = try doc.data(as: SocialGroup.self)
            } else {
                self.currentGroup = nil
            }
        } catch {
            print("Error fetching user group: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Fetch Members
    func fetchMembers() async {
        guard let memberIds = currentGroup?.memberIds, !memberIds.isEmpty else {
            DispatchQueue.main.async { self.groupMembers = [] }
            return
        }
        
        do {
            // Only fetching up to 10 for safety here, a real app might chunk this
            let chunks = memberIds.chunked(into: 10)
            var allMembers: [UserProfile] = []
            
            for chunk in chunks {
                let snapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                let members = snapshot.documents.compactMap { doc -> UserProfile? in
                    var user = try? doc.data(as: UserProfile.self)
                    if user != nil {
                        user?.id = doc.documentID
                    }
                    return user
                }
                allMembers.append(contentsOf: members)
            }
            
            let finalMembers = allMembers
            DispatchQueue.main.async {
                self.groupMembers = finalMembers
            }
        } catch {
            print("Error fetching group members: \(error)")
        }
    }
    
    // MARK: - Reset State
    func reset() {
        self.currentGroup = nil
        self.groupMembers = []
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
