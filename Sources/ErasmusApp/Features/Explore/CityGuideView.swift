// CityGuideView.swift — guía rica de una ciudad con secciones editoriales + datos dinámicos
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Vista completa de una ciudad: guía editorial + eventos+gente+posts en vivo.
/// Si la ciudad es "Próximamente", muestra la guía light + CTA "Avísame".
struct CityGuideView: View {
    let city: CityInfo
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var cityRequest = CityRequestManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedDestination") private var selectedDestination: String = "Salamanca"

    // Datos dinámicos
    @State private var cityEvents: [Evento] = []
    @State private var cityPeople: [UserProfile] = []
    @State private var cityPosts: [ErasmusPost] = []
    @State private var isLoading = true

    private var isActive: Bool { AvailableCities.isActive(city.name) }
    private var guide: CityGuide? { CityGuide.guide(for: city.name) }
    private var isMyDestination: Bool { selectedDestination == city.name }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                VStack(alignment: .leading, spacing: 28) {
                    if let guide = guide {
                        guideHeader(guide)
                        if !isActive { comingSoonBanner }
                        if isActive { setDestinationButton }
                        thisWeekSection(guide)
                        sectionsBlock(guide)
                    } else {
                        // Fallback: ciudad sin guía curada — info básica del modelo
                        basicCityInfo
                    }

                    if isActive {
                        Divider()
                        dynamicEventsSection
                        dynamicPeopleSection
                        dynamicPostsSection
                    }

                    statsAndDetailsSection
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await favoritesManager.toggleCity(city) } }) {
                    Image(systemName: favoritesManager.isCitySaved(city.name) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(favoritesManager.isCitySaved(city.name) ? .blue : .primary)
                }
                .accessibilityLabel(favoritesManager.isCitySaved(city.name) ? "Quitar ciudad de guardados" : "Guardar ciudad")
            }
        }
        .task {
            await loadDynamicContent()
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if city.coverImageName != "default_image",
                   UIImage(named: city.coverImageName) != nil {
                    Image(city.coverImageName)
                        .resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: gradientForCity(),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 280)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(city.countryFlag).font(.title2)
                    if !isActive {
                        Text("PRÓXIMAMENTE")
                            .font(.caption2).fontWeight(.bold)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } else if isMyDestination {
                        Text("TU DESTINO")
                            .font(.caption2).fontWeight(.bold)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                Text(city.name)
                    .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                Text(city.country)
                    .font(.headline).foregroundColor(.white.opacity(0.92))
            }
            .padding(20)
        }
    }

    // MARK: - Guide header (tagline + highlights)
    private func guideHeader(_ guide: CityGuide) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(guide.tagline)
                .font(.title3).fontWeight(.medium)
                .foregroundColor(.primary)
                .lineSpacing(2)

            FlowLayout(spacing: 8) {
                ForEach(guide.highlights, id: \.self) { hl in
                    Text(hl)
                        .font(.caption).fontWeight(.medium)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.blue.opacity(0.10))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Coming soon banner
    private var comingSoonBanner: some View {
        let subscribed = cityRequest.hasRequested(city.name)
        let count = cityRequest.counts[city.name] ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "hourglass")
                    .font(.title3).foregroundColor(.orange)
                Text("Aún no estamos en \(city.name)")
                    .font(.headline)
            }
            Text("La app aún no está activa aquí. Estamos esperando alcanzar masa crítica de estudiantes para lanzar.")
                .font(.subheadline).foregroundColor(.secondary)
            if count > 0 {
                Text("👥 \(count) \(count == 1 ? "persona ya está" : "personas ya están") esperando")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            Button(action: { Task { await toggleSubscription() } }) {
                HStack {
                    Image(systemName: subscribed ? "checkmark.circle.fill" : "bell.badge.fill")
                    Text(subscribed ? "Te avisaremos cuando llegue" : "Avísame cuando llegue a \(city.name)")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: subscribed ? [.green, .teal] : [.blue, .purple],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    // MARK: - Set destination button
    @ViewBuilder
    private var setDestinationButton: some View {
        if !isMyDestination {
            Button(action: setAsDestination) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Establecer \(city.name) como mi destino")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
        }
    }

    // MARK: - This week
    private func thisWeekSection(_ guide: CityGuide) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").foregroundColor(.yellow)
                Text("Imprescindibles esta semana")
                    .font(.headline).fontWeight(.bold)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(guide.mustDoThisWeek.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.caption2).fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.purple)
                            .clipShape(Circle())
                        Text(item)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(14)
    }

    // MARK: - Sections (Transporte, Vivienda, Salir, etc.)
    private func sectionsBlock(_ guide: CityGuide) -> some View {
        VStack(spacing: 12) {
            ForEach(guide.sections) { section in
                GuideSectionCard(section: section)
            }
        }
    }

    // MARK: - Dynamic events
    @ViewBuilder
    private var dynamicEventsSection: some View {
        if !cityEvents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Eventos en \(city.name)", icon: "sparkles", color: .purple)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cityEvents.prefix(8)) { evt in
                            NavigationLink(destination: EventDetailView(evento: evt)
                                .environmentObject(authManager)) {
                                miniEventCard(evt)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private func miniEventCard(_ evt: Evento) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let url = evt.imageURL, let u = URL(string: url) {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    }
                } else {
                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(width: 180, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(evt.title).font(.subheadline).fontWeight(.semibold).lineLimit(2)
                Text(evt.date).font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(width: 180)
    }

    // MARK: - Dynamic people
    @ViewBuilder
    private var dynamicPeopleSection: some View {
        if !cityPeople.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Gente en \(city.name)", icon: "person.2.fill", color: .blue)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cityPeople.prefix(10)) { p in
                            NavigationLink(destination: UserProfileView(userToDisplay: p.toExtendedUserProfile())
                                .environmentObject(authManager)) {
                                miniPersonCard(p)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private func miniPersonCard(_ p: UserProfile) -> some View {
        VStack(spacing: 8) {
            UserAvatarView(
                photoURL: p.photoURL.isEmpty ? nil : p.photoURL,
                name: p.displayName,
                size: 64
            )
            Text(p.displayName)
                .font(.caption).fontWeight(.semibold)
                .lineLimit(1)
            if !p.university.isEmpty {
                Text(p.university)
                    .font(.caption2).foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 100)
    }

    // MARK: - Dynamic posts
    @ViewBuilder
    private var dynamicPostsSection: some View {
        if !cityPosts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Lo último de \(city.name)", icon: "newspaper.fill", color: .orange)
                VStack(spacing: 8) {
                    ForEach(cityPosts.prefix(5)) { post in
                        miniPostRow(post)
                    }
                }
            }
        }
    }

    private func miniPostRow(_ post: ErasmusPost) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconForPostType(post.type))
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(colorForPostType(post.type))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(post.title).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                Text(post.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func iconForPostType(_ t: PostType) -> String {
        switch t {
        case .event: return "calendar.badge.plus"
        case .recommendation: return "star.fill"
        case .announcement: return "megaphone.fill"
        case .personalPlan: return "person.2.fill"
        case .openMessage: return "bubble.right.fill"
        case .housing: return "house.fill"
        }
    }
    private func colorForPostType(_ t: PostType) -> Color {
        switch t {
        case .event: return .purple
        case .recommendation: return .orange
        case .announcement: return .blue
        case .personalPlan: return .pink
        case .openMessage: return .cyan
        case .housing: return .brown
        }
    }

    // MARK: - Stats + Details bloque (lo que ya había, recolocado)
    private var statsAndDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Datos clave", icon: "chart.bar.fill", color: .blue)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                CityStatCard(icon: "eurosign.circle.fill", label: "Coste de vida", value: city.costOfLiving.icon, color: .green)
                CityStatCard(icon: "shield.fill", label: "Seguridad", value: "\(city.safetyScore)/5", color: .blue)
                CityStatCard(icon: "music.note", label: "Vida nocturna", value: "\(city.partyScene)/5 🎉", color: .purple)
                CityStatCard(icon: "building.columns.fill", label: "Cultura", value: "\(city.cultureScore)/5 🏛️", color: .orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "thermometer.medium", label: "Clima", value: city.climateDescription)
                InfoRow(icon: "textformat.abc", label: "Idioma", value: city.language)
                InfoRow(icon: "house.fill", label: "Alquiler medio", value: city.averageRent)
                InfoRow(icon: "person.3.fill", label: "Estudiantes", value: "\(city.studentPopulation.formatted())")
            }

            if !city.universities.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Universidades").font(.subheadline).fontWeight(.semibold).padding(.top, 4)
                    ForEach(city.universities, id: \.self) { uni in
                        HStack(spacing: 6) {
                            Image(systemName: "graduationcap.fill").font(.caption2).foregroundColor(.blue)
                            Text(uni).font(.caption)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var basicCityInfo: some View {
        Text(city.description)
            .font(.body).foregroundColor(.secondary)
            .lineSpacing(4)
        if !isActive { comingSoonBanner }
    }

    // MARK: - Helpers
    private func sectionTitle(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).font(.headline).fontWeight(.bold)
        }
    }

    private func gradientForCity() -> [Color] {
        let palettes: [[Color]] = [
            [.purple, .pink], [.blue, .cyan], [.orange, .red],
            [.green, .teal], [.indigo, .purple], [.pink, .orange]
        ]
        let idx = ((city.id.hashValue % palettes.count) + palettes.count) % palettes.count
        return palettes[idx]
    }

    // MARK: - Actions
    private func setAsDestination() {
        selectedDestination = city.name
        AppErrorManager.shared.success("\(city.name) ahora es tu destino", icon: "location.fill")
        AppAnalytics.logDestinationChange(destination: city.name)
        // Si el usuario tiene perfil, persistimos también en Firestore
        if let uid = authManager.currentUser?.id {
            Task {
                try? await UserProfileManager.shared.updateUserProfile(userId: uid, updates: ["destination": city.name])
            }
        }
    }

    private func toggleSubscription() async {
        if cityRequest.hasRequested(city.name) {
            _ = await cityRequest.unsubscribe(fromCity: city.name)
        } else {
            _ = await cityRequest.subscribe(toCity: city.name)
        }
    }

    // MARK: - Data loading
    private func loadDynamicContent() async {
        guard isActive else { isLoading = false; return }
        isLoading = true
        defer { isLoading = false }

        let db = Firestore.firestore()
        let cityName = city.name

        // Eventos
        if let snap = try? await db.collection("events")
            .whereField("city", isEqualTo: cityName)
            .limit(to: 12)
            .getDocuments() {
            cityEvents = snap.documents.compactMap { try? $0.data(as: Evento.self) }
        }

        // Gente
        if let snap = try? await db.collection("users")
            .whereField("destination", isEqualTo: cityName)
            .limit(to: 15)
            .getDocuments() {
            let currentId = Auth.auth().currentUser?.uid ?? ""
            cityPeople = snap.documents
                .compactMap { try? $0.data(as: UserProfile.self) }
                .filter { $0.id != currentId }
        }

        // Posts recientes
        if let snap = try? await db.collection("posts")
            .whereField("destination", isEqualTo: cityName)
            .limit(to: 8)
            .getDocuments() {
            cityPosts = snap.documents.compactMap { try? $0.data(as: ErasmusPost.self) }
        }

        // Carga conteo de demanda para el banner coming-soon (no bloqueante)
        await cityRequest.loadUserSubscriptions()
    }
}

// MARK: - GuideSectionCard
private struct GuideSectionCard: View {
    let section: GuideSection
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { withAnimation { expanded.toggle() } }) {
                HStack(spacing: 10) {
                    Image(systemName: section.icon)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(section.color)
                        .clipShape(Circle())
                    Text(section.title)
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(section.tips) { tip in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tip.title)
                                .font(.subheadline).fontWeight(.semibold)
                            Text(tip.detail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }
}
