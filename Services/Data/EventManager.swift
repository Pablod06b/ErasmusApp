import Foundation
import FirebaseFirestore

class EventManager: ObservableObject {
    static let shared = EventManager()
    private let db = Firestore.firestore()
    
    @Published var events: [Evento] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Fetch Events
    func fetchEvents(destination: String? = nil, category: String? = nil) async {
        DispatchQueue.main.async { self.isLoading = true }
        
        do {
            // In a real app we'd query Firestore "events" collection
            // For now we'll simulate a network delay and return the mock data 
            // but structure it ready for Firebase
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            
            var fetchedEvents = [
                Evento(title: "Candyland Party", location: "BCM - Salamanca", date: "15 Sept", imageName: "party", participants: nil, category: "Discotecas"),
                Evento(title: "Beerpong y tapas Erasmus", location: "París", date: "Dom 21 Jul", imageName: "beerpong", participants: 17, category: "Eventos"),
                Evento(title: "Viaje a Roma", location: "Roma", date: "21-22 Jul", imageName: "Roma", participants: 20, category: "Otros"),
                Evento(title: "Noche de Karaoke", location: "Camelot - Salamanca", date: "16 Sept", imageName: "party", participants: 12, category: "Eventos"),
                Evento(title: "Excursión a la Alberca", location: "Salamanca", date: "20 Sept", imageName: "nature", participants: 25, category: "Viajes")
            ]
            
            // Filter locally for now effectively mocking the query
            if let category = category, category != "Todos" {
                fetchedEvents = fetchedEvents.filter { $0.category == category }
            }
            
            DispatchQueue.main.async {
                self.events = fetchedEvents
                self.isLoading = false
            }
        } catch {
            print("Error fetching events: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}
