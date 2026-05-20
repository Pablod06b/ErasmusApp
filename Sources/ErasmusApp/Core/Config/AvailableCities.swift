// AvailableCities.swift — catálogo central de ciudades disponibles
import Foundation

/// Ciudad del catálogo de la app. Se centraliza aquí para que todos los
/// selectores (registro, header del feed, crear post, eventos, búsqueda)
/// consuman la misma lista y marquen visualmente las que están en "Próximamente".
struct AppCity: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let country: String
    let flag: String
    let isAvailable: Bool
}

enum AvailableCities {
    /// Ciudades 100% operativas. El feed, posts y eventos sólo se muestran aquí.
    static let active: [AppCity] = [
        AppCity(name: "Salamanca", country: "España", flag: "🇪🇸", isAvailable: true),
        AppCity(name: "Madrid",    country: "España", flag: "🇪🇸", isAvailable: true)
    ]

    /// Ciudades en lista de espera. Aparecen en el listado deshabilitadas con
    /// banner "Próximamente" y opción "Avísame cuando llegue".
    static let comingSoon: [AppCity] = [
        AppCity(name: "Barcelona", country: "España",     flag: "🇪🇸", isAvailable: false),
        AppCity(name: "Valencia",  country: "España",     flag: "🇪🇸", isAvailable: false),
        AppCity(name: "Sevilla",   country: "España",     flag: "🇪🇸", isAvailable: false),
        AppCity(name: "Granada",   country: "España",     flag: "🇪🇸", isAvailable: false),
        AppCity(name: "Roma",      country: "Italia",     flag: "🇮🇹", isAvailable: false),
        AppCity(name: "París",     country: "Francia",    flag: "🇫🇷", isAvailable: false),
        AppCity(name: "Berlín",    country: "Alemania",   flag: "🇩🇪", isAvailable: false),
        AppCity(name: "Lisboa",    country: "Portugal",   flag: "🇵🇹", isAvailable: false),
        AppCity(name: "Milán",     country: "Italia",     flag: "🇮🇹", isAvailable: false),
        AppCity(name: "Ámsterdam", country: "Países Bajos", flag: "🇳🇱", isAvailable: false)
    ]

    /// Catálogo completo (activas + próximamente) para selectores con UI de "muy pronto".
    static var all: [AppCity] { active + comingSoon }

    /// Nombres de ciudades activas — útil para validaciones y pickers legacy
    static var activeNames: [String] { active.map { $0.name } }

    /// Devuelve true si la ciudad está activa
    static func isActive(_ cityName: String) -> Bool {
        active.contains { $0.name == cityName }
    }

    /// Devuelve la AppCity por nombre, o nil
    static func city(named name: String) -> AppCity? {
        all.first { $0.name == name }
    }
}
