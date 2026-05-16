// ExploreView.swift
import SwiftUI

// MARK: - Main Explore View
struct ExploreView: View {
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var searchText = ""
    @State private var selectedSection: ExploreSection = .cities
    @State private var selectedDestinationFilter: String = ""
    @State private var selectedInterestFilter: String = ""
    @State private var selectedEventCategory: String = "Todos"
    @State private var discoveredUsers: [UserProfile] = []
    @State private var isLoadingUsers = false
    @State private var showDestinationExplorer = false

    enum ExploreSection: String, CaseIterable {
        case cities = "Ciudades"
        case people = "Personas"
        case events = "Eventos"
        case housing = "Pisos"

        var icon: String {
            switch self {
            case .cities: return "globe.europe.africa"
            case .people: return "person.2.fill"
            case .events: return "sparkles"
            case .housing: return "house.fill"
            }
        }
    }

    let eventCategories = ["Todos", "Fiesta", "Cultural", "Deporte", "Gratis", "Hoy", "Popular"]
    let interests = ["Fiesta", "Viajes", "Tecnología", "Cultura", "Gastronomía", "Deporte", "Arte", "Música", "Fotografía", "Naturaleza"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Section Picker
                sectionPicker
                    .padding(.bottom, 8)

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedSection {
                        case .cities:
                            citiesSection
                        case .people:
                            peopleSection
                        case .events:
                            eventsSection
                        case .housing:
                            housingSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Explorar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showDestinationExplorer) {
                DestinationExplorerView()
            }
            .task {
                await loadUsers()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Buscar personas, eventos, ciudades...", text: $searchText)
                .font(.subheadline)
                .submitLabel(.search)
                .onSubmit { Task { await loadUsers() } }
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExploreSection.allCases, id: \.self) { section in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedSection = section }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.caption)
                            Text(section.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            selectedSection == section ?
                            AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                            AnyShapeStyle(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .foregroundColor(selectedSection == section ? .white : .primary)
                        .cornerRadius(20)
                        .shadow(color: selectedSection == section ? .blue.opacity(0.25) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Cities Section

    private var citiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Banner CTA for destination exploration
            Button(action: { showDestinationExplorer = true }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Explorar destinos Erasmus")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Descubre ciudades con estadísticas detalladas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())

            // Cities grid
            SectionHeaderExplore(title: "Ciudades populares", icon: "flame.fill", color: .orange)

            let filtered = searchText.isEmpty ? CityInfo.sampleCities :
                CityInfo.sampleCities.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText) ||
                    $0.country.localizedCaseInsensitiveContains(searchText)
                }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(filtered) { city in
                    NavigationLink(destination: CityDetailView(city: city)) {
                        CityCardView(city: city)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - People Section

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Filters
            VStack(alignment: .leading, spacing: 10) {
                Text("Filtrar personas")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "Todos", isSelected: selectedInterestFilter.isEmpty) {
                            selectedInterestFilter = ""
                            Task { await loadUsers() }
                        }
                        ForEach(interests, id: \.self) { interest in
                            FilterChip(label: interest, isSelected: selectedInterestFilter == interest) {
                                selectedInterestFilter = selectedInterestFilter == interest ? "" : interest
                                Task { await loadUsers() }
                            }
                        }
                    }
                }
            }

            if isLoadingUsers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if discoveredUsers.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No se encontraron personas",
                    message: "Prueba con otros filtros o destinos."
                )
            } else {
                SectionHeaderExplore(title: "\(discoveredUsers.count) erasmus encontrados", icon: "person.2.fill", color: .blue)

                LazyVStack(spacing: 12) {
                    ForEach(discoveredUsers) { user in
                        NavigationLink(destination: UserProfileView(userToDisplay: user.toExtendedUserProfile())) {
                            UserDiscoveryCard(user: user)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(eventCategories, id: \.self) { cat in
                        FilterChip(label: cat, isSelected: selectedEventCategory == cat) {
                            selectedEventCategory = cat
                        }
                    }
                }
            }

            SectionHeaderExplore(title: "Eventos destacados", icon: "sparkles", color: .purple)

            // Sample events for demo
            LazyVStack(spacing: 14) {
                ForEach(sampleEventsForExplore) { event in
                    EventCardView(evento: event)
                }
            }
        }
    }

    // MARK: - Housing Section

    private var housingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderExplore(title: "Pisos disponibles", icon: "house.fill", color: .green)

            Text("Encuentra piso para tu Erasmus")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVStack(spacing: 14) {
                ForEach(sampleHousingListings) { listing in
                    HousingCardView(listing: listing)
                }
            }
        }
    }

    // MARK: - Data Loaders

    private func loadUsers() async {
        isLoadingUsers = true
        let destination = selectedDestinationFilter.isEmpty ? nil : selectedDestinationFilter
        let interests = selectedInterestFilter.isEmpty ? [] : [selectedInterestFilter]

        let query = searchText.isEmpty ? "" : searchText
        let results = await socialManager.fetchUsers(destination: destination, interests: interests)

        discoveredUsers = query.isEmpty ? results : results.filter {
            $0.displayName.localizedCaseInsensitiveContains(query) ||
            $0.username.localizedCaseInsensitiveContains(query) ||
            $0.destination.localizedCaseInsensitiveContains(query) ||
            $0.university.localizedCaseInsensitiveContains(query)
        }
        isLoadingUsers = false
    }

    // MARK: - Sample Data

    var sampleEventsForExplore: [Evento] {
        let all = EventManager.shared.events
        if all.isEmpty {
            return [
                Evento(title: "Erasmus Welcome Party", location: "Club Fabric", date: "Viernes 20:00", imageName: "party", participants: 120, category: "Fiesta"),
                Evento(title: "Free Walking Tour", location: "Centro histórico", date: "Sábado 10:00", imageName: "Roma", participants: 25, category: "Cultural"),
                Evento(title: "Torneo Beer Pong Erasmus", location: "Hostel One", date: "Jueves 22:00", imageName: "beerpong", participants: 60, category: "Fiesta", price: 5.0)
            ]
        }
        return all
    }

    var sampleHousingListings: [HousingListing] {
        [
            HousingListing(
                userId: "u1", ownerName: "Carlos M.", ownerPhotoURL: nil,
                city: "Roma", title: "Habitación en piso compartido – Trastevere",
                description: "Piso de 4 hab cerca del Tiber. Cocina equipada, WiFi, ideal para Erasmus.",
                price: 550, roomsAvailable: 1, totalRooms: 4,
                amenities: ["WiFi", "Cocina", "Lavadora", "Balcón"],
                photoURLs: [], address: "Trastevere, Roma",
                availableFrom: Date(), contactInfo: "carlos@erasmus.com",
                flatmateInterests: ["Fiesta", "Cultura"], flatmateSchedule: "Flexible",
                createdAt: Date()
            ),
            HousingListing(
                userId: "u2", ownerName: "Ana G.", ownerPhotoURL: nil,
                city: "Salamanca", title: "Estudio en el centro histórico",
                description: "Estudio completo para una persona, amueblado. 2 min andando a la Universidad.",
                price: 420, roomsAvailable: 1, totalRooms: 1,
                amenities: ["WiFi", "Todo incluido", "A/C"],
                photoURLs: [], address: "Calle Mayor, Salamanca",
                availableFrom: Date(), contactInfo: "ana@uni.es",
                flatmateInterests: [], flatmateSchedule: "Normal",
                createdAt: Date()
            )
        ]
    }
}

// MARK: - City Card View

struct CityCardView: View {
    let city: CityInfo
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Group {
                if city.coverImageName != "default_image",
                   let _ = UIImage(named: city.coverImageName) {
                    Image(city.coverImageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: gradientColors(for: city.id),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 160)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            // City info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(city.countryFlag)
                        .font(.title2)
                    Spacer()
                    Button(action: {
                        Task { await favoritesManager.toggleCity(city) }
                    }) {
                        Image(systemName: favoritesManager.isCitySaved(city.name) ? "bookmark.fill" : "bookmark")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text(city.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(city.country)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))

                HStack(spacing: 4) {
                    Text(city.costOfLiving.icon)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(6)

                    Text("🎉 \(city.partyScene)/5")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(6)
                }
            }
            .padding(10)
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .clipped()
    }

    func gradientColors(for id: String) -> [Color] {
        let gradients: [[Color]] = [
            [.blue, .purple],
            [.orange, .red],
            [.green, .teal],
            [.pink, .purple],
            [.indigo, .blue],
            [.teal, .green],
            [.red, .orange],
            [.purple, .pink]
        ]
        let index = abs(id.hashValue) % gradients.count
        return gradients[index]
    }
}

// MARK: - City Detail View

struct CityDetailView: View {
    let city: CityInfo
    @StateObject private var favoritesManager = FavoritesManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if city.coverImageName != "default_image",
                           let _ = UIImage(named: city.coverImageName) {
                            Image(city.coverImageName)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: CityCardView(city: city).gradientColors(for: city.id),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .frame(height: 260)
                    .clipped()

                    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(city.countryFlag) \(city.name)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(city.country)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(20)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Description
                    Text(city.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .padding(.top, 8)

                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Estadísticas")
                            .font(.headline)
                            .fontWeight(.bold)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            CityStatCard(icon: "eurosign.circle.fill", label: "Coste de vida", value: city.costOfLiving.icon, color: .green)
                            CityStatCard(icon: "shield.fill", label: "Seguridad", value: "\(city.safetyScore)/5", color: .blue)
                            CityStatCard(icon: "music.note", label: "Vida nocturna", value: "\(city.partyScene)/5 🎉", color: .purple)
                            CityStatCard(icon: "building.columns.fill", label: "Cultura", value: "\(city.cultureScore)/5 🏛️", color: .orange)
                        }
                    }

                    // Info Row
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(icon: "thermometer.medium", label: "Clima", value: city.climateDescription)
                        InfoRow(icon: "textformat.abc", label: "Idioma", value: city.language)
                        InfoRow(icon: "house.fill", label: "Alquiler medio", value: city.averageRent)
                        InfoRow(icon: "person.3.fill", label: "Estudiantes", value: "\(city.studentPopulation.formatted()) estudiantes")
                    }

                    // Universities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Universidades")
                            .font(.headline)
                            .fontWeight(.bold)
                        ForEach(city.universities, id: \.self) { uni in
                            HStack(spacing: 8) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(uni)
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Attractions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Qué ver")
                            .font(.headline)
                            .fontWeight(.bold)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(city.topAttractions, id: \.self) { attraction in
                                    Text(attraction)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await favoritesManager.toggleCity(city) } }) {
                    Image(systemName: favoritesManager.isCitySaved(city.name) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(favoritesManager.isCitySaved(city.name) ? .blue : .primary)
                }
            }
        }
    }
}

// MARK: - User Discovery Card

struct UserDiscoveryCard: View {
    let user: UserProfile

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Group {
                if !user.photoURL.isEmpty, let url = URL(string: user.photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure: initialsAvatar(user.displayName)
                        default: Color.gray.opacity(0.2)
                        }
                    }
                } else {
                    initialsAvatar(user.displayName)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.1), radius: 4)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(user.displayName)
                        .font(.headline)
                    Spacer()
                    Text(user.destination.isEmpty ? "Sin destino" : user.destination)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !user.university.isEmpty {
                    Text(user.university)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if !user.interests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(user.interests.prefix(3), id: \.self) { interest in
                                Text(interest)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

@ViewBuilder
private func initialsAvatar(_ name: String) -> some View {
    let initials = name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    let seed = abs(name.hashValue) % 6
    let colors: [Color] = [.blue, .purple, .teal, .orange, .pink, .indigo]
    ZStack {
        colors[seed].opacity(0.8)
        Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
    }
}

// MARK: - Housing Card View

struct HousingCardView: View {
    let listing: HousingListing

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Placeholder image
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(listing.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Label("\(listing.price, format: .number.precision(.fractionLength(0)))€/mes", systemImage: "eurosign.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(listing.roomsAvailable) hab. libre")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Amenities
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(listing.amenities, id: \.self) { amenity in
                        Text(amenity)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
            }

            // Contact
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "person.fill").font(.caption2).foregroundColor(.gray))
                    Text(listing.ownerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {}) {
                    Text("Contactar")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Helper Subviews

struct SectionHeaderExplore: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.subheadline)
            Text(title).font(.headline).fontWeight(.bold)
            Spacer()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ?
                    AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                    AnyShapeStyle(Color(UIColor.secondarySystemGroupedBackground))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(isSelected ? 0 : 0.2), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CityStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}
