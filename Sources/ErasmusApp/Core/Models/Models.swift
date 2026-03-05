// Models.swift
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum PostType: String, CaseIterable, Codable, Identifiable {
    case event = "Evento"
    case housing = "Casas"
    case recommendation = "Recomendación"
    case announcement = "Anuncio"
    case personalPlan = "Plan personal"
    case openMessage = "Mensaje abierto"
    
    var id: String { rawValue }
}

enum Visibility: String, CaseIterable, Codable, Identifiable {
    case everyone = "Todos"
    case friends = "Amigos"
    case onlyMe = "Solo yo"
    
    var id: String { rawValue }
}

struct ErasmusPost: Identifiable, Codable, Equatable {
    var id = UUID()
    let userId: String
    let type: PostType
    let title: String
    let description: String
    let location: String?
    let destination: String
    let date: Date?
    let isPaid: Bool?
    let price: Double?
    let allowSignups: Bool?
    let visibility: Visibility
    let imageName: String?
    let category: String?
    let contact: String?
    var isReported: Bool? = false
    let rating: Int?
    let participantsNeeded: Int?
    
    // Custom init to provide defaults for existing code
    init(id: UUID = UUID(), userId: String, type: PostType, title: String, description: String, location: String?, destination: String, date: Date?, isPaid: Bool?, price: Double?, allowSignups: Bool?, visibility: Visibility, imageName: String?, category: String?, contact: String?, isReported: Bool? = false, rating: Int? = nil, participantsNeeded: Int? = nil) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.description = description
        self.location = location
        self.destination = destination
        self.date = date
        self.isPaid = isPaid
        self.price = price
        self.allowSignups = allowSignups
        self.visibility = visibility
        self.imageName = imageName
        self.category = category
        self.contact = contact
        self.isReported = isReported
        self.rating = rating
        self.participantsNeeded = participantsNeeded
    }
    
    static func ==(lhs: ErasmusPost, rhs: ErasmusPost) -> Bool {
        return lhs.id == rhs.id
    }
}

#if canImport(UIKit)
// Extension para FileManager (para guardar imágenes)
extension FileManager {
    static func saveImage(_ image: UIImage, withName name: String) -> String? {
        if let data = image.jpegData(compressionQuality: 0.8),
           let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = documents.appendingPathComponent(name)
            do {
                try data.write(to: url)
                return name
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        return nil
    }
    
    static func loadImage(named name: String) -> UIImage? {
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = documents.appendingPathComponent(name)
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
}
#endif

struct Evento: Identifiable, Codable {
    let id = UUID()
    let title: String
    let location: String
    let date: String
    let imageName: String
    let participants: Int?
    let category: String
    var price: Double? = nil
}

struct Persona: Identifiable, Codable {
    let id = UUID()
    let name: String
    let imageName: String
    let commonInterests: Int
}


// MARK: - Notification Models (Moved to NotificationModel.swift)
