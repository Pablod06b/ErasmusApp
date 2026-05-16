// HomeView.swift
import SwiftUI

// MARK: - Notification Components (Missing in user's report)
// We define them here or stub them if they should exist.
// Based on previous reads, NotificationToastView was used but not seen defined.
// I will add a basic definition here to fix the "Cannot find" error if it's truly missing.
// MARK: - Notification Toast View
struct NotificationToastView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.rawValue)
                .font(.title2)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(notification.message)
                    .font(.caption)
                    .lineLimit(2)
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.85))
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
}

// Removed NotificationsView as it is now in a standalone file.


struct HomeView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    // Inject managers
    @StateObject private var postManager = PostManager.shared
    @StateObject private var eventManager = EventManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var router = NavigationRouter.shared

    @State private var selectedFilter: String = "Todos"
    @State private var showCreatePostSheet = false
    @State private var showNotificationsSheet = false
    @State private var selectedTab: Tab = .home
    @State private var selectedDestination = "Salamanca"
    @State private var pendingChatId: String? = nil

    let filters = ["Todos", "Discotecas", "Eventos", "Conocer", "Casas", "Otros", "Recomendación", "Anuncio", "Plan personal", "Mensaje abierto"]
    let destinations = ["Salamanca", "Madrid", "Barcelona", "Valencia", "Roma", "París", "Berlín", "Lisboa", "Milán", "Ámsterdam"]
    
    var postsFiltrados: [ErasmusPost] {
        // Redundant filter if PostManager handles it, but keeps UI consistent during transitions
        let destinationFiltered = postManager.posts.filter { $0.destination == selectedDestination }
        
        if selectedFilter == "Todos" {
            // Removed .shuffled() to support stable pagination
            return destinationFiltered
        }
        
        let filterToType: [String: PostType] = [
            "Discotecas": .event,
            "Eventos": .event,
            "Conocer": .openMessage,
            "Casas": .announcement,
            "Otros": .event,
            "Recomendación": .recommendation,
            "Anuncio": .announcement,
            "Plan personal": .personalPlan,
            "Mensaje abierto": .openMessage
        ]
        
        if let postType = filterToType[selectedFilter] {
            return destinationFiltered.filter { $0.type == postType }
        }
        
        return destinationFiltered
    }
    
    var personasFiltradas: [UserProfile] {
        return userManager.recommendedProfiles
    }

    var eventosFiltrados: [Evento] {
        if selectedFilter == "Todos" {
            return eventManager.events
        }
        return eventManager.events.filter { $0.category == selectedFilter }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                ModernHeaderView(
                    selectedDestination: $selectedDestination,
                    showCreatePostSheet: $showCreatePostSheet,
                    showNotificationsSheet: $showNotificationsSheet,
                    destinations: destinations,
                    posts: $postManager.posts
                )
                
                // Main Content
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeTabView(
                                selectedFilter: $selectedFilter,
                                posts: postsFiltrados,
                                eventos: eventosFiltrados,
                                personas: personasFiltradas,
                                selectedDestination: selectedDestination,
                                filters: filters,
                                showCreatePostSheet: .constant(false),
                                isLoading: postManager.isLoading,
                                onLoadMore: {
                                    await postManager.fetchMorePosts(destination: selectedDestination)
                                }
                            )
                        case .search:
                            ExploreView()
                        case .map:
                            SocialMapView()
                        case .messages:
                            NavigationStack {
                                ChatView(initialConversationId: pendingChatId)
                                    .onAppear { pendingChatId = nil }
                            }
                        case .profile:
                            NavigationStack {
                                UserProfileView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom Navigation
                ModernBottomNavigationView(selectedTab: $selectedTab)
            }
            .sheet(isPresented: $showCreatePostSheet) {
                CreatePostOptionsView(
                    showSheet: $showCreatePostSheet, 
                    posts: $postManager.posts,
                    selectedFilter: $selectedFilter
                )
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsView()
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .task {
                await loadData()
            }
            .onChange(of: selectedDestination) { newDestination in
                Task { await loadData() }
            }
            .onChange(of: router.pendingTarget) { target in
                guard let target = target else { return }
                switch target {
                case .chat(let conversationId):
                    pendingChatId = conversationId
                    selectedTab = .messages
                case .notifications:
                    showNotificationsSheet = true
                case .post:
                    selectedTab = .home
                case .profile:
                    selectedTab = .profile
                }
                router.pendingTarget = nil
            }
            .refreshable {
                await loadData()
            }
            .overlay(alignment: .top) {
                if let toast = notificationManager.currentToast {
                    NotificationToastView(notification: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                        .zIndex(100)
                }
            }
            .animation(.spring(), value: notificationManager.currentToast)
        }
    }
    
    private func loadData() async {
        // Use user's Erasmus destination if available
        if selectedDestination == "Salamanca",
           let userDest = authManager.currentUser?.destination, !userDest.isEmpty {
            selectedDestination = userDest
        }
        await postManager.fetchInitialPosts(destination: selectedDestination)
        await eventManager.fetchEvents(destination: selectedDestination)
        await userManager.fetchRecommendedUsers(destination: selectedDestination)
        await GroupManager.shared.fetchUserGroup()
        notificationManager.startListening()
    }
}

// MARK: - Enums
enum Tab: Int, CaseIterable {
    case home, search, map, messages, profile

    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .map: return "map"
        case .messages: return "message"
        case .profile: return "person.circle"
        }
    }

    var title: String {
        switch self {
        case .home: return "Inicio"
        case .search: return "Explorar"
        case .map: return "Mapa"
        case .messages: return "Mensajes"
        case .profile: return "Perfil"
        }
    }
}

// MARK: - Components (Consolidated back into HomeView.swift)

struct ModernBottomNavigationView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? "\(tab.icon).fill" : tab.icon)
                            .font(.title3)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                        
                        Text(tab.title)
                            .font(.caption2)
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }
}

struct ModernHeaderView: View {
    @Binding var selectedDestination: String
    @Binding var showCreatePostSheet: Bool
    @Binding var showNotificationsSheet: Bool
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var groupManager = GroupManager.shared
    let destinations: [String]
    @Binding var posts: [ErasmusPost]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ErasmusConnect")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Tu aventura empieza aquí")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    if groupManager.currentGroup != nil {
                        NavigationLink(destination: MyGroupView()) {
                            Image(systemName: "person.3")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                    }
                    
                    Button(action: {
                        showNotificationsSheet = true
                        // Note: To clear badge we should add a method in NotificationManager, but for now we access static logic if needed or leave it.
                        // Assuming unreadCount is computed property, we can't set it directly unless logic allows.
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(Circle())
                            
                            if notificationManager.unreadCount > 0 {
                                Text("\(notificationManager.unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    Button(action: { showCreatePostSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                    }
                }
            }
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Picker("Destino", selection: $selectedDestination) {
                    ForEach(destinations, id: \.self) { city in
                        Text(city).tag(city)
                    }
                }
                .pickerStyle(.menu)
                .font(.subheadline)
                .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Rectangle().fill(.ultraThinMaterial).ignoresSafeArea())
    }
}

struct ModernFilterView: View {
    let filters: [String]
    @Binding var selectedFilter: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(selectedFilter == filter ? 
                                          AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                                          AnyShapeStyle(Color.gray.opacity(0.05))
                                    )
                            )
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(selectedFilter == filter ? Color.clear : Color.gray.opacity(0.4), lineWidth: 1))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
        .cornerRadius(16)
    }
}

struct HomeTabView: View {
    @Binding var selectedFilter: String
    let posts: [ErasmusPost]
    let eventos: [Evento]
    let personas: [UserProfile]
    let selectedDestination: String
    let filters: [String]
    @Binding var showCreatePostSheet: Bool
    @EnvironmentObject var authManager: FirebaseAuthManager

    // Pagination props
    var isLoading: Bool = false
    var onLoadMore: () async -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    ModernFilterView(filters: filters, selectedFilter: $selectedFilter)
                }
                .padding(.top, 10)
                
                if selectedFilter == "Todos" {
                    allCategoriesFeed
                } else {
                    filteredCategoryFeed
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    @ViewBuilder
    private var allCategoriesFeed: some View {
        Group {
            if !eventos.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Eventos destacados", icon: "sparkles", color: .orange)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(eventos) { evento in
                                EventCardView(evento: evento).frame(width: 280)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            if !personas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Gente en \(selectedDestination)", icon: "person.2.fill", color: .blue)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(personas) { profile in
                                PersonCardView(profile: profile).frame(width: 160)
                                    .environmentObject(authManager)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                if isLoading && posts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if posts.isEmpty {
                    EmptyStateView(
                        icon: "newspaper",
                        title: "No hay publicaciones",
                        message: "Sé el primero en publicar lo que está pasando en \(selectedDestination)."
                    )
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCardView(post: post)
                                .onAppear {
                                    if post == posts.last {
                                        Task {
                                            await onLoadMore()
                                        }
                                    }
                                }
                        }
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private var filteredCategoryFeed: some View {
        VStack(spacing: 20) {
            if selectedFilter == "Eventos" || selectedFilter == "Discotecas" {
                if isLoading && eventosFiltrados.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                } else if eventosFiltrados.isEmpty {
                    EmptyStateView(icon: "calendar.badge.exclamationmark", title: "No hay eventos", message: "Actualmente no hay eventos de esta categoría en \(selectedDestination).")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(eventosFiltrados) { evento in
                            EventCardView(evento: evento)
                        }
                    }
                }
            } else if selectedFilter == "Conocer" {
                if isLoading && personas.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                } else if personas.isEmpty {
                    EmptyStateView(icon: "person.2.slash", title: "Nadie nuevo por aquí", message: "No hemos encontrado personas nuevas para conocer en \(selectedDestination).")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(personas) { profile in
                            PersonCardView(profile: profile)
                                .environmentObject(authManager)
                        }
                    }
                }
            } else {
                if isLoading && posts.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                } else if posts.isEmpty {
                    EmptyStateView(icon: "doc.text.magnifyingglass", title: "Nada por aquí", message: "Todavía no hay publicaciones en \(selectedDestination).")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCardView(post: post)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    var eventosFiltrados: [Evento] {
        if selectedFilter == "Todos" { return eventos }
        return eventos.filter { $0.category == selectedFilter }
    }
}


struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.headline).fontWeight(.bold)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

struct SearchTabView: View {
    let posts: [ErasmusPost]
    let people: [UserProfile]
    let events: [Evento]
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var searchText = ""

    var filteredPosts: [ErasmusPost] {
        if searchText.isEmpty { return [] }
        return posts.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredPeople: [UserProfile] {
        if searchText.isEmpty { return [] }
        return people.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) || $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredEvents: [Evento] {
        if searchText.isEmpty { return [] }
        return events.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    if !filteredPeople.isEmpty {
                        Section("Personas") {
                            ForEach(filteredPeople) { profile in
                                PersonCardView(profile: profile)
                                    .environmentObject(authManager)
                            }
                        }
                    }
                    if !filteredEvents.isEmpty {
                        Section("Eventos") {
                            ForEach(filteredEvents) { event in
                                EventCardView(evento: event)
                            }
                        }
                    }
                    if !filteredPosts.isEmpty {
                        Section("Publicaciones") {
                            ForEach(filteredPosts) { post in
                                PostCardView(post: post)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("Busca algo...", systemImage: "magnifyingglass")
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Buscar usuarios, eventos...")
            .navigationTitle("Explorar")
        }
    }
}
