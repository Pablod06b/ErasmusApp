// AppConfig.swift — constantes y configuración global de la app
import Foundation

/// Tamaños de paginación unificados para queries de Firestore.
/// Centralizar aquí evita inconsistencias y facilita ajustar costes.
enum PageSize {
    /// Tamaño por defecto para feeds infinitos (posts, eventos)
    static let `default`: Int = 20
    /// Mensajes en una conversación (cargamos más de golpe porque son ligeros)
    static let messages: Int = 50
    /// Sugerencias de usuarios (Explore, recomendados)
    static let users: Int = 20
    /// Posts del perfil de un usuario
    static let userPosts: Int = 30
}

/// IDs/keys/URLs constantes de la app.
enum AppConfig {
    static let firebaseProjectId = "erasmusconnect-2a003"
    static let supportEmail = "soporte@erasmusconnect.app"
    static let privacyEmail = "privacidad@erasmusconnect.app"
}
