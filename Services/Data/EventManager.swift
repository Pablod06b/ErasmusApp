import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class EventManager: ObservableObject {
    static let shared = EventManager()
    private let db = Firestore.firestore()

    @Published var events: [Evento] = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Fetch Events from Firebase
    func fetchEvents(destination: String? = nil, category: String? = nil) async {
        isLoading = true

        do {
            var query: Query = db.collection("events")

            if let city = destination, !city.isEmpty {
                query = query.whereField("city", isEqualTo: city)
            }

            let snapshot = try await query.getDocuments()

            var fetched: [Evento] = snapshot.documents.compactMap { doc -> Evento? in
                let data = doc.data()
                return Evento(
                    title: data["title"] as? String ?? "Evento",
                    location: data["location"] as? String ?? "",
                    date: data["date"] as? String ?? "",
                    imageName: data["imageName"] as? String ?? "calendar",
                    participants: data["participants"] as? Int,
                    category: data["category"] as? String ?? "Eventos",
                    price: data["price"] as? Double,
                    firestoreId: doc.documentID,
                    userId: data["userId"] as? String,
                    city: data["city"] as? String,
                    isVerifiedBusiness: data["isVerifiedBusiness"] as? Bool ?? false,
                    isPromoted: data["isPromoted"] as? Bool ?? false,
                    eventDescription: data["eventDescription"] as? String,
                    imageURL: data["imageURL"] as? String
                )
            }

            // Fallback to sample data when Firebase is empty
            if fetched.isEmpty {
                fetched = sampleEvents(for: destination)
            }

            // Category filter
            if let category = category, category != "Todos" {
                fetched = fetched.filter { $0.category == category }
            }

            // Sort: promoted first, then verified business, then regular
            fetched.sort {
                let a = ($0.isPromoted == true ? 2 : 0) + ($0.isVerifiedBusiness == true ? 1 : 0)
                let b = ($1.isPromoted == true ? 2 : 0) + ($1.isVerifiedBusiness == true ? 1 : 0)
                return a > b
            }

            events = fetched
            isLoading = false
        } catch {
            print("Error fetching events: \(error)")
            events = sampleEvents(for: destination)
            isLoading = false
        }
    }

    // MARK: - Create Event
    func createEvent(
        title: String, location: String, date: String, category: String,
        city: String, description: String? = nil, price: Double? = nil,
        participants: Int? = nil, imageURL: String? = nil
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var data: [String: Any] = [
            "title": title, "location": location, "date": date,
            "category": category, "city": city, "userId": uid,
            "isVerifiedBusiness": false, "isPromoted": false,
            "imageName": "calendar", "createdAt": FieldValue.serverTimestamp()
        ]
        if let p = participants { data["participants"] = p }
        if let pr = price { data["price"] = pr }
        if let d = description { data["eventDescription"] = d }
        if let img = imageURL { data["imageURL"] = img }

        try await db.collection("events").addDocument(data: data)
        await fetchEvents(destination: city)
    }

    // MARK: - Sample Events (shown when Firebase collection is empty)
    private func sampleEvents(for destination: String?) -> [Evento] {
        let city = destination ?? "Salamanca"
        return [
            Evento(title: "Candyland Party", location: "BCM - \(city)", date: "15 Sept",
                   imageName: "music.note", participants: nil, category: "Discotecas",
                   city: city, isVerifiedBusiness: true, isPromoted: true,
                   eventDescription: "La fiesta más grande del Erasmus"),
            Evento(title: "Beerpong Erasmus", location: city, date: "Dom 21 Jul",
                   imageName: "party.popper", participants: 17, category: "Eventos",
                   city: city, isVerifiedBusiness: false, isPromoted: false),
            Evento(title: "Free Tour Erasmus", location: city, date: "Mañana 10:00",
                   imageName: "figure.walk", participants: 20, category: "Otros",
                   city: city, isVerifiedBusiness: true, isPromoted: false,
                   eventDescription: "Descubre la ciudad con otros erasmus"),
            Evento(title: "Noche de Karaoke", location: "Camelot - \(city)", date: "16 Sept",
                   imageName: "mic.fill", participants: 12, category: "Eventos",
                   city: city, isVerifiedBusiness: false, isPromoted: false),
            Evento(title: "Excursión Fin de Semana", location: city, date: "20 Sept",
                   imageName: "mountain.2.fill", participants: 25, category: "Viajes",
                   city: city, isVerifiedBusiness: false, isPromoted: false)
        ]
    }
}
