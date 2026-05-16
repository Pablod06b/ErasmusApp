// SocialManager.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SocialManager: ObservableObject {
    static let shared = SocialManager()

    @Published var friendRequests: [FriendRequest] = []
    @Published var pendingRequestCount: Int = 0
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()
    private var requestsListener: ListenerRegistration?

    private init() {}

    // MARK: - Follow / Unfollow

    func follow(userId targetId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        let batch = db.batch()

        // Add targetId to my followingIds
        let myRef = db.collection("users").document(myId)
        batch.updateData(["followingIds": FieldValue.arrayUnion([targetId])], forDocument: myRef)

        // Add myId to target's followerIds
        let targetRef = db.collection("users").document(targetId)
        batch.updateData(["followerIds": FieldValue.arrayUnion([myId])], forDocument: targetRef)

        try await batch.commit()

        // Send notification
        await sendNotification(
            toUserId: targetId,
            type: .newFollower,
            title: "Nuevo seguidor",
            message: "Ha empezado a seguirte",
            relatedItemId: myId
        )
    }

    func unfollow(userId targetId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        let batch = db.batch()

        let myRef = db.collection("users").document(myId)
        batch.updateData(["followingIds": FieldValue.arrayRemove([targetId])], forDocument: myRef)

        let targetRef = db.collection("users").document(targetId)
        batch.updateData(["followerIds": FieldValue.arrayRemove([myId])], forDocument: targetRef)

        try await batch.commit()
    }

    // MARK: - Friend Requests

    func sendFriendRequest(toUserId targetId: String, toUserName: String, toUserPhotoURL: String? = nil) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }

        let myDoc = try await db.collection("users").document(myId).getDocument()
        let myName = myDoc.data()?["displayName"] as? String ?? "Usuario"
        let myPhoto = myDoc.data()?["photoURL"] as? String

        let request = FriendRequest(
            fromUserId: myId,
            fromUserName: myName,
            fromUserPhotoURL: myPhoto,
            toUserId: targetId,
            status: .pending,
            createdAt: Date()
        )

        let requestData: [String: Any] = [
            "id": request.id,
            "fromUserId": request.fromUserId,
            "fromUserName": request.fromUserName,
            "fromUserPhotoURL": request.fromUserPhotoURL as Any,
            "toUserId": request.toUserId,
            "status": request.status.rawValue,
            "createdAt": Timestamp(date: request.createdAt)
        ]

        // Save request in both sender and receiver subcollections
        try await db.collection("users").document(targetId)
            .collection("friendRequests").document(request.id).setData(requestData)

        try await db.collection("users").document(myId)
            .collection("sentRequests").document(request.id).setData(requestData)

        // Add to pending list
        let targetRef = db.collection("users").document(targetId)
        try await targetRef.updateData(["pendingFriendRequestIds": FieldValue.arrayUnion([myId])])

        // relatedItemId = request.id so the receiver can accept/reject using it
        await sendNotification(
            toUserId: targetId,
            type: .friendRequest,
            title: "Solicitud de amistad",
            message: "\(myName) quiere ser tu amigo",
            relatedItemId: request.id
        )
    }

    func acceptFriendRequest(requestId: String, fromUserId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }

        // Find the actual friend request document (requestId may be the doc ID or we search by fromUserId)
        let requestsRef = db.collection("users").document(myId).collection("friendRequests")
        var actualRequestId = requestId

        // Verify the request document exists; if not, find it by fromUserId
        let directDoc = try? await requestsRef.document(requestId).getDocument()
        if directDoc?.exists != true {
            let query = try? await requestsRef.whereField("fromUserId", isEqualTo: fromUserId).getDocuments()
            actualRequestId = query?.documents.first?.documentID ?? requestId
        }

        let batch = db.batch()

        // Update request status
        let requestRef = requestsRef.document(actualRequestId)
        batch.updateData(["status": "accepted"], forDocument: requestRef)

        // Add each other as friends
        let myRef = db.collection("users").document(myId)
        batch.updateData([
            "friendIds": FieldValue.arrayUnion([fromUserId]),
            "pendingFriendRequestIds": FieldValue.arrayRemove([fromUserId])
        ], forDocument: myRef)

        let theirRef = db.collection("users").document(fromUserId)
        batch.updateData(["friendIds": FieldValue.arrayUnion([myId])], forDocument: theirRef)

        try await batch.commit()

        // Notify the sender
        let myDoc = try await db.collection("users").document(myId).getDocument()
        let myName = myDoc.data()?["displayName"] as? String ?? "Usuario"

        await sendNotification(
            toUserId: fromUserId,
            type: .friendAccepted,
            title: "¡Solicitud aceptada!",
            message: "\(myName) aceptó tu solicitud de amistad",
            relatedItemId: myId
        )
    }

    func rejectFriendRequest(requestId: String, fromUserId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }

        let requestsRef = db.collection("users").document(myId).collection("friendRequests")
        var actualRequestId = requestId

        let directDoc = try? await requestsRef.document(requestId).getDocument()
        if directDoc?.exists != true {
            let query = try? await requestsRef.whereField("fromUserId", isEqualTo: fromUserId).getDocuments()
            actualRequestId = query?.documents.first?.documentID ?? requestId
        }

        try await requestsRef.document(actualRequestId).updateData(["status": "rejected"])
        try await db.collection("users").document(myId)
            .updateData(["pendingFriendRequestIds": FieldValue.arrayRemove([fromUserId])])
    }

    func removeFriend(userId targetId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        let batch = db.batch()

        let myRef = db.collection("users").document(myId)
        batch.updateData(["friendIds": FieldValue.arrayRemove([targetId])], forDocument: myRef)

        let targetRef = db.collection("users").document(targetId)
        batch.updateData(["friendIds": FieldValue.arrayRemove([myId])], forDocument: targetRef)

        try await batch.commit()
    }

    // MARK: - Listen for Incoming Friend Requests

    func startListeningForRequests() {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        requestsListener?.remove()

        requestsListener = db.collection("users").document(myId)
            .collection("friendRequests")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let docs = snapshot?.documents else { return }
                let requests = docs.compactMap { doc -> FriendRequest? in
                    let data = doc.data()
                    guard
                        let fromId = data["fromUserId"] as? String,
                        let fromName = data["fromUserName"] as? String,
                        let toId = data["toUserId"] as? String,
                        let statusRaw = data["status"] as? String,
                        let status = FriendRequest.FriendRequestStatus(rawValue: statusRaw),
                        let ts = data["createdAt"] as? Timestamp
                    else { return nil }
                    return FriendRequest(
                        id: doc.documentID,
                        fromUserId: fromId,
                        fromUserName: fromName,
                        fromUserPhotoURL: data["fromUserPhotoURL"] as? String,
                        toUserId: toId,
                        status: status,
                        createdAt: ts.dateValue()
                    )
                }
                Task { @MainActor in
                    self.friendRequests = requests
                    self.pendingRequestCount = requests.count
                }
            }
    }

    func stopListening() {
        requestsListener?.remove()
        requestsListener = nil
    }

    // MARK: - Social Status Check

    func socialStatus(with userId: String, myProfile: UserProfile) -> SocialStatus {
        if myProfile.friendIds.contains(userId) { return .friends }
        if myProfile.pendingFriendRequestIds.contains(userId) { return .requestSent }
        if myProfile.followingIds.contains(userId) { return .following }
        return .none
    }

    // MARK: - User Discovery

    func fetchUsers(destination: String? = nil, interests: [String] = [], language: String? = nil, university: String? = nil) async -> [UserProfile] {
        guard let myId = Auth.auth().currentUser?.uid else { return [] }

        do {
            var query: Query = db.collection("users")

            if let dest = destination, !dest.isEmpty {
                query = query.whereField("destination", isEqualTo: dest)
            }

            let snapshot = try await query.limit(to: 40).getDocuments()

            return snapshot.documents.compactMap { doc -> UserProfile? in
                guard doc.documentID != myId else { return nil }
                return try? doc.data(as: UserProfile.self)
            }.filter { user in
                if !interests.isEmpty {
                    let commonInterests = Set(user.interests).intersection(Set(interests))
                    if commonInterests.isEmpty { return false }
                }
                if let lang = language, !lang.isEmpty {
                    let hasLang = user.languages.contains { $0.language.lowercased().contains(lang.lowercased()) }
                    if !hasLang { return false }
                }
                if let uni = university, !uni.isEmpty {
                    if !user.university.lowercased().contains(uni.lowercased()) { return false }
                }
                return true
            }
        } catch {
            print("Error fetching users: \(error)")
            return []
        }
    }

    // MARK: - Open Plan Participation

    func joinPlan(postId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }

        let myDoc = try await db.collection("users").document(myId).getDocument()
        let myName = myDoc.data()?["displayName"] as? String ?? "Usuario"
        let myPhoto = myDoc.data()?["photoURL"] as? String

        let participant = PlanParticipant(
            userId: myId,
            userName: myName,
            userPhotoURL: myPhoto,
            joinedAt: Date()
        )

        let participantData: [String: Any] = [
            "id": participant.id,
            "userId": participant.userId,
            "userName": participant.userName,
            "userPhotoURL": participant.userPhotoURL as Any,
            "joinedAt": Timestamp(date: participant.joinedAt)
        ]

        try await db.collection("openPlans").document(postId)
            .collection("participants").document(myId).setData(participantData)

        // Notify plan creator
        let postDoc = try await db.collection("posts").document(postId).getDocument()
        if let creatorId = postDoc.data()?["userId"] as? String, creatorId != myId {
            await sendNotification(
                toUserId: creatorId,
                type: .planJoin,
                title: "Alguien se apuntó a tu plan",
                message: "\(myName) se ha unido a tu plan",
                relatedItemId: postId
            )
        }
    }

    func leavePlan(postId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("openPlans").document(postId)
            .collection("participants").document(myId).delete()
    }

    func fetchPlanParticipants(postId: String) async -> [PlanParticipant] {
        do {
            let snapshot = try await db.collection("openPlans").document(postId)
                .collection("participants").getDocuments()
            return snapshot.documents.compactMap { doc -> PlanParticipant? in
                let data = doc.data()
                guard
                    let userId = data["userId"] as? String,
                    let userName = data["userName"] as? String,
                    let ts = data["joinedAt"] as? Timestamp
                else { return nil }
                return PlanParticipant(
                    id: doc.documentID,
                    userId: userId,
                    userName: userName,
                    userPhotoURL: data["userPhotoURL"] as? String,
                    joinedAt: ts.dateValue()
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Fetch Friends

    /// Fetches UserProfile objects for a list of friend IDs
    func fetchFriends(ids: [String]) async -> [UserProfile] {
        guard !ids.isEmpty else { return [] }
        do {
            // Firestore 'in' queries support up to 30 items
            let batches = stride(from: 0, to: ids.count, by: 30).map {
                Array(ids[$0..<min($0 + 30, ids.count)])
            }
            var results: [UserProfile] = []
            for batch in batches {
                let snapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: batch)
                    .getDocuments()
                let profiles = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
                results.append(contentsOf: profiles)
            }
            return results
        } catch {
            print("Error fetching friends: \(error)")
            return []
        }
    }

    // MARK: - Private Helpers

    private func sendNotification(toUserId: String, type: NotificationType, title: String, message: String, relatedItemId: String?) async {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        do {
            let myDoc = try await db.collection("users").document(myId).getDocument()
            let myName = myDoc.data()?["displayName"] as? String ?? "Usuario"
            let myPhoto = myDoc.data()?["photoURL"] as? String

            let notifData: [String: Any] = [
                "type": type.rawValue,
                "title": title,
                "message": message,
                "date": Timestamp(date: Date()),
                "isRead": false,
                "relatedItemId": relatedItemId as Any,
                "fromUserId": myId,
                "fromUserName": myName,
                "fromUserPhotoURL": myPhoto as Any
            ]
            try await db.collection("users").document(toUserId)
                .collection("notifications").addDocument(data: notifData)
        } catch {
            print("Error sending notification: \(error)")
        }
    }
}

// MARK: - Social Status
enum SocialStatus {
    case none
    case following
    case requestSent
    case friends
}
