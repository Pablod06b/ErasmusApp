// GeocodeCache.swift — caché en memoria + UserDefaults para geocoding de direcciones
import Foundation
import CoreLocation
import MapKit

/// Cache simple para evitar pedir al geocoder dos veces la misma dirección
/// dentro de la misma sesión. Las coords se serializan en UserDefaults para
/// que sobrevivan entre lanzamientos. Las ciudades activas las tenemos
/// precargadas en el catálogo.
actor GeocodeCache {
    static let shared = GeocodeCache()

    private var memory: [String: CLLocationCoordinate2D] = [:]
    private let geocoder = CLGeocoder()
    private let defaultsKey = "GeocodeCache.v1"

    private init() {
        loadFromDefaults()
        // Precarga coords aproximadas de las ciudades activas
        for (name, coord) in Self.bakedCities {
            memory[name.lowercased()] = coord
        }
    }

    /// Coords aproximadas de las ciudades activas y comunes.
    /// Centradas en el centro turístico/casco histórico.
    static let bakedCities: [String: CLLocationCoordinate2D] = [
        "Salamanca": CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635),
        "Madrid":    CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        "Barcelona": CLLocationCoordinate2D(latitude: 41.3851, longitude:  2.1734),
        "Valencia":  CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
        "Sevilla":   CLLocationCoordinate2D(latitude: 37.3891, longitude: -5.9845),
        "Granada":   CLLocationCoordinate2D(latitude: 37.1773, longitude: -3.5986),
        "Roma":      CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
        "París":     CLLocationCoordinate2D(latitude: 48.8566, longitude:  2.3522),
        "Berlín":    CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        "Lisboa":    CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
        "Milán":     CLLocationCoordinate2D(latitude: 45.4642, longitude:  9.1900),
        "Ámsterdam": CLLocationCoordinate2D(latitude: 52.3676, longitude:  4.9041)
    ]

    /// Devuelve las coordenadas para una dirección. Mira primero en caché,
    /// luego pide al geocoder y guarda el resultado.
    func coordinates(for address: String) async -> CLLocationCoordinate2D? {
        let key = address.lowercased().trimmingCharacters(in: .whitespaces)
        if key.isEmpty { return nil }
        if let cached = memory[key] { return cached }

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let coord = placemarks.first?.location?.coordinate {
                memory[key] = coord
                saveToDefaults()
                return coord
            }
        } catch {
            // Geocoder rate limit / sin conexión / dirección inválida
        }
        return nil
    }

    /// Devuelve el centro de una ciudad activa (consulta instantánea desde el catálogo).
    nonisolated func coordinatesForActiveCity(_ name: String) -> CLLocationCoordinate2D? {
        Self.bakedCities[name]
    }

    // MARK: - Persistencia (UserDefaults)

    private func saveToDefaults() {
        var dict: [String: [Double]] = [:]
        for (key, coord) in memory {
            dict[key] = [coord.latitude, coord.longitude]
        }
        UserDefaults.standard.set(dict, forKey: defaultsKey)
    }

    private func loadFromDefaults() {
        guard let dict = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: [Double]] else { return }
        for (key, arr) in dict where arr.count == 2 {
            memory[key] = CLLocationCoordinate2D(latitude: arr[0], longitude: arr[1])
        }
    }
}
