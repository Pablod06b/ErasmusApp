// CityRequestManager.swift — peticiones de usuarios para activar nuevas ciudades
import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Gestiona las peticiones de los usuarios para que se active una ciudad.
/// Documento: `cityRequests/{cityName}` con:
///   - count: número total de peticiones (denormalizado)
///   - userIds: array de UIDs que quieren ser notificados al activar
///
/// Cuando una ciudad alcanza un umbral (configurable) podemos
/// activarla y enviar una push notification a todos los userIds.
@MainActor
final class CityRequestManager: ObservableObject {
    static let shared = CityRequestManager()

    @Published var requestedCities: Set<String> = []
    @Published var counts: [String: Int] = [:]

    private let db = Firestore.firestore()

    private init() {}

    /// El usuario actual se apunta para recibir notificación cuando se active la ciudad.
    /// Idempotente: si ya estaba apuntado, no duplica.
    @discardableResult
    func subscribe(toCity cityName: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let ref = db.collection("cityRequests").document(cityName)
        do {
            try await ref.setData([
                "userIds": FieldValue.arrayUnion([uid]),
                "count": FieldValue.increment(Int64(1)),
                "lastRequestedAt": FieldValue.serverTimestamp(),
                "cityName": cityName
            ], merge: true)
            requestedCities.insert(cityName)
            counts[cityName, default: 0] += 1
            AppErrorManager.shared.success("Te avisaremos cuando llegue a \(cityName) 🎉", icon: "bell.badge.fill")
            return true
        } catch {
            print("CityRequest error: \(error)")
            AppErrorManager.shared.report("No se pudo registrar tu petición. Inténtalo de nuevo.")
            return false
        }
    }

    /// El usuario se desapunta de las notificaciones de esa ciudad.
    @discardableResult
    func unsubscribe(fromCity cityName: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let ref = db.collection("cityRequests").document(cityName)
        do {
            try await ref.setData([
                "userIds": FieldValue.arrayRemove([uid]),
                "count": FieldValue.increment(Int64(-1))
            ], merge: true)
            requestedCities.remove(cityName)
            counts[cityName] = max(0, (counts[cityName] ?? 1) - 1)
            return true
        } catch {
            print("CityRequest unsubscribe error: \(error)")
            return false
        }
    }

    /// Devuelve true si el usuario actual ya pidió esta ciudad
    func hasRequested(_ cityName: String) -> Bool {
        requestedCities.contains(cityName)
    }

    /// Carga el estado actual al iniciar sesión: ¿qué ciudades pidió ya el usuario?
    func loadUserSubscriptions() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snap = try await db.collection("cityRequests").getDocuments()
            var subscribed = Set<String>()
            var newCounts: [String: Int] = [:]
            for doc in snap.documents {
                if let uids = doc.data()["userIds"] as? [String], uids.contains(uid) {
                    subscribed.insert(doc.documentID)
                }
                if let c = doc.data()["count"] as? Int {
                    newCounts[doc.documentID] = c
                }
            }
            requestedCities = subscribed
            counts = newCounts
        } catch {
            print("CityRequest load error: \(error)")
        }
    }
}
