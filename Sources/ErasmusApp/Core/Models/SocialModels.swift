// SocialModels.swift
import Foundation

// MARK: - Friend Request
struct FriendRequest: Identifiable, Codable {
    var id: String = UUID().uuidString
    let fromUserId: String
    let fromUserName: String
    let fromUserPhotoURL: String?
    let toUserId: String
    var status: FriendRequestStatus
    let createdAt: Date

    enum FriendRequestStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
    }
}

// MARK: - Open Plan Participation
struct PlanParticipant: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let userName: String
    let userPhotoURL: String?
    let joinedAt: Date
}

struct OpenPlanDetail: Identifiable, Codable {
    var id: String
    let postId: String
    var participants: [PlanParticipant]
    let maxParticipants: Int?
    var miniChatMessages: [PlanChatMessage]

    var isFull: Bool {
        guard let max = maxParticipants else { return false }
        return participants.count >= max
    }
}

struct PlanChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let userName: String
    let content: String
    let createdAt: Date
}

// MARK: - City Info (Destination Explorer)
struct CityInfo: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let country: String
    let countryFlag: String
    let coverImageName: String
    let description: String
    let costOfLiving: CostLevel
    let partyScene: Int          // 1-5
    let cultureScore: Int        // 1-5
    let safetyScore: Int         // 1-5
    let climateDescription: String
    let universities: [String]
    let topAttractions: [String]
    let studentPopulation: Int
    let averageRent: String
    let language: String

    enum CostLevel: String, Codable {
        case low = "Bajo"
        case medium = "Medio"
        case high = "Alto"
        case veryHigh = "Muy alto"

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .veryHigh: return "red"
            }
        }

        var icon: String {
            switch self {
            case .low: return "€"
            case .medium: return "€€"
            case .high: return "€€€"
            case .veryHigh: return "€€€€"
            }
        }
    }

    // MARK: - Sample Cities
    static let sampleCities: [CityInfo] = [
        CityInfo(
            id: "rome",
            name: "Roma",
            country: "Italia",
            countryFlag: "🇮🇹",
            coverImageName: "Roma",
            description: "La Ciudad Eterna te espera. Historia, arte, pasta y una vida estudiantil increíble.",
            costOfLiving: .medium,
            partyScene: 4,
            cultureScore: 5,
            safetyScore: 3,
            climateDescription: "Mediterráneo, veranos calurosos e inviernos suaves",
            universities: ["La Sapienza", "Università Roma Tre", "LUISS"],
            topAttractions: ["Coliseo", "Vaticano", "Fontana di Trevi", "Trastevere"],
            studentPopulation: 45000,
            averageRent: "500-700€/mes",
            language: "Italiano"
        ),
        CityInfo(
            id: "prague",
            name: "Praga",
            country: "República Checa",
            countryFlag: "🇨🇿",
            coverImageName: "default_image",
            description: "La ciudad de las cien torres. Cerveza barata, arquitectura gótica y vida nocturna legendaria.",
            costOfLiving: .low,
            partyScene: 5,
            cultureScore: 4,
            safetyScore: 4,
            climateDescription: "Continental, inviernos fríos y veranos agradables",
            universities: ["Charles University", "CTU Prague"],
            topAttractions: ["Puente Carlos", "Barrio Judío", "Viejo Ayuntamiento"],
            studentPopulation: 30000,
            averageRent: "300-500€/mes",
            language: "Checo / Inglés"
        ),
        CityInfo(
            id: "lisbon",
            name: "Lisboa",
            country: "Portugal",
            countryFlag: "🇵🇹",
            coverImageName: "default_image",
            description: "Fados, pastéis de nata y atardeceres sobre el Tajo. La ciudad más vibrante de la península.",
            costOfLiving: .medium,
            partyScene: 4,
            cultureScore: 4,
            safetyScore: 5,
            climateDescription: "Atlántico, sol casi todo el año y lluvia en invierno",
            universities: ["Universidade de Lisboa", "Nova SBE", "ISCTE"],
            topAttractions: ["Belém", "Alfama", "LX Factory", "Sintra"],
            studentPopulation: 35000,
            averageRent: "500-750€/mes",
            language: "Portugués"
        ),
        CityInfo(
            id: "berlin",
            name: "Berlín",
            country: "Alemania",
            countryFlag: "🇩🇪",
            coverImageName: "default_image",
            description: "La capital del arte underground, la electrónica y la historia moderna. Una ciudad que nunca duerme.",
            costOfLiving: .medium,
            partyScene: 5,
            cultureScore: 5,
            safetyScore: 4,
            climateDescription: "Continental, inviernos muy fríos y veranos cálidos",
            universities: ["Humboldt-Universität", "TU Berlin", "FU Berlin"],
            topAttractions: ["Muro de Berlín", "Puerta de Brandeburgo", "East Side Gallery"],
            studentPopulation: 60000,
            averageRent: "600-900€/mes",
            language: "Alemán"
        ),
        CityInfo(
            id: "amsterdam",
            name: "Ámsterdam",
            country: "Países Bajos",
            countryFlag: "🇳🇱",
            coverImageName: "default_image",
            description: "Canales, bicicletas, museos de clase mundial y una cultura increíblemente abierta y cosmopolita.",
            costOfLiving: .high,
            partyScene: 4,
            cultureScore: 5,
            safetyScore: 4,
            climateDescription: "Oceánico, lluvioso y templado todo el año",
            universities: ["University of Amsterdam", "VU Amsterdam"],
            topAttractions: ["Rijksmuseum", "Anne Frank House", "Jordaan", "Vondelpark"],
            studentPopulation: 40000,
            averageRent: "800-1200€/mes",
            language: "Neerlandés / Inglés"
        ),
        CityInfo(
            id: "barcelona",
            name: "Barcelona",
            country: "España",
            countryFlag: "🇪🇸",
            coverImageName: "default_image",
            description: "Mar, Gaudí, fútbol y una escena de fiestas que no tiene rival. La ciudad perfecta para el Erasmus.",
            costOfLiving: .medium,
            partyScene: 5,
            cultureScore: 5,
            safetyScore: 3,
            climateDescription: "Mediterráneo, soleado casi todo el año",
            universities: ["UB", "UAB", "UPF", "UPC"],
            topAttractions: ["Sagrada Família", "Las Ramblas", "Park Güell", "Barceloneta"],
            studentPopulation: 55000,
            averageRent: "600-900€/mes",
            language: "Castellano / Catalán"
        ),
        CityInfo(
            id: "warsaw",
            name: "Varsovia",
            country: "Polonia",
            countryFlag: "🇵🇱",
            coverImageName: "default_image",
            description: "Ciudad en auge con historia fascinante, comida deliciosa y un coste de vida muy bajo.",
            costOfLiving: .low,
            partyScene: 4,
            cultureScore: 4,
            safetyScore: 4,
            climateDescription: "Continental, inviernos muy fríos y veranos calurosos",
            universities: ["University of Warsaw", "Warsaw University of Technology"],
            topAttractions: ["Ciudad Vieja", "Museo del Alzamiento", "Łazienki Park"],
            studentPopulation: 25000,
            averageRent: "250-400€/mes",
            language: "Polaco"
        ),
        CityInfo(
            id: "vienna",
            name: "Viena",
            country: "Austria",
            countryFlag: "🇦🇹",
            coverImageName: "default_image",
            description: "Música clásica, cafés imperiales y palacios. La ciudad más elegante de Europa para estudiar.",
            costOfLiving: .high,
            partyScene: 3,
            cultureScore: 5,
            safetyScore: 5,
            climateDescription: "Continental, cuatro estaciones bien definidas",
            universities: ["Universität Wien", "TU Wien", "WU Vienna"],
            topAttractions: ["Palacio de Schönbrunn", "Belvedere", "Prater"],
            studentPopulation: 30000,
            averageRent: "600-900€/mes",
            language: "Alemán"
        )
    ]
}

// MARK: - Post Comment
struct PostComment: Identifiable, Codable {
    var id: String = UUID().uuidString
    let postId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    let content: String
    let createdAt: Date
    var likes: Int = 0
}

// MARK: - Saved Item (Favorites)
enum SavedItemType: String, Codable {
    case post = "post"
    case event = "event"
    case city = "city"
    case user = "user"
}

struct SavedItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    let itemId: String
    let type: SavedItemType
    let savedAt: Date
    let title: String
    let subtitle: String?
    let imageURL: String?
}

// MARK: - Housing Listing
struct HousingListing: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let ownerName: String
    let ownerPhotoURL: String?
    let city: String
    let title: String
    let description: String
    let price: Double
    let roomsAvailable: Int
    let totalRooms: Int
    let amenities: [String]
    let photoURLs: [String]
    let address: String
    let availableFrom: Date
    let contactInfo: String
    let flatmateInterests: [String]
    let flatmateSchedule: String
    let createdAt: Date
    var isSaved: Bool = false
}

// MARK: - Announcement Post
struct AnnouncementPost: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let userName: String
    let city: String
    let title: String
    let description: String
    let category: AnnouncementCategory
    let price: Double?
    let imageURL: String?
    let contactInfo: String
    let createdAt: Date

    enum AnnouncementCategory: String, Codable, CaseIterable {
        case housing = "Piso"
        case bike = "Bici"
        case companion = "Compañero"
        case sale = "Venta"
        case service = "Servicio"
        case other = "Otro"

        var icon: String {
            switch self {
            case .housing: return "house.fill"
            case .bike: return "bicycle"
            case .companion: return "person.2.fill"
            case .sale: return "tag.fill"
            case .service: return "wrench.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
}
