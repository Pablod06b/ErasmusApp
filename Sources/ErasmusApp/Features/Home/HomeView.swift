// HomeView.swift
import SwiftUI

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

// MARK: - Feed Sort Mode
enum FeedSortMode: String, CaseIterable {
    case recientes = "Recientes"
    case popular = "Popular"
    case paraTi = "Para ti"
    case eventos = "Eventos"
    case personas = "Personas"

    var icon: String {
        switch self {
        case .recientes: return "clock.fill"
        case .popular: return "flame.fill"
        case .paraTi: return "star.fill"
        case .eventos: return "calendar"
        case .personas: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .recientes: return .blue
        case .popular: return .orange
        case .paraTi: return .purple
        case .eventos: return .green
        case .personas: return .pink
        }
    }
}

// MARK: - Feed Item (unified for mixed list)
enum FeedItem: Identifiable {
    case post(ErasmusPost)
    case event(Evento)
    case person(UserProfile)

    var id: String {
        switch self {
        case .post(let p): return "post_\(p.id)"
        case .event(let e): return "event_\(e.id)"
        case .person(let u): return "user_\(u.id)"
        }
    }
}

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @StateObject private var postManager = PostManager.shared
    @StateObject private var eventManager = EventManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var router = NavigationRouter.shared

    @State private var selectedSort: FeedSortMode = .recientes
    @State private var showCreatePostSheet = false
    @State private var showNotificationsSheet = false
    @State private var selectedTab: Tab = .home
    @State private var selectedDestination = "Salamanca"
    @State private var pendingChatId: String? = nil

    let destinations = ["Salamanca", "Madrid", "Barcelona", "Valencia", "Roma", "París", "Berlín", "Lisboa", "Milán", "Ámsterdam"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ModernHeaderView(
                    selectedDestination: $selectedDestination,
                    showCreatePostSheet: $showCreatePostSheet,
                    showNotificationsSheet: $showNotificationsSheet,
                    destinations: destinations,
                    posts: $postManager.posts
                )

                ZStack(alignment: .bottomTrailing) {
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeTabView(
                                selectedSort: $selectedSort,
                                posts: postManager.posts,
                                eventos: eventManager.events,
                                personas: userManager.recommendedProfiles,
                                selectedDestination: selectedDestination,
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

                ModernBottomNavigationView(selectedTab: $selectedTab)
            }
            .sheet(isPresented: $showCreatePostSheet) {
                CreatePostOptionsView(showSheet: $showCreatePostSheet, posts: $postManager.posts)
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsView()
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .task { await loadData() }
            .onChange(of: selectedDestination) { _ in Task { await loadData() } }
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

// MARK: - Tab Enum
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

// MARK: - Bottom Navigation
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

// MARK: - Header
struct ModernHeaderView: View {
    @Binding var selectedDestination: String
    @Binding var showCreatePostSheet: Bool
    @Binding var showNotificationsSheet: Bool
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var groupManager = GroupManager.shared
    let destinations: [String]
    @Binding var posts: [ErasmusPost]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ErasmusConnect")
                        .font(.title2).fontWeight(.bold)
                    Text("Tu aventura empieza aquí")
                        .font(.caption).foregroundColor(.secondary)
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
                    Button(action: { showNotificationsSheet = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.title3).foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(Circle())
                            if notificationManager.unreadCount > 0 {
                                Text("\(notificationManager.unreadCount)")
                                    .font(.caption2).fontWeight(.bold)
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
                            .font(.title3).foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                    }
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "location.fill").foregroundColor(.blue).font(.caption)
                Picker("Destino", selection: $selectedDestination) {
                    ForEach(destinations, id: \.self) { city in Text(city).tag(city) }
                }
                .pickerStyle(.menu)
                .font(.subheadline).fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Rectangle().fill(.ultraThinMaterial).ignoresSafeArea())
    }
}

// MARK: - Sort Chips
struct FeedSortChipsView: View {
    @Binding var selected: FeedSortMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FeedSortMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = mode
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.caption)
                            Text(mode.rawValue)
                                .font(.subheadline).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(
                            selected == mode
                                ? AnyShapeStyle(mode.color.opacity(0.15))
                                : AnyShapeStyle(Color(UIColor.secondarySystemBackground))
                        )
                        .foregroundColor(selected == mode ? mode.color : .secondary)
                        .overlay(
                            Capsule()
                                .stroke(selected == mode ? mode.color : Color.gray.opacity(0.2), lineWidth: selected == mode ? 1.5 : 1)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 56)).foregroundColor(.gray.opacity(0.45))
            Text(title).font(.title3).fontWeight(.bold)
            Text(message).font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Mixed Feed
struct HomeTabView: View {
    @Binding var selectedSort: FeedSortMode
    let posts: [ErasmusPost]
    let eventos: [Evento]
    let personas: [UserProfile]
    let selectedDestination: String
    var isLoading: Bool = false
    var onLoadMore: () async -> Void = {}

    @State private var refreshSeed: Int = 0
    @State private var feedItems: [FeedItem] = []
    @EnvironmentObject var authManager: FirebaseAuthManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                FeedSortChipsView(selected: $selectedSort)
                    .padding(.top, 8)

                if isLoading && feedItems.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else if feedItems.isEmpty {
                    EmptyStateView(
                        icon: "newspaper",
                        title: "Nada por aquí todavía",
                        message: "Sé el primero en publicar algo en \(selectedDestination)."
                    )
                } else {
                    ForEach(feedItems) { item in
                        Group {
                            switch item {
                            case .post(let p):
                                FeedPostCard(post: p)
                            case .event(let e):
                                FeedEventCard(evento: e)
                            case .person(let u):
                                FeedPersonCard(profile: u)
                                    .environmentObject(authManager)
                            }
                        }
                        .onAppear {
                            if case .post(let p) = item, p == posts.last {
                                Task { await onLoadMore() }
                            }
                        }
                    }
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            refreshSeed += 1
            feedItems = buildFeed()
            await onLoadMore()
        }
        .onAppear { feedItems = buildFeed() }
        .onChange(of: selectedSort) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                feedItems = buildFeed()
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        .onChange(of: posts.count) { _ in feedItems = buildFeed() }
        .onChange(of: eventos.count) { _ in feedItems = buildFeed() }
        .onChange(of: personas.count) { _ in feedItems = buildFeed() }
    }

    private func buildFeed() -> [FeedItem] {
        switch selectedSort {
        case .recientes:
            return interleaved(posts: posts, events: eventos, people: personas, eventEvery: 4, personEvery: 7)
        case .popular:
            return interleavedEventFirst(posts: posts, events: eventos, people: personas)
        case .paraTi:
            return shuffledMix(posts: posts, events: eventos, people: personas, seed: refreshSeed)
        case .eventos:
            if eventos.isEmpty { return posts.map { .post($0) } }
            return eventos.map { .event($0) }
        case .personas:
            if personas.isEmpty { return posts.map { .post($0) } }
            return personas.map { .person($0) }
        }
    }

    private func interleaved(posts: [ErasmusPost], events: [Evento], people: [UserProfile], eventEvery: Int, personEvery: Int) -> [FeedItem] {
        var result: [FeedItem] = []
        var ei = 0, pi = 0
        for (i, post) in posts.enumerated() {
            result.append(.post(post))
            if (i + 1) % eventEvery == 0, ei < events.count {
                result.append(.event(events[ei])); ei += 1
            }
            if (i + 1) % personEvery == 0, pi < people.count {
                result.append(.person(people[pi])); pi += 1
            }
        }
        while ei < events.count { result.append(.event(events[ei])); ei += 1 }
        while pi < people.count { result.append(.person(people[pi])); pi += 1 }
        return result
    }

    private func interleavedEventFirst(posts: [ErasmusPost], events: [Evento], people: [UserProfile]) -> [FeedItem] {
        var result: [FeedItem] = []
        var pi = 0
        let grouped = zip(events, posts.prefix(events.count))
        for (event, post) in grouped {
            result.append(.event(event))
            result.append(.post(post))
            if result.count % 6 == 0, pi < people.count {
                result.append(.person(people[pi])); pi += 1
            }
        }
        if posts.count > events.count {
            result.append(contentsOf: posts[events.count...].map { .post($0) })
        }
        while pi < people.count { result.append(.person(people[pi])); pi += 1 }
        return result
    }

    private func shuffledMix(posts: [ErasmusPost], events: [Evento], people: [UserProfile], seed: Int) -> [FeedItem] {
        var all: [FeedItem] = posts.map { .post($0) }
            + eventos.prefix(min(eventos.count, max(1, posts.count / 2))).map { .event($0) }
            + personas.prefix(min(personas.count, max(1, posts.count / 4))).map { .person($0) }
        guard all.count > 1 else { return all }
        // Fisher-Yates shuffle with LCG — overflow-safe via UInt arithmetic
        var rng = UInt(bitPattern: seed == 0 ? 12345 : seed)
        for i in stride(from: all.count - 1, through: 1, by: -1) {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            let j = Int(rng >> 33) % (i + 1)   // upper bits, always in [0, i]
            all.swapAt(i, j)
        }
        return all
    }
}

// MARK: - Feed Post Card (Instagram style)
struct FeedPostCard: View {
    let post: ErasmusPost
    @State private var isLiked = false
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var postManager = PostManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager

    private var isSaved: Bool { favoritesManager.isPostSaved(post.id.uuidString) }

    private var typeGradient: [Color] {
        switch post.type {
        case .event: return [.orange, .red]
        case .recommendation: return [.green, .teal]
        case .announcement: return [.blue, .indigo]
        case .personalPlan: return [.purple, .pink]
        case .openMessage: return [.cyan, .blue]
        case .housing: return [.brown, .orange]
        }
    }

    private var typeIcon: String {
        switch post.type {
        case .event: return "calendar.badge.plus"
        case .recommendation: return "star.fill"
        case .announcement: return "megaphone.fill"
        case .personalPlan: return "person.2.fill"
        case .openMessage: return "bubble.right.fill"
        case .housing: return "house.fill"
        }
    }

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(alignment: .leading, spacing: 0) {
                // Type + save header
                HStack {
                    Label(post.type.rawValue, systemImage: typeIcon)
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(LinearGradient(colors: typeGradient, startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .clipShape(Capsule())

                    Spacer()

                    if post.isVerifiedBusiness == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue).font(.subheadline)
                    }

                    Button(action: { Task { await favoritesManager.togglePost(post) } }) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isSaved ? .blue : .secondary)
                            .font(.system(size: 17))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

                // Visual area
                ZStack(alignment: .bottomLeading) {
                    if let imageName = post.imageName, let img = loadLocalImage(named: imageName) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 200)
                            .clipped()
                    } else {
                        LinearGradient(colors: typeGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 160)
                            .overlay(
                                Image(systemName: typeIcon)
                                    .font(.system(size: 52, weight: .ultraLight))
                                    .foregroundColor(.white.opacity(0.35))
                            )
                    }

                    if let location = post.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                            Text(location).lineLimit(1)
                        }
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(10)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.title)
                        .font(.headline).fontWeight(.bold)
                        .lineLimit(2)
                    Text(post.description)
                        .font(.subheadline).foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 4)

                // Footer
                HStack(spacing: 0) {
                    if let price = post.price, post.isPaid == true {
                        Text(price == 0 ? "Gratis" : String(format: "%.0f€", price))
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(price == 0 ? .green : .primary)
                    }
                    Spacer()
                    Button(action: {
                        guard let userId = authManager.currentUser?.id else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isLiked.toggle() }
                        Task { await postManager.toggleLike(postId: post.id.uuidString, userId: userId) }
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .secondary)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 16)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var destinationView: some View {
        if post.type == .personalPlan || post.type == .openMessage {
            OpenPlanDetailView(post: post)
        } else {
            PostDetailView(post: post)
        }
    }

    private func loadLocalImage(named name: String) -> UIImage? {
        LocalImageCache.shared.image(for: name)
    }
}

// MARK: - Local image cache (avoids hitting disk every render)
final class LocalImageCache {
    static let shared = LocalImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 80 }

    func image(for name: String) -> UIImage? {
        let key = name as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let img = UIImage(contentsOfFile: docs.appendingPathComponent(name).path) else { return nil }
        cache.setObject(img, forKey: key)
        return img
    }
}

// MARK: - Feed Event Card
struct FeedEventCard: View {
    let evento: Evento

    private var categoryColor: Color {
        switch evento.category.lowercased() {
        case "discoteca", "fiesta", "club": return .purple
        case "deporte", "sport": return .green
        case "cultura", "arte", "museum": return .orange
        case "comida", "gastronomía": return .red
        default: return .blue
        }
    }

    var body: some View {
        NavigationLink(destination: EventDetailPlaceholder(evento: evento)) {
            VStack(alignment: .leading, spacing: 0) {
                // Banner
                ZStack(alignment: .topTrailing) {
                    if let urlStr = evento.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(maxWidth: .infinity).frame(height: 180)
                                    .clipped()
                            default:
                                eventGradient.frame(height: 180)
                            }
                        }
                    } else {
                        eventGradient.frame(height: 180)
                    }

                    // Date pill
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(evento.date)
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(evento.category)
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundColor(categoryColor)
                            .clipShape(Capsule())

                        Spacer()

                        if let price = evento.price {
                            Text(price == 0 ? "Gratis" : String(format: "%.0f€", price))
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundColor(price == 0 ? .green : .primary)
                        }
                    }

                    Text(evento.title)
                        .font(.headline).fontWeight(.bold).lineLimit(2)

                    HStack(spacing: 12) {
                        Label(evento.location, systemImage: "mappin.circle.fill")
                            .font(.caption).foregroundColor(.secondary).lineLimit(1)

                        if let participants = evento.participants {
                            Label("\(participants)", systemImage: "person.2.fill")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding(14)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var eventGradient: some View {
        LinearGradient(
            colors: [categoryColor.opacity(0.8), categoryColor.opacity(0.4)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.5))
        )
    }
}

// Placeholder event detail until a real one exists
private struct EventDetailPlaceholder: View {
    let evento: Evento
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(evento.title).font(.largeTitle).fontWeight(.bold).padding(.horizontal)
                Label(evento.location, systemImage: "mappin.circle.fill").padding(.horizontal)
                Label(evento.date, systemImage: "calendar").padding(.horizontal)
                if let desc = evento.eventDescription {
                    Text(desc).padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Evento")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feed Person Card
struct FeedPersonCard: View {
    let profile: UserProfile
    @EnvironmentObject var authManager: FirebaseAuthManager

    var body: some View {
        NavigationLink(destination: UserProfileView(userToDisplay: profile.toExtendedUserProfile())
            .environmentObject(authManager)) {
            HStack(spacing: 14) {
                // Avatar
                Group {
                    if !profile.photoURL.isEmpty, let url = URL(string: profile.photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: initialsView
                            }
                        }
                    } else {
                        initialsView
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 2))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text(profile.displayName)
                            .font(.headline).fontWeight(.bold).lineLimit(1)
                        if profile.accountType == .business {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue).font(.caption)
                        }
                    }
                    if !profile.university.isEmpty {
                        Text(profile.university)
                            .font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                    if !profile.destination.isEmpty {
                        Label(profile.destination, systemImage: "location.fill")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    if !profile.interests.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(profile.interests.prefix(3), id: \.self) { interest in
                                    Text(interest)
                                        .font(.caption2).fontWeight(.medium)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer(minLength: 0)

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var initials: String {
        let words = profile.displayName.split(separator: " ")
        return words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal]
        let idx = ((profile.displayName.hashValue % colors.count) + colors.count) % colors.count
        return colors[idx]
    }

    private var initialsView: some View {
        ZStack {
            avatarColor.opacity(0.25)
            Text(initials.isEmpty ? "?" : initials)
                .font(.title2).fontWeight(.bold)
                .foregroundColor(avatarColor)
        }
    }
}
