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
            
            // Update cursor
            self.lastDocument = snapshot.documents.last
            
            DispatchQueue.main.async {
                // If it's a reload (lastDocument was nil at start of call but local var capture... 
                // actually we check if we are appending or setting)
                // Since this method is generic, let's look at `self.posts`
                // BUT: We reset `self.posts = []` in fetchInitialPosts.
                // However, doing that on MainActor async might race if we are not careful.
                // Better approach: append to existing if lastDocument existed locally BEFORE this call? 
                // No, simpler: check if the new batch belongs at the end.
                
                // For simplicity in this step: direct append.
                // Note: fetchInitialPosts clears the array.
                
                self.posts.append(contentsOf: fetchedPosts)
                self.isLoading = false
            }
        } catch {
            print("Error fetching posts: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}
