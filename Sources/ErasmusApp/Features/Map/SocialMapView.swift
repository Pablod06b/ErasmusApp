// SocialMapView.swift
import SwiftUI
import MapKit

// MARK: - Map Annotation Types

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: MapItemType
    let title: String
    let subtitle: String
    let color: Color
    let icon: String

    enum MapItemType {
        case event, recommendation, person, group, housing
    }
}

// MARK: - Social Map View

struct SocialMapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var eventManager = EventManager.shared
    @StateObject private var userManager = UserManager.shared

    /// Ciudad activa (compartida con HomeView). Por defecto Salamanca.
    @AppStorage("selectedDestination") private var selectedCity: String = "Salamanca"

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635), // Salamanca
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var selectedFilter: MapFilter = .all
    @State private var selectedAnnotation: MapAnnotationItem? = nil
    @State private var showAnnotationSheet = false

    /// Annotations cargadas desde Firestore + geocoding
    @State private var loadedAnnotations: [MapAnnotationItem] = []
    @State private var isGeocoding = false

    enum MapFilter: String, CaseIterable {
        case all = "Todo"
        case events = "Eventos"
        case recommendations = "Posts"
        case people = "Personas"

        var icon: String {
            switch self {
            case .all: return "map.fill"
            case .events: return "sparkles"
            case .recommendations: return "newspaper.fill"
            case .people: return "person.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .blue
            case .events: return .purple
            case .recommendations: return .orange
            case .people: return .green
            }
        }
    }

    /// Filtrado de annotations cargadas
    var annotations: [MapAnnotationItem] {
        switch selectedFilter {
        case .all: return loadedAnnotations
        case .events: return loadedAnnotations.filter { $0.type == .event }
        case .recommendations: return loadedAnnotations.filter { $0.type == .recommendation }
        case .people: return loadedAnnotations.filter { $0.type == .person }
        }
    }

    // El catálogo anterior con annotations hardcoded está obsoleto.
    private var legacyHardcodedAnnotations: [MapAnnotationItem] {
        let base: [MapAnnotationItem] = [
            MapAnnotationItem(
                id: "ev1",
                coordinate: CLLocationCoordinate2D(latitude: 40.4200, longitude: -3.7050),
                type: .event,
                title: "Erasmus Welcome Party",
                subtitle: "Hoy 22:00 • 85 asistentes",
                color: .purple,
                icon: "music.note"
            ),
            MapAnnotationItem(
                id: "ev2",
                coordinate: CLLocationCoordinate2D(latitude: 40.4150, longitude: -3.6980),
                type: .event,
                title: "Free Tour Erasmus",
                subtitle: "Mañana 10:00 • 20 asistentes",
                color: .orange,
                icon: "figure.walk"
            ),
            MapAnnotationItem(
                id: "rec1",
                coordinate: CLLocationCoordinate2D(latitude: 40.4180, longitude: -3.7100),
                type: .recommendation,
                title: "Café Central",
                subtitle: "⭐ 4.8 · Cafetería",
                color: .yellow,
                icon: "cup.and.saucer.fill"
            ),
            MapAnnotationItem(
                id: "rec2",
                coordinate: CLLocationCoordinate2D(latitude: 40.4130, longitude: -3.7010),
                type: .recommendation,
                title: "El Lateral",
                subtitle: "⭐ 4.6 · Restaurante",
                color: .orange,
                icon: "fork.knife"
            ),
            MapAnnotationItem(
                id: "house1",
                coordinate: CLLocationCoordinate2D(latitude: 40.4210, longitude: -3.6950),
                type: .housing,
                title: "Habitación en piso Erasmus",
                subtitle: "500€/mes · 1 libre",
                color: .teal,
                icon: "house.fill"
            ),
            MapAnnotationItem(
                id: "person1",
                coordinate: CLLocationCoordinate2D(latitude: 40.4165, longitude: -3.7030),
                type: .person,
                title: "María G.",
                subtitle: "📍 Erasmus Madrid",
                color: .green,
                icon: "person.fill"
            )
        ]

        return base
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MAP
                Map(position: $cameraPosition) {
                    // User Location
                    UserAnnotation()

                    // Dynamic Annotations
                    ForEach(annotations) { item in
                        Annotation(item.title, coordinate: item.coordinate) {
                            MapPinView(item: item)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedAnnotation = item
                                        showAnnotationSheet = true
                                    }
                                }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea()

                // Overlay controls
                VStack(spacing: 0) {
                    // Top Filter Bar
                    filterBar
                        .padding(.top, 60)
                        .padding(.horizontal, 16)

                    Spacer()

                    // Stats bar at bottom
                    statsBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAnnotationSheet) {
                if let annotation = selectedAnnotation {
                    MapAnnotationSheet(item: annotation)
                        .presentationDetents([.height(260)])
                        .presentationDragIndicator(.visible)
                }
            }
            .onAppear {
                locationManager.requestAuthorization()
                locationManager.requestLocation()
                centerOnSelectedCity()
                Task { await reloadAnnotations() }
            }
            .onChange(of: selectedCity) { _ in
                centerOnSelectedCity()
                Task { await reloadAnnotations() }
            }
            .onChange(of: postManager.posts.count) { _ in
                Task { await reloadAnnotations() }
            }
            .onChange(of: eventManager.events.count) { _ in
                Task { await reloadAnnotations() }
            }
            .overlay(alignment: .topTrailing) {
                if isGeocoding {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Cargando...").font(.caption)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 60).padding(.trailing, 16)
                }
            }
        }
    }

    // MARK: - Centrado en ciudad

    private func centerOnSelectedCity() {
        guard let coord = GeocodeCache.shared.coordinatesForActiveCity(selectedCity) else { return }
        withAnimation(.easeInOut) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            ))
        }
    }

    // MARK: - Carga real de annotations

    /// Construye annotations desde:
    /// - Eventos de la ciudad actual (geocodificados por location)
    /// - Posts con location de la ciudad actual (geocodificados)
    /// - Personas recomendadas (centradas en la ciudad — sin ubicación exacta)
    private func reloadAnnotations() async {
        await MainActor.run { isGeocoding = true }
        defer { Task { @MainActor in isGeocoding = false } }

        var result: [MapAnnotationItem] = []
        let cityCenter = GeocodeCache.shared.coordinatesForActiveCity(selectedCity)
            ?? CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038)

        // 1) Eventos
        let cityEvents = eventManager.events.filter { evt in
            (evt.city == selectedCity) || evt.location.localizedCaseInsensitiveContains(selectedCity)
        }
        for evt in cityEvents.prefix(40) {
            let query = "\(evt.location), \(evt.city ?? selectedCity)"
            if let coord = await GeocodeCache.shared.coordinates(for: query) {
                result.append(MapAnnotationItem(
                    id: "event_\(evt.id)",
                    coordinate: coord,
                    type: .event,
                    title: evt.title,
                    subtitle: "\(evt.date) · \(evt.category)",
                    color: .purple,
                    icon: "sparkles"
                ))
            }
        }

        // 2) Posts con location
        let cityPosts = postManager.posts.filter {
            $0.destination == selectedCity && ($0.location ?? "").isEmpty == false
        }
        for post in cityPosts.prefix(40) {
            guard let loc = post.location, !loc.isEmpty else { continue }
            let query = "\(loc), \(selectedCity)"
            if let coord = await GeocodeCache.shared.coordinates(for: query) {
                result.append(MapAnnotationItem(
                    id: "post_\(post.id)",
                    coordinate: coord,
                    type: .recommendation,
                    title: post.title,
                    subtitle: post.type.rawValue,
                    color: .orange,
                    icon: "newspaper.fill"
                ))
            }
        }

        // 3) Personas — distribuidas alrededor del centro de la ciudad
        let cityPeople = userManager.recommendedProfiles.filter { $0.destination == selectedCity }
        for (i, person) in cityPeople.prefix(20).enumerated() {
            // Distribución circular alrededor del centro (radio ~1km)
            let angle = Double(i) / Double(max(cityPeople.count, 1)) * 2 * .pi
            let radius = 0.008 // ~900m
            let coord = CLLocationCoordinate2D(
                latitude: cityCenter.latitude + cos(angle) * radius,
                longitude: cityCenter.longitude + sin(angle) * radius
            )
            result.append(MapAnnotationItem(
                id: "person_\(person.id)",
                coordinate: coord,
                type: .person,
                title: person.displayName,
                subtitle: person.university.isEmpty ? "Erasmus en \(selectedCity)" : person.university,
                color: .green,
                icon: "person.fill"
            ))
        }

        await MainActor.run {
            loadedAnnotations = result
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = filter }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon).font(.caption)
                            Text(filter.rawValue).font(.subheadline).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedFilter == filter ?
                            AnyShapeStyle(filter.color) :
                            AnyShapeStyle(.ultraThinMaterial)
                        )
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 12) {
            MapStatChip(count: annotations.filter { $0.type == .event }.count, label: "eventos", icon: "sparkles", color: .purple)
            MapStatChip(count: annotations.filter { $0.type == .recommendation }.count, label: "lugares", icon: "star.fill", color: .orange)
            MapStatChip(count: annotations.filter { $0.type == .person }.count, label: "erasmus", icon: "person.fill", color: .green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Map Pin View

struct MapPinView: View {
    let item: MapAnnotationItem
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            Circle()
                .fill(item.color)
                .frame(width: 40, height: 40)
                .shadow(color: item.color.opacity(0.5), radius: 6, x: 0, y: 3)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.subheadline)
                        .foregroundColor(.white)
                )
        }
        .scaleEffect(1.0)
        .animation(.spring(), value: isExpanded)
    }
}

// MARK: - Map Stat Chip

struct MapStatChip: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundColor(color)
            Text("\(count) \(label)").font(.caption).fontWeight(.semibold)
        }
    }
}

// MARK: - Map Annotation Sheet

struct MapAnnotationSheet: View {
    let item: MapAnnotationItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(item.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        typeTag
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Action Buttons
            HStack(spacing: 12) {
                actionButton(icon: "map.fill", label: "Ver ruta", color: .blue)
                actionButton(icon: "square.and.arrow.up", label: "Compartir", color: .green)

                switch item.type {
                case .event:
                    actionButton(icon: "person.badge.plus", label: "Apuntarse", color: .purple)
                case .recommendation:
                    actionButton(icon: "star.fill", label: "Guardar", color: .orange)
                case .person:
                    actionButton(icon: "message.fill", label: "Mensaje", color: .teal)
                case .housing:
                    actionButton(icon: "phone.fill", label: "Contactar", color: .teal)
                case .group:
                    actionButton(icon: "person.3.fill", label: "Ver grupo", color: .indigo)
                }
            }
        }
        .padding(20)
    }

    private var typeTag: some View {
        Text(typeLabelText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(item.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(item.color.opacity(0.12))
            .cornerRadius(8)
    }

    private var typeLabelText: String {
        switch item.type {
        case .event: return "Evento"
        case .recommendation: return "Recomendación"
        case .person: return "Erasmus"
        case .group: return "Grupo"
        case .housing: return "Piso"
        }
    }

    private func actionButton(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .cornerRadius(14)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
