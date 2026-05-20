// UserProfileView.swift
import SwiftUI
import PhotosUI

// Explicit models/enums for the UI tabs
enum ProfileTab: String, CaseIterable {
    case publicaciones = "Publicaciones"
    case planes = "Planes"
    case recomendaciones = "Recomendaciones"
    case eventos = "Eventos"
    case amigos = "Amigos"
}

struct UserProfileView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @Environment(\.dismiss) private var dismiss
    
    // Optional targeted user. If nil, it shows the current logged-in user.
    var userToDisplay: ExtendedUserProfile?
    
    @State private var showingEditProfile = false
    @State private var showSettings = false
    @State private var showGroupSheet = false
    @State private var showReportAlert = false
    @StateObject private var postManager = PostManager.shared
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared

    // UI States
    @State private var selectedTab: ProfileTab = .publicaciones

    // Social Connection States
    @State private var isFollowing = false
    @State private var isFriendRequestSent = false
    @State private var isFriend = false
    @State private var socialActionLoading = false

    // Friends list
    @State private var friendProfiles: [UserProfile] = []
    @State private var isLoadingFriends = false

    // User's own posts (fetched specifically for this profile)
    @State private var userOwnPosts: [ErasmusPost] = []
    @State private var showChatSheet = false
    @State private var chatConversationId: String? = nil
    @State private var isLoadingUserPosts = false
    @State private var showSavedItems = false

    // Modal seguidores/seguidos/amigos (estilo Insta)
    @State private var followListKind: FollowListKind? = nil

    // MARK: - Share
    /// URL pública del perfil (deeplink + web). Cuando configures el dominio
    /// erasmusconnect.app con Universal Links, abrirá directamente en la app.
    private var profileShareURL: URL {
        let slug = user.username.isEmpty ? user.id : user.username
        return URL(string: "https://erasmusconnect.app/u/\(slug)") ?? URL(string: "https://erasmusconnect.app")!
    }
    private var profileShareMessage: String {
        if user.currentDestination.isEmpty {
            return "Mira el perfil de \(user.name) en ErasmusConnect"
        } else {
            return "Conoce a \(user.name), en Erasmus en \(user.currentDestination). Únete a ErasmusConnect 👇"
        }
    }
    private var followListUserIds: [String] {
        guard let kind = followListKind else { return [] }
        // Si no es mi propio perfil, uso los ids del UserProfile completo si los tengo cargados.
        // Para simplificar, usamos los ids del propio user object (followerIds, friendIds) del display target.
        switch kind {
        case .followers: return user.followerIds
        case .following: return authManager.currentUser?.id == user.id ? (authManager.currentUser?.followingIds ?? []) : []
        case .friends:   return user.friendIds
        case .posts:     return []
        }
    }
    
    // Geometry reading for parallax
    let headerHeight: CGFloat = 350
    
    // Logic property to dictate the UI mode
    private var isCurrentUser: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        if let targetUser = userToDisplay {
            return targetUser.id == currentUser.id
        }
        return true
    }
    
    // The actual user object being rendered
    private var user: ExtendedUserProfile {
        if let targetUser = userToDisplay {
            return targetUser
        }
        return authManager.currentUser?.toExtendedUserProfile() ?? ExtendedUserProfile.sampleUser
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Parallax Header
                    GeometryReader { geometry in
                        let scrollOffset = geometry.frame(in: .global).minY
                        let offset = scrollOffset > 0 ? -scrollOffset : 0
                        let height = scrollOffset > 0 ? headerHeight + scrollOffset : headerHeight
                        
                        ZStack(alignment: .bottom) {
                            // Background Image (Cover)
                            Group {
                                if let photoURL = user.photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    }
                                } else {
                                    LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                }
                            }
                            .frame(width: geometry.size.width, height: height)
                            .offset(y: offset)
                            
                            // Bottom Gradient / Glass Blur Overlay
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: height * 0.5)
                                .offset(y: offset)
                            
                            
                            // User Info inside the glass overlay
                            VStack(alignment: .center, spacing: 8) {
                                // Floating Avatar
                                UserAvatarView(photoURL: user.photoURL, name: user.name, size: 110)
                                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 3))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                // Name & Basic Info
                                HStack {
                                    Text(user.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    if user.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Subtitle: Flag -> Location
                                Text("🇪🇸 España → 📍 \(user.currentDestination)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                // University & Status
                                Text("\(user.university) • 📍 En destino")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.bottom, 24)
                            .offset(y: scrollOffset > 0 ? offset : 0) // Keeps info anchored to bottom when stretching
                        }
                    }
                    .frame(height: headerHeight)
                    // Allows the background to ignore safe area top
                    .ignoresSafeArea(.all, edges: .top)
                    
                    
                    // MARK: - Profile Body
                    VStack(spacing: 24) {
                        
                        // Action Buttons: Depends if it's My Profile or Someone Else's
                        if isCurrentUser {
                            selfManagementButtonsSection
                        } else {
                            socialActionButtonsSection
                            // Social Context Indicators ONLY for other users
                            socialIndicatorsSection
                        }
                        
                        // Mini Glass Stats
                        statsSection
                        
                        // About Me (Frosted Card)
                        aboutMeSection
                        
                        // Dynamic Tabs
                        VStack(spacing: 16) {
                            glassTabBar
                            
                            // Dynamic Tab Content
                            tabContentSection
                                .padding(.top, 8)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(.all, edges: .top)
            
            // Fixed Custom Header for settings (Sticks to top)
            topNavigationBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(user: user)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showGroupSheet) {
            MyGroupView()
        }
        .sheet(isPresented: $showSavedItems) {
            FavoritesView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showChatSheet) {
            if let convId = chatConversationId {
                NavigationStack {
                    ChatDetailView(conversation: Conversation(
                        id: convId, participants: [], lastMessage: "", lastMessageTime: Date()
                    ))
                    .environmentObject(authManager)
                }
            }
        }
        .alert("Usuario Reportado", isPresented: $showReportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Hemos recibido tu solicitud. Nuestro equipo revisará a este usuario.")
        }
        .onAppear {
            loadSocialStatus()
            Task { await loadUserPosts() }
            AppAnalytics.logProfileView(userId: user.id, isSelf: isCurrentUser)
        }
    }

    private func loadUserPosts() async {
        guard !isLoadingUserPosts else { return }
        isLoadingUserPosts = true
        userOwnPosts = await postManager.fetchUserPosts(userId: user.id)
        isLoadingUserPosts = false
    }

    private func loadSocialStatus() {
        guard !isCurrentUser, let myProfile = authManager.currentUser else { return }
        let targetId = user.id
        let status = socialManager.socialStatus(with: targetId, myProfile: myProfile)
        switch status {
        case .friends:
            isFriend = true
            isFollowing = true
        case .requestSent:
            isFriendRequestSent = true
        case .following:
            isFollowing = true
        case .none:
            break
        }
    }
    
    // MARK: - Top Navigation Bar (Liquid Header)
    private var topNavigationBar: some View {
        HStack {
            // Only show custom back button if we are looking at someone else's profile
            if !isCurrentUser {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            
            Spacer()
            
            Menu {
                // Compartir está siempre disponible
                ShareLink(item: profileShareURL, message: Text(profileShareMessage)) {
                    Label("Compartir perfil", systemImage: "square.and.arrow.up")
                }

                if isCurrentUser {
                    Button(action: { showSettings = true }) {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                    Button(action: { showingEditProfile = true }) {
                        Label("Editar Perfil", systemImage: "pencil")
                    }
                    Button(action: { showSavedItems = true }) {
                        Label("Guardados", systemImage: "bookmark.fill")
                    }
                } else {
                    Button(role: .destructive, action: { showReportAlert = true }) {
                        Label("Reportar", systemImage: "flag.fill")
                    }
                    Button(role: .destructive, action: {
                        Task {
                            try? await socialManager.block(userId: user.id)
                            dismiss()
                        }
                    }) {
                        Label(socialManager.isBlocked(userId: user.id) ? "Desbloquear" : "Bloquear", systemImage: "hand.raised.fill")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.5))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        // Adjust for safe area manually
        .padding(.top, safeAreaTop)
    }
    
    private var safeAreaTop: CGFloat {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 50 }
        return windowScene.windows.first?.safeAreaInsets.top ?? 50
        #else
        return 50
        #endif
    }
    
    // MARK: - Action Buttons (Public Profile)
    private var socialActionButtonsSection: some View {
        HStack(spacing: 12) {
            
            if isFriend {
                // Already Friends Status
                Button(action: { /* open context menu for friends */ }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Amigos")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(22)
                }
                
                // Message button opens DM
                Button(action: {
                    Task {
                        if let convId = await ChatManager.shared.getOrCreateConversation(with: user.id) {
                            chatConversationId = convId
                            showChatSheet = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Mensaje")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 44)
                    .background(.ultraThinMaterial)
                    .cornerRadius(22)
                }
            } else {
                // Seguir (Glass button)
                Button(action: {
                    Task {
                        socialActionLoading = true
                        do {
                            if isFollowing {
                                try await socialManager.unfollow(userId: user.id)
                            } else {
                                try await socialManager.follow(userId: user.id)
                            }
                            withAnimation { isFollowing.toggle() }
                        } catch { }
                        socialActionLoading = false
                    }
                }) {
                    Text(isFollowing ? "Siguiendo" : "Seguir")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isFollowing ? .white : .primary)
                        .frame(width: 90, height: 44)
                        .background(
                            isFollowing ?
                            AnyShapeStyle(Color.black.opacity(0.6)) :
                            AnyShapeStyle(.ultraThinMaterial)
                        )
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                // Añadir Amigo
                Button(action: {
                    guard !isFriendRequestSent else { return }
                    Task {
                        socialActionLoading = true
                        do {
                            try await socialManager.sendFriendRequest(toUserId: user.id, toUserName: user.name)
                            withAnimation { isFriendRequestSent = true }
                        } catch { }
                        socialActionLoading = false
                    }
                }) {
                    HStack {
                        if socialActionLoading {
                            ProgressView().tint(.white).frame(width: 18, height: 18)
                        } else {
                            Image(systemName: isFriendRequestSent ? "person.badge.clock.fill" : "person.badge.plus")
                        }
                        Text(isFriendRequestSent ? "Solicitud enviada" : "Añadir amigo")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isFriendRequestSent ? .gray : .white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        isFriendRequestSent ?
                        AnyShapeStyle(Color.gray.opacity(0.2)) :
                        AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    )
                    .cornerRadius(22)
                    .shadow(color: isFriendRequestSent ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isFriendRequestSent || socialActionLoading)

                // Mensaje Icon
                Button(action: {
                    Task {
                        if let convId = await ChatManager.shared.getOrCreateConversation(with: user.id) {
                            chatConversationId = convId
                            showChatSheet = true
                        }
                    }
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Action Buttons (My Profile)
    private var selfManagementButtonsSection: some View {
        HStack(spacing: 12) {
            
            // Editar Perfil (Primary)
            Button(action: {
                showingEditProfile = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Editar perfil")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.blue)
                .cornerRadius(22)
            }
            
            // Compartir Perfil
            Button(action: {
                // Share sheet logic
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Compartir")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(.ultraThinMaterial)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Groups button
            Button(action: {
                showGroupSheet = true
            }) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .cornerRadius(22)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Social Indicators (Smart Context)
    private var socialIndicatorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Mutual Friends Context
            HStack(spacing: 6) {
                HStack(spacing: -8) {
                    // Mock Mutual Friends
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color(UIColor.systemGroupedBackground), lineWidth: 2))
                    }
                }
                let commonCount = Set(user.friendIds).intersection(Set(authManager.currentUser?.friendIds ?? [])).count
                if commonCount > 0 {
                    Text("Tenéis \(commonCount) amigo\(commonCount == 1 ? "" : "s") en común")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                Spacer()
            }
            
            // Mutual Interests Context (Mock)
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("Coincidís en 4 intereses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Mini Stats (Glass Card)
    private var statsSection: some View {
        HStack(spacing: 0) {
            // Publicaciones (no abre modal, scroll a sección)
            StatButton(value: "\(userOwnPosts.count)", title: "Posts") {
                // Se podría hacer scroll, por ahora no acción
            }
            Divider().frame(height: 36).padding(.horizontal, 4)

            // Seguidores → abre modal estilo Insta
            StatButton(value: "\(user.followerIds.count)", title: "Seguidores") {
                followListKind = .followers
            }
            Divider().frame(height: 36).padding(.horizontal, 4)

            // Siguiendo (solo si es mi propio perfil, porque sólo tengo mis followingIds)
            if isCurrentUser, let following = authManager.currentUser?.followingIds {
                StatButton(value: "\(following.count)", title: "Siguiendo") {
                    followListKind = .following
                }
                Divider().frame(height: 36).padding(.horizontal, 4)
            }

            // Amigos
            StatButton(value: "\(user.friendIds.count)", title: "Amigos") {
                followListKind = .friends
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .sheet(item: $followListKind) { kind in
            FollowListView(kind: kind, userIds: followListUserIds)
                .environmentObject(authManager)
        }
    }
    
    // MARK: - About Me (Frosted Card)
    private var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            } else if isCurrentUser {
                Text("Añade una bio en Editar Perfil para que otros Erasmus te conozcan mejor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Interests
            VStack(alignment: .leading, spacing: 8) {
                Text("Intereses")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(user.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Languages
            VStack(alignment: .leading, spacing: 8) {
                Text("Idiomas")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text((user.languages.isEmpty ? ["🇪🇸 Español", "🇬🇧 Inglés", "🇮🇹 Italiano"] : user.languages).joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Segmented Tabs (Liquid Glass Style)
    private var glassTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    // Logic filtering tabs
                    // E.g., Hide Friends tab if we are looking at Public Profile and we are NOT friends
                    if tab == .amigos && !isCurrentUser && !isFriend {
                        // Don't show
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .bold : .medium)
                                .foregroundColor(selectedTab == tab ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTab == tab ?
                                    AnyShapeStyle(Color.black.opacity(0.8)) :
                                    AnyShapeStyle(.ultraThinMaterial)
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedTab == tab ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Dynamic Tab Content
    private var tabContentSection: some View {
        VStack {
            switch selectedTab {
            case .publicaciones:
                userPostsFeed
            case .planes:
                userPlansFeed
            case .eventos:
                userEventsFeed
            case .recomendaciones:
                userRecommendationsFeed
            case .amigos:
                userFriendsFeed
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Tab: Publicaciones
    private var userPostsFeed: some View {
        LazyVStack(spacing: 16) {
            if isLoadingUserPosts {
                ProgressView()
                    .padding(.top, 40)
            } else {
                let myPosts = userOwnPosts.filter { $0.type != .event }
                if myPosts.isEmpty {
                    emptyGlassState(icon: "doc.text", title: "Sin publicaciones", desc: "No hay actividad reciente.")
                } else {
                    ForEach(myPosts) { post in
                        PostCardView(post: post)
                    }
                }
            }
        }
    }

    // MARK: Tab: Eventos
    private var userEventsFeed: some View {
        LazyVStack(spacing: 16) {
            if isLoadingUserPosts {
                ProgressView()
                    .padding(.top, 40)
            } else {
                let myEvents = userOwnPosts.filter { $0.type == .event }
                if myEvents.isEmpty {
                    emptyGlassState(icon: "calendar", title: "Sin eventos", desc: "Aún no ha organizado ningún evento.")
                } else {
                    ForEach(myEvents) { event in
                        PostCardView(post: event)
                    }
                }
            }
        }
    }
    
    // MARK: Mock Tabs (Planes, Recomendaciones, Amigos)
    private var userPlansFeed: some View {
        Group {
            if isCurrentUser || isFriend {
                emptyGlassState(icon: "map", title: "Sin planes abiertos", desc: "No hay planes activos.")
            } else {
                emptyGlassState(icon: "lock.fill", title: "Planes privados", desc: "Solo los amigos pueden ver los planes.")
            }
        }
    }
    
    private var userRecommendationsFeed: some View {
        LazyVStack(spacing: 16) {
            let recs = userOwnPosts.filter { $0.type == .recommendation }
            if recs.isEmpty {
                emptyGlassState(icon: "star", title: "Sin recomendaciones", desc: "No ha compartido ninguna recomendación local.")
            } else {
                ForEach(recs) { rec in
                    PostCardView(post: rec)
                }
            }
        }
    }
    
    private var userFriendsFeed: some View {
        Group {
            if isLoadingFriends {
                ProgressView("Cargando amigos...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if friendProfiles.isEmpty {
                emptyGlassState(icon: "person.2", title: "Sin amigos aún", desc: "Conecta con otros erasmus enviando solicitudes de amistad.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(friendProfiles) { friend in
                        HStack(spacing: 12) {
                            if !friend.photoURL.isEmpty, let url = URL(string: friend.photoURL) {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(friend.displayName.prefix(1)))
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.displayName)
                                    .font(.headline)
                                if !friend.destination.isEmpty {
                                    Text("📍 \(friend.destination)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                }
            }
        }
        .task {
            guard !isLoadingFriends else { return }
            isLoadingFriends = true
            friendProfiles = await socialManager.fetchFriends(ids: user.friendIds)
            isLoadingFriends = false
        }
    }
    
    // Reusable Empty State
    private func emptyGlassState(icon: String, title: String, desc: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text(title)
                .font(.headline)
            Text(desc)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
    }
}

// MARK: - Subcomponents

struct StatItem: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Versión clicable de StatItem para abrir modales tipo Instagram al pulsar el número.
struct StatButton: View {
    let value: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityHint("Toca dos veces para ver la lista")
    }
}

// MARK: - Edit Profile View (Placeholder)
/// Edición de perfil completa — todos los campos del onboarding en una sola pantalla.
struct EditProfileView: View {
    let user: ExtendedUserProfile
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @StateObject private var profileManager = UserProfileManager.shared

    // MARK: - Campos editables
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var university: String = ""
    @State private var career: String = ""
    @State private var destination: String = ""
    @State private var originCountry: String = "España"
    @State private var originCity: String = ""
    @State private var erasmusStatus: String = ""
    @State private var erasmusStartDate: Date = Date()
    @State private var hasStartDate: Bool = false
    @State private var interests: [String] = []
    @State private var languages: [LanguageLevel] = []

    // Privacidad
    @State private var isPrivateAccount: Bool = false
    @State private var showOnlineStatus: Bool = true

    // Foto
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    // UI state
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showAddInterest = false
    @State private var newInterest: String = ""
    @State private var showAddLanguage = false

    private let erasmusStatusOptions = [
        "future":  "Voy a hacer Erasmus",
        "current": "Estoy haciendo Erasmus",
        "past":    "Ya hice Erasmus",
        "local":   "Local, no Erasmus"
    ]

    private let popularInterests = [
        "🎉 Fiesta", "🎭 Cultura", "🍕 Gastronomía", "📸 Fotografía",
        "✈️ Viajes", "⚽ Deporte", "🎵 Música", "📚 Literatura",
        "🎨 Arte", "🏛️ Historia", "🌿 Naturaleza", "🎮 Gaming",
        "💻 Tech", "🍻 Bares", "🎬 Cine"
    ]

    private let countries = ["España", "Italia", "Francia", "Alemania", "Portugal",
                             "Reino Unido", "Países Bajos", "Polonia", "Otro"]

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                basicInfoSection
                originSection
                academicSection
                erasmusSection
                languagesSection
                interestsSection
                privacySection

                if let saveError = saveError {
                    Section { Text(saveError).foregroundColor(.red).font(.footnote) }
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Guardando..." : "Guardar") {
                        Task { await saveChanges() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            .onAppear { loadCurrent() }
            .sheet(isPresented: $showAddLanguage) {
                AddLanguageSheet { newLang in
                    languages.append(newLang)
                }
            }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Group {
                        if let img = selectedImage {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else {
                            UserAvatarView(photoURL: authManager.currentUser?.photoURL, name: name, size: 110)
                        }
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3))

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Cambiar foto", systemImage: "camera.fill")
                            .font(.footnote).fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    private var basicInfoSection: some View {
        Section(header: Text("Información básica")) {
            TextField("Nombre", text: $name)
            HStack {
                Text("@").foregroundColor(.secondary)
                TextField("usuario", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            TextField("Biografía", text: $bio, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var originSection: some View {
        Section(header: Text("De dónde eres")) {
            Picker("País", selection: $originCountry) {
                ForEach(countries, id: \.self) { Text($0).tag($0) }
            }
            TextField("Ciudad de origen", text: $originCity)
        }
    }

    private var academicSection: some View {
        Section(header: Text("Académico")) {
            TextField("Universidad", text: $university)
            TextField("Carrera o estudios", text: $career)
        }
    }

    private var erasmusSection: some View {
        Section(header: Text("Erasmus")) {
            // Estado
            Picker("Estado", selection: $erasmusStatus) {
                Text("Selecciona...").tag("")
                ForEach(Array(erasmusStatusOptions.keys), id: \.self) { key in
                    Text(erasmusStatusOptions[key] ?? key).tag(key)
                }
            }

            // Destino con CityPicker (solo activas, próximamente avisa)
            HStack {
                Text("Destino").foregroundColor(.primary)
                Spacer()
                CityPicker(selected: $destination, label: "Elige")
                    .frame(maxWidth: 200, alignment: .trailing)
            }

            // Fecha inicio
            Toggle("Fecha de inicio", isOn: $hasStartDate)
            if hasStartDate {
                DatePicker("", selection: $erasmusStartDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var languagesSection: some View {
        Section(header: HStack {
            Text("Idiomas")
            Spacer()
            Button { showAddLanguage = true } label: {
                Image(systemName: "plus.circle.fill").foregroundColor(.blue)
            }
        }) {
            if languages.isEmpty {
                Text("Aún no has añadido ningún idioma")
                    .font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(languages) { lang in
                    HStack {
                        Text(lang.language)
                        Spacer()
                        Text(lang.level)
                            .font(.caption).foregroundColor(.secondary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .onDelete { offsets in languages.remove(atOffsets: offsets) }
            }
        }
    }

    private var interestsSection: some View {
        Section(header: Text("Intereses")) {
            // Chips de mis intereses
            if !interests.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(interests, id: \.self) { interest in
                        Button(action: { interests.removeAll { $0 == interest } }) {
                            HStack(spacing: 4) {
                                Text(interest).font(.caption)
                                Image(systemName: "xmark").font(.caption2)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Sugerencias para añadir
            Text("Toca para añadir / quitar")
                .font(.caption2).foregroundColor(.secondary)
            FlowLayout(spacing: 6) {
                ForEach(popularInterests, id: \.self) { item in
                    let isSelected = interests.contains(item)
                    Button(action: { toggleInterest(item) }) {
                        Text(item)
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                            .foregroundColor(isSelected ? .blue : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var privacySection: some View {
        Section(header: Text("Privacidad")) {
            Toggle(isOn: $isPrivateAccount) {
                Label("Cuenta privada", systemImage: "lock.fill")
            }
            Toggle(isOn: $showOnlineStatus) {
                Label("Mostrar cuándo estoy online", systemImage: "circle.fill")
            }
        }
    }

    // MARK: - Helpers

    private func toggleInterest(_ item: String) {
        if let idx = interests.firstIndex(of: item) {
            interests.remove(at: idx)
        } else {
            interests.append(item)
        }
    }

    private func loadCurrent() {
        guard let me = authManager.currentUser else { return }
        name = me.displayName
        username = me.username
        bio = me.bio
        university = me.university
        career = me.career
        destination = me.destination
        originCountry = me.originCountry
        originCity = me.originCity
        erasmusStatus = me.erasmusStatus
        interests = me.interests
        languages = me.languages
        isPrivateAccount = me.permissions.isPrivateAccount
        showOnlineStatus = me.permissions.showOnlineStatus
        if let dateStr = me.erasmusStartDate {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "es_ES")
            fmt.dateFormat = "MMM yyyy"
            if let d = fmt.date(from: dateStr.lowercased().capitalized) {
                erasmusStartDate = d
                hasStartDate = true
            }
        }
    }

    private func saveChanges() async {
        guard let userId = authManager.currentUser?.id else { return }
        isSaving = true
        saveError = nil

        do {
            if let newImage = selectedImage {
                _ = try await profileManager.uploadProfileImage(newImage, userId: userId)
            }

            // Languages como array de dicts (Codable manual para Firestore)
            let languagesData: [[String: Any]] = languages.map {
                ["id": $0.id, "language": $0.language, "level": $0.level]
            }

            var updates: [String: Any] = [
                "displayName": name.trimmingCharacters(in: .whitespaces),
                "username": username.trimmingCharacters(in: .whitespaces),
                "bio": bio,
                "university": university,
                "career": career,
                "destination": destination,
                "originCountry": originCountry,
                "originCity": originCity,
                "erasmusStatus": erasmusStatus,
                "interests": interests,
                "languages": languagesData,
                "permissions.isPrivateAccount": isPrivateAccount,
                "permissions.showOnlineStatus": showOnlineStatus
            ]
            if hasStartDate {
                let fmt = DateFormatter()
                fmt.locale = Locale(identifier: "es_ES")
                fmt.dateFormat = "MMM yyyy"
                updates["erasmusStartDate"] = fmt.string(from: erasmusStartDate).capitalized
            }

            try await profileManager.updateUserProfile(userId: userId, updates: updates)
            _ = try await authManager.getUserProfile()

            await MainActor.run {
                AppErrorManager.shared.success("Perfil actualizado", icon: "checkmark.circle.fill")
                isSaving = false
                dismiss()
            }
        } catch {
            print("Error guardando perfil: \(error)")
            await MainActor.run {
                saveError = "No se pudo guardar: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - FlowLayout (chips wrap)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let width = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if lineWidth + size.width > width {
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .init(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - AddLanguageSheet
struct AddLanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (LanguageLevel) -> Void

    @State private var language: String = "Español"
    @State private var level: String = "Nativo"

    private let languages = ["Español", "Inglés", "Francés", "Italiano", "Alemán",
                             "Portugués", "Catalán", "Gallego", "Euskera", "Chino", "Árabe"]
    private let levels = ["Básico", "Intermedio", "Avanzado", "Nativo"]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Idioma", selection: $language) {
                    ForEach(languages, id: \.self) { Text($0).tag($0) }
                }
                Picker("Nivel", selection: $level) {
                    ForEach(levels, id: \.self) { Text($0).tag($0) }
                }
            }
            .navigationTitle("Añadir idioma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        onAdd(LanguageLevel(language: language, level: level))
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
        }
    }
}
