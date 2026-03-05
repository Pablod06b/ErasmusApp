import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al procesar la imagen"])
        }
        
        let ref = storage.reference().child("profile_images/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await ref.putDataAsync(data, metadata: metadata)
        
        var downloadURL: URL? = nil
        var lastError: Error? = nil
        
        for _ in 0..<3 {
            do {
                downloadURL = try await ref.downloadURL()
                break
            } catch {
                lastError = error
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        guard let finalURL = downloadURL else {
            throw lastError ?? NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la URL final."])
        }
        
        let photoStringUrl = finalURL.absoluteString
        
        // Update user profile in Firestore
        try await db.collection("users").document(userId).updateData([
            "photoURL": photoStringUrl
        ])
        
        return photoStringUrl
    }
    
    func updateUserProfile(userId: String, updates: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(updates)
    }
}
