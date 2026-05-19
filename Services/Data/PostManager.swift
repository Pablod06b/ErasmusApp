import Foundation
import FirebaseFirestore
import FirebaseStorage
#if canImport(UIKit)
import UIKit
#endif


class PostManager: ObservableObject {
    static let shared = PostManager()
    private let db = Firestore.firestore()
    
    @Published var posts: [ErasmusPost] = []
    @Published var isLoading = false
    
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Upload Image
    #if canImport(UIKit)
    func uploadPostImage(_ image: UIImage, postId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error compressing image"])
        }
        
        let ref = storage.reference().child("posts/\(postId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await ref.putDataAsync(data, metadata: metadata)
        
        var downloadURL: URL? = nil
        var lastError: Error? = nil
        
        // Firebase Storage on iOS sometimes takes a moment to make the object visible to downloadURL
        for _ in 0..<3 {
            do {
                downloadURL = try await ref.downloadURL()
                break
            } catch {
                lastError = error
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        
        if let url = downloadURL {
            return url.absoluteString
        } else {
            throw lastError ?? NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la URL final."])
        }
    }
    #endif
    
    // MARK: - Create Post
    func createPost(_ post: ErasmusPost) async throws {
        isLoading = true
        do {
            // We can convert UUID to String for Firestore ID or use auto-id
            // Here we use the UUID as the document ID
            let data = try Firestore.Encoder().encode(post)
            try await db.collection("posts").document(post.id.uuidString).setData(data)
            await fetchPosts() // Refresh
            isLoading = false
        } catch {
            isLoading = false
            print("Error creating post: \(error)")
            throw error
        }
    }
    
    // MARK: - Pagination Properties
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 10
    
    // MARK: - Fetch Posts (Paginated)
    func fetchInitialPosts(destination: String? = nil) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.posts = [] // Reset for new refresh
        }
        self.lastDocument = nil
        
        await fetchPostBatch(destination: destination)
    }
    
    func fetchMorePosts(destination: String? = nil) async {
        guard !isLoading, lastDocument != nil else { return }
        await fetchPostBatch(destination: destination)
    }
    
    // Legacy support to match existing HomeView call, redirects to initial fetch
    func fetchPosts(destination: String? = nil) async {
        await fetchInitialPosts(destination: destination)
    }
    
    private func fetchPostBatch(destination: String?) async {
        do {
            var query: Query = db.collection("posts")

            if let destination = destination {
                query = query.whereField("destination", isEqualTo: destination)
            }

            // Limit and Pagination
            query = query.limit(to: pageSize)

            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }

            let snapshot = try await query.getDocuments()
            let fetchedPosts = try snapshot.documents.compactMap { doc -> ErasmusPost? in
                try doc.data(as: ErasmusPost.self)
            }

            // Filtrar posts de usuarios bloqueados
            let blocked = await MainActor.run { SocialManager.shared.blockedUserIds }
            let visible = fetchedPosts.filter { !blocked.contains($0.userId) }

            // Update cursor
            self.lastDocument = snapshot.documents.last

            DispatchQueue.main.async {
                self.posts.append(contentsOf: visible)
                self.isLoading = false
            }
        } catch {
            print("Error fetching posts: \(error)")
            await MainActor.run {
                AppErrorManager.shared.report("No se pudo cargar el feed. Revisa tu conexión.", icon: "wifi.exclamationmark")
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch Posts by User

    /// Fetches all posts authored by a specific user, most-recent first.
    func fetchUserPosts(userId: String) async -> [ErasmusPost] {
        guard !userId.isEmpty else { return [] }
        do {
            let snapshot = try await db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .limit(to: 50)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: ErasmusPost.self) }
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        } catch {
            print("Error fetching user posts: \(error)")
            return []
        }
    }

    // MARK: - Likes

    /// Returns (isLiked, likeCount) for a post and current user
    func fetchLikeStatus(postId: String, userId: String) async -> (Bool, Int) {
        do {
            let doc = try await db.collection("posts").document(postId).getDocument()
            let likedBy = doc.data()?["likedBy"] as? [String] ?? []
            return (likedBy.contains(userId), likedBy.count)
        } catch {
            print("Error fetching like status: \(error)")
            return (false, 0)
        }
    }

    /// Toggles the like for a user on a post. Returns new state (isLiked, likeCount).
    @discardableResult
    func toggleLike(postId: String, userId: String) async -> (Bool, Int) {
        let ref = db.collection("posts").document(postId)
        do {
            let doc = try await ref.getDocument()
            var likedBy = doc.data()?["likedBy"] as? [String] ?? []
            let isCurrentlyLiked = likedBy.contains(userId)

            if isCurrentlyLiked {
                try await ref.updateData(["likedBy": FieldValue.arrayRemove([userId])])
                likedBy.removeAll { $0 == userId }
            } else {
                try await ref.updateData(["likedBy": FieldValue.arrayUnion([userId])])
                likedBy.append(userId)
            }
            return (!isCurrentlyLiked, likedBy.count)
        } catch {
            // If update fails (document missing field), set it
            do {
                let doc = try await ref.getDocument()
                if doc.exists {
                    try await ref.setData(["likedBy": [userId]], merge: true)
                    return (true, 1)
                }
            } catch {}
            print("Error toggling like: \(error)")
            return (false, 0)
        }
    }

    // MARK: - Comments

    /// Fetches all comments for a post, ordered by creation date
    func fetchComments(postId: String) async -> [PostComment] {
        do {
            let snapshot = try await db.collection("posts").document(postId)
                .collection("comments")
                .order(by: "createdAt", descending: false)
                .getDocuments()
            return snapshot.documents.compactMap { doc -> PostComment? in
                let data = doc.data()
                return PostComment(
                    id: doc.documentID,
                    postId: data["postId"] as? String ?? postId,
                    userId: data["userId"] as? String ?? "",
                    userName: data["userName"] as? String ?? "Usuario",
                    userPhotoURL: data["userPhotoURL"] as? String,
                    content: data["content"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    likes: data["likes"] as? Int ?? 0
                )
            }
        } catch {
            print("Error fetching comments: \(error)")
            return []
        }
    }

    /// Adds a comment to a post in Firestore
    func addComment(postId: String, comment: PostComment) async {
        let ref = db.collection("posts").document(postId).collection("comments").document(comment.id)
        let data: [String: Any] = [
            "postId": comment.postId,
            "userId": comment.userId,
            "userName": comment.userName,
            "userPhotoURL": comment.userPhotoURL as Any,
            "content": comment.content,
            "createdAt": Timestamp(date: comment.createdAt),
            "likes": comment.likes
        ]
        do {
            try await ref.setData(data)
        } catch {
            print("Error adding comment: \(error)")
        }
    }
}
