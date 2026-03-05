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
    
    // UI States
    @State private var selectedTab: ProfileTab = .publicaciones
    
    // Social Connection States (Mocked for now)
    @State private var isFollowing = false
    @State private var isFriendRequestSent = false
    @State private var isFriend = false // Toggles between Add Friend and ✔ Amigos
    
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
                                Group {
                                    if let photoURL = user.photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Circle().fill(Color.gray.opacity(0.3))
                                        }
                                    } else {
                                        AsyncImage(url: URL(string: "https://picsum.photos/300/300?random=\(user.id)")) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundColor(.white))
                                        }
                                    }
                                }
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
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
        .alert("Usuario Reportado", isPresented: $showReportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Hemos recibido tu solicitud. Nuestro equipo revisará a este usuario.")
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
                if isCurrentUser {
                    Button(action: { showSettings = true }) {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                    Button(action: { showingEditProfile = true }) {
                        Label("Editar Perfil", systemImage: "pencil")
                    }
                } else {
                    Button(role: .destructive, action: { showReportAlert = true }) {
                        Label("Reportar o Bloquear", systemImage: "exclamationmark.shield")
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
                
                // Message button expands a bit more when friends
                Button(action: { /* open DM */ }) {
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
                    withAnimation { isFollowing.toggle() }
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
                
                // Añadir Amigo (Primary Main Gradient)
                Button(action: {
                    withAnimation { isFriendRequestSent.toggle() }
                }) {
                    HStack {
                        Image(systemName: isFriendRequestSent ? "person.badge.clock.fill" : "person.badge.plus")
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
                .disabled(isFriendRequestSent)
                
                // Mensaje Icon (only if followers can direct message them natively)
                Button(action: {
                    // Open DM
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
                Text("Tenéis 3 amigos en común")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
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
            StatItem(value: "12", title: "Recomend.")
            Divider().frame(height: 30).padding(.horizontal, 8)
            StatItem(value: "\(user.eventsCount)", title: "Eventos")
            Divider().frame(height: 30).padding(.horizontal, 8)
            StatItem(value: "3", title: "Planes")
            Divider().frame(height: 30).padding(.horizontal, 8)
            StatItem(value: "1.2k", title: "Seguidores")
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
            } else {
                Text("Me encanta descubrir cafeterías escondidas y viajar improvisando.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
            
            // Interests
            VStack(alignment: .leading, spacing: 8) {
                Text("Intereses")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(user.interests.isEmpty ? ["🎉 Fiesta", "🌊 Playa", "☕ Cafés", "📸 Fotografía"] : user.interests, id: \.self) { interest in
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
            let myPosts = postManager.posts.filter { $0.userId == user.id && $0.type != .event }
            if myPosts.isEmpty {
                emptyGlassState(icon: "doc.text", title: "Sin publicaciones", desc: "No hay actividad reciente.")
            } else {
                ForEach(myPosts) { post in
                    PostCardView(post: post)
                }
            }
        }
    }
    
    // MARK: Tab: Eventos
    private var userEventsFeed: some View {
        LazyVStack(spacing: 16) {
            let myEvents = postManager.posts.filter { $0.userId == user.id && $0.type == .event }
            if myEvents.isEmpty {
                emptyGlassState(icon: "calendar", title: "Sin eventos", desc: "Aún no ha organizado ningún evento.")
            } else {
                ForEach(myEvents) { event in
                    PostCardView(post: event)
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
        emptyGlassState(icon: "star", title: "Sin recomendaciones", desc: "No ha compartido ninguna recomendación local.")
    }
    
    private var userFriendsFeed: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { i in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amigo \(i+1)")
                            .font(.headline)
                        Text("📍 Roma • 🇪🇸 España")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
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

// MARK: - Edit Profile View (Placeholder)
struct EditProfileView: View {
    let user: ExtendedUserProfile
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @StateObject private var profileManager = UserProfileManager.shared
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var university: String = ""
    @State private var career: String = ""
    @State private var destination: String = ""
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let photoURL = authManager.currentUser?.photoURL, let url = URL(string: photoURL), !photoURL.isEmpty {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray
                                }
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Cambiar foto")
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                Section("Información Personal") {
                    TextField("Nombre", text: $name)
                    TextField("Biografía", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Erasmus") {
                    TextField("Universidad de Origen", text: $university)
                    TextField("Carrera", text: $career)
                    TextField("Destino", text: $destination)
                }
                
                if isSaving {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Guardando...")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            .onAppear {
                name = user.name
                bio = user.bio ?? ""
                university = user.university
                career = user.career
                destination = user.currentDestination
            }
        }
    }
    
    private func saveChanges() async {
        guard let userId = authManager.currentUser?.id else { return }
        isSaving = true
        
        do {
            if let newImage = selectedImage {
               let _ = try await profileManager.uploadProfileImage(newImage, userId: userId)
            }
            let updates: [String: Any] = [
                "displayName": name,
                "bio": bio,
                "university": university,
                "career": career,
                "destination": destination
            ]
            try await profileManager.updateUserProfile(userId: userId, updates: updates)
            let _ = try await authManager.getUserProfile()
            
            isSaving = false
            dismiss()
        } catch {
            print("Error parsing profile: \(error)")
            isSaving = false
        }
    }
}
