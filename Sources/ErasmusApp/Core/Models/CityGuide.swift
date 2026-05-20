// CityGuide.swift — contenido editorial curado para cada ciudad activa
import Foundation
import SwiftUI

/// Una sección de la guía con un icono, título y lista de tips.
struct GuideSection: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let tips: [GuideTip]
}

struct GuideTip: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

/// Guía editorial completa de una ciudad para estudiantes Erasmus.
struct CityGuide {
    let cityName: String
    let tagline: String                  // Frase corta que define la ciudad
    let highlights: [String]             // 3-4 highlights en una línea
    let sections: [GuideSection]
    let mustDoThisWeek: [String]         // Cosas que no te puedes perder
}

// MARK: - Catálogo curado

extension CityGuide {
    static func guide(for cityName: String) -> CityGuide? {
        switch cityName {
        case "Salamanca": return salamanca
        case "Madrid":    return madrid
        default:          return nil
        }
    }

    // MARK: - Salamanca
    static let salamanca = CityGuide(
        cityName: "Salamanca",
        tagline: "La ciudad universitaria por excelencia. Pequeña, viva, barata.",
        highlights: [
            "🎓 30.000 estudiantes",
            "💰 Coste de vida bajo",
            "🍻 Vida nocturna 24/7",
            "🏛️ Patrimonio UNESCO"
        ],
        sections: [
            GuideSection(
                icon: "tram.fill", color: .blue, title: "Transporte",
                tips: [
                    GuideTip(title: "Andando", detail: "Todo está a 15 min andando. No vas a necesitar transporte para el día a día."),
                    GuideTip(title: "Bus urbano", detail: "Bono mensual joven ~30€. Líneas útiles: 1, 4, 11 (campus Unamuno)."),
                    GuideTip(title: "BlaBlaCar / Bus", detail: "Para escapadas: Madrid 2h30 (Avanza, ~15€), Lisboa 6h, Porto 5h, Barcelona vía Madrid."),
                    GuideTip(title: "Bici", detail: "Llano + compacta. Trae candado bueno; los robos pasan en el centro.")
                ]
            ),
            GuideSection(
                icon: "house.fill", color: .green, title: "Dónde vivir",
                tips: [
                    GuideTip(title: "Centro histórico", detail: "Plaza Mayor, San Justo, San Pablo. Caro pero todo a 5 min. Habitación 280-380€."),
                    GuideTip(title: "Garrido", detail: "Barrio universitario por excelencia. Muchos Erasmus, ambiente joven. 230-300€."),
                    GuideTip(title: "Vidal / Pizarrales", detail: "Más barato (200-260€) pero 15-20 min andando del centro."),
                    GuideTip(title: "Plataformas", detail: "Idealista, Spotahome, Erasmusu, grupos de Facebook 'Pisos Salamanca'. Cuidado con estafas fuera de plataforma.")
                ]
            ),
            GuideSection(
                icon: "music.note.house.fill", color: .purple, title: "Salir",
                tips: [
                    GuideTip(title: "Gran Vía y Van Dyck", detail: "Calles principales de bares. Empieza por aquí cualquier noche."),
                    GuideTip(title: "Discotecas", detail: "Camelot (medieval, locura), Potemkin, Cum Laude. Apertura ~1:30, cierre 6-7h."),
                    GuideTip(title: "Erasmus parties", detail: "Cada jueves/viernes hay fiestas Erasmus organizadas (ESN, Eralia). Síguelos en Insta."),
                    GuideTip(title: "Después", detail: "Chocolate con churros a las 7 AM en Valor o la Avda. Mirat. Tradición.")
                ]
            ),
            GuideSection(
                icon: "fork.knife", color: .orange, title: "Comida y bares",
                tips: [
                    GuideTip(title: "Tapas baratas", detail: "Pincho + caña 2-3€. Casa Paca, Mesón Cervantes, El Patio Chico, La Tapería."),
                    GuideTip(title: "Menú del día", detail: "10-13€ en cualquier sitio del centro. Ideal entre semana."),
                    GuideTip(title: "Hornazo", detail: "Plato típico (empanada de chorizo). En Pascua se come en el campo (Lunes de Aguas)."),
                    GuideTip(title: "Mercados", detail: "Mercado Central (Pza. del Mercado), super para fruta/verduras frescas y baratas.")
                ]
            ),
            GuideSection(
                icon: "doc.text.fill", color: .red, title: "Papeleo Erasmus",
                tips: [
                    GuideTip(title: "TIE (extranjeros no UE)", detail: "Pedir cita en sede.administracionespublicas.gob.es nada más llegar. Cita en Avda. de Portugal."),
                    GuideTip(title: "Empadronamiento", detail: "Ayuntamiento, Plaza Mayor. Gratis. Pídelo aunque vivas en habitación compartida."),
                    GuideTip(title: "Cuenta bancaria", detail: "Si te quedas >3 meses: BBVA y Santander tienen ofertas para Erasmus. Revolut/N26 funcionan para todo, pero necesitas IBAN ES para algunas becas."),
                    GuideTip(title: "Tarjeta universitaria", detail: "USAL te la da en tu primera semana. Te abre el campus 24h y da descuentos en transporte y cultura.")
                ]
            ),
            GuideSection(
                icon: "sparkles", color: .pink, title: "No te pierdas",
                tips: [
                    GuideTip(title: "La rana de la fachada", detail: "Tradición: encuéntrala en la fachada de la Universidad sin ayuda. Dicen que da buena nota."),
                    GuideTip(title: "Atardecer en La Clerecía", detail: "Subir a las torres a la hora dorada. 4€ con carné universitario."),
                    GuideTip(title: "Domingo en El Tormes", detail: "Camina por el Puente Romano hasta el Huerto de Calixto y Melibea."),
                    GuideTip(title: "Lunes de Aguas", detail: "Fiesta universitaria mítica en abril. Picnic en el río con hornazo. No te lo pierdas.")
                ]
            )
        ],
        mustDoThisWeek: [
            "Suscríbete a ESN Salamanca en Instagram",
            "Saca el carné universitario en tu facultad",
            "Encuentra la rana de la Universidad",
            "Cena tapas en la Plaza Mayor al menos una vez"
        ]
    )

    // MARK: - Madrid
    static let madrid = CityGuide(
        cityName: "Madrid",
        tagline: "Capital sin parar. Cultura, fiesta y oportunidades a partes iguales.",
        highlights: [
            "🎓 320.000 estudiantes",
            "🌃 Vida nocturna mítica",
            "🏛️ Museos top mundial",
            "✈️ Aeropuerto a todo el mundo"
        ],
        sections: [
            GuideSection(
                icon: "tram.fill", color: .blue, title: "Transporte",
                tips: [
                    GuideTip(title: "Abono joven", detail: "Si tienes <26 años: 20€/mes para Metro+Bus+Cercanías en TODA la Comunidad. Imprescindible."),
                    GuideTip(title: "Metro", detail: "12 líneas, abre 6h-1:30. App: Metro Madrid Oficial o Google Maps."),
                    GuideTip(title: "BiciMAD", detail: "Bicis eléctricas públicas. Bono anual ~25€ con abono joven. Hay carriles bici decentes."),
                    GuideTip(title: "Aeropuerto", detail: "Línea 8 Metro hasta Nuevos Ministerios (~5€ con suplemento, 30 min). Evita taxi/Uber si vas con presupuesto.")
                ]
            ),
            GuideSection(
                icon: "house.fill", color: .green, title: "Dónde vivir",
                tips: [
                    GuideTip(title: "Malasaña / Chueca", detail: "Centro, alternativo, gay-friendly, caro. Hab 500-650€."),
                    GuideTip(title: "Moncloa / Argüelles", detail: "Cerca de la Complutense, ambiente universitario. Hab 450-600€."),
                    GuideTip(title: "Lavapiés / Tirso de Molina", detail: "Multicultural, barato (400-500€), mucho ambiente Erasmus."),
                    GuideTip(title: "Vallecas / Carabanchel", detail: "Si buscas barato (300-400€) y no te importa metro de 30 min al centro."),
                    GuideTip(title: "Plataformas", detail: "Idealista, Badi, Spotahome, Erasmusu. Visita SIEMPRE en persona antes de pagar.")
                ]
            ),
            GuideSection(
                icon: "music.note.house.fill", color: .purple, title: "Salir",
                tips: [
                    GuideTip(title: "Malasaña", detail: "Empieza con cañas en Plaza 2 de Mayo. Bares pequeños, mucho ambiente."),
                    GuideTip(title: "Discotecas grandes", detail: "Kapital (7 plantas, mítica), Teatro Barceló, Joy Eslava. Entradas 10-20€ con consumición."),
                    GuideTip(title: "Sala Cocó / Mondo", detail: "Para techno/electrónica. Domingos Industrial Copera."),
                    GuideTip(title: "Erasmus Madrid", detail: "ESN Madrid organiza fiestas casi diarias. Casi siempre con descuento si tienes ESNcard.")
                ]
            ),
            GuideSection(
                icon: "fork.knife", color: .orange, title: "Comida y bares",
                tips: [
                    GuideTip(title: "Bocadillo de calamares", detail: "Plaza Mayor. Sí, es turístico, pero hay que hacerlo una vez."),
                    GuideTip(title: "Mercados", detail: "San Miguel (turístico pero precioso), Antón Martín (auténtico), San Fernando (Lavapiés, barato)."),
                    GuideTip(title: "Cocido madrileño", detail: "Plato típico, contundente. La Bola, Lhardy, Malacatín. Mínimo 18€ pero merece la pena."),
                    GuideTip(title: "Tapeo barato", detail: "La Latina los domingos. Bares en C/ Cava Baja: tapa + caña 2-3€.")
                ]
            ),
            GuideSection(
                icon: "doc.text.fill", color: .red, title: "Papeleo Erasmus",
                tips: [
                    GuideTip(title: "TIE (extranjeros no UE)", detail: "Cita previa en sede.administracionespublicas.gob.es. Hay overbooking constante: revisa cada mañana."),
                    GuideTip(title: "Empadronamiento", detail: "Hazlo en la junta de distrito (no en el ayuntamiento central). Es gratis y rápido si tienes contrato de alquiler."),
                    GuideTip(title: "Cuenta bancaria", detail: "BBVA Online, Openbank, Santander. Revolut funciona para casi todo. Becas españolas suelen pedir IBAN ES."),
                    GuideTip(title: "Tarjeta sanitaria", detail: "Con TSE de tu país basta para urgencias. Para médico de cabecera pide tarjeta SERMAS en tu centro de salud asignado por empadronamiento.")
                ]
            ),
            GuideSection(
                icon: "sparkles", color: .pink, title: "No te pierdas",
                tips: [
                    GuideTip(title: "Museos gratis", detail: "Prado (lun-sáb 18-20h, dom 17-19h gratis), Reina Sofía (lun y sáb 19-21h, dom 12:30-14:30 gratis), Thyssen (lunes gratis 12-16h)."),
                    GuideTip(title: "El Retiro", detail: "Domingo por la mañana es ESCENA: gente leyendo, batucadas, vermuts, palacio de cristal."),
                    GuideTip(title: "El Rastro", detail: "Mercadillo dominical en La Latina. Después: cañas y tapas obligatorias."),
                    GuideTip(title: "Escapadas", detail: "Toledo (30 min en AVE), Segovia (30 min), El Escorial (1h). Con abono joven, casi gratis.")
                ]
            )
        ],
        mustDoThisWeek: [
            "Sacar el Abono Joven (20€/mes ahorra 100€/mes en transporte)",
            "Apuntarse a ESN Madrid",
            "Empadronarse en la junta de distrito",
            "Domingo en El Retiro + tapas en La Latina"
        ]
    )
}
