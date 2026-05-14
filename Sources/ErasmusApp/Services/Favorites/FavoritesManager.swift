// FavoritesManager.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published var savedPostIds: Set<String> = []
    @Published var savedEventIds: Set<String> = []
    @Published var savedCityNames: Set<String> = []
    @Published var savedUserIds: Set<String> = []
    @Published var savedItems: [SavedItem] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    // MARK: - Load Favorites

    func loadFavorites(for userId: String) {
        listener?.remove()
        listener = db.collection("users").document(userId)
            .collection("favorites")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else { return }
                let items = docs.compactMap { doc -> SavedItem? in
                    let data = doc.data()
                    guard
                        let itemId = data["itemId"] as? String,
                        let typeRaw = data["type"] as? String,
                        let type = SavedItemType(rawValue: typeRaw),
                        let ts = data["savedAt"] as? Timestamp,
                        let title = data["title"] as? String
                    else { return nil }
                    return SavedItem(
                        id: doc.documentID,
                        itemId: itemId,
                        type: type,
                        savedAt: ts.dateValue(),
                        title: title,
                        subtitle: data["subtitle"] as? String,
                        imageURL: data["imageURL"] as? String
                    )
                }
                Task { @MainActor in
                    self.savedItems = items.sorted { $0.savedAt > $1.savedAt }
                    self.savedPostIds = Set(items.filter { $0.type == .post }.map { $0.itemId })
                    self.savedEventIds = Set(items.filter { $0.type == .event }.map { $0.itemId })
                    self.savedCityNames = Set(items.filter { $0.type == .city }.map { $0.itemId })
                    self.savedUserIds = Set(items.filter { $0.type == .user }.map { $0.itemId })
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Toggle Post

    func togglePost(_ post: ErasmusPost) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let itemId = post.id.uuidString

        if savedPostIds.contains(itemId) {
            await removeFavorite(itemId: itemId, type: .post, userId: userId)
        } else {
            let item = SavedItem(
                itemId: itemId,
                type: .post,
                savedAt: Date(),
                title: post.title,
                subtitle: post.location,
                imageURL: post.imageName
            )
            await addFavorite(item: item, userId: userId)
        }
    }

    // MARK: - Toggle Event

    func toggleEvent(_ event: Evento) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let itemId = event.id.uuidString

        if savedEventIds.contains(itemId) {
            await removeFavorite(itemId: itemId, type: .event, userId: userId)
        } else {
            let item = SavedItem(
                itemId: itemId,
                type: .event,
                savedAt: Date(),
                title: event.title,
                subtitle: event.location,
                imageURL: event.imageName
            )
            await addFavorite(item: item, userId: userId)
        }
    }

    // MARK: - Toggle City

    func toggleCity(_ city: CityInfo) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let itemId = city.name

        if savedCityNames.contains(itemId) {
            await removeFavorite(itemId: itemId, type: .city, userId: userId)
        } else {
            let item = SavedItem(
                itemId: itemId,
                type: .city,
                savedAt: Date(),
                title: "\(city.countryFlag) \(city.name)",
                subtitle: city.country,
                imageURL: nil
            )
            await addFavorite(item: item, userId: userId)
        }
    }

    // MARK: - Toggle User

    func toggleUser(_ profile: UserProfile) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let itemId = profile.id

        if savedUserIds.contains(itemId) {
            await removeFavorite(itemId: itemId, type: .user, userId: userId)
        } else {
            let item = SavedItem(
                itemId: itemId,
                type: .user,
                savedAt: Date(),
                title: profile.displayName,
                subtitle: "@\(profile.username)",
                imageURL: profile.photoURL.isEmpty ? nil : profile.photoURL
            )
            await addFavorite(item: item, userId: userId)
        }
    }

    // MARK: - Helpers

    func isPostSaved(_ postId: String) -> Bool { savedPostIds.contains(postId) }
    func isEventSaved(_ eventId: String) -> Bool { savedEventIds.contains(eventId) }
    func isCitySaved(_ cityName: String) -> Bool { savedCityNames.contains(cityName) }
    func isUserSaved(_ userId: String) -> Bool { savedUserIds.contains(userId) }

    var savedCities: [CityInfo] {
        CityInfo.sampleCities.filter { savedCityNames.contains($0.name) }
    }

    // MARK: - Firebase CRUD

    private func addFavorite(item: SavedItem, userId: String) async {
        do {
            let data: [String: Any] = [
                "itemId": item.itemId,
                "type": item.type.rawValue,
                "savedAt": Timestamp(date: item.savedAt),
                "title": item.title,
                "subtitle": item.subtitle as Any,
                "imageURL": item.imageURL as Any
            ]
            try await db.collection("users").document(userId)
                .collection("favorites").document(item.id).setData(data)
        } catch {
            print("Error saving favorite: \(error)")
        }
    }

    private func removeFavorite(itemId: String, type: SavedItemType, userId: String) async {
        do {
            // Find the document with matching itemId and type
            let snapshot = try await db.collection("users").document(userId)
                .collection("favorites")
                .whereField("itemId", isEqualTo: itemId)
                .whereField("type", isEqualTo: type.rawValue)
                .getDocuments()

            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
        } catch {
            print("Error removing favorite: \(error)")
        }
    }
}
