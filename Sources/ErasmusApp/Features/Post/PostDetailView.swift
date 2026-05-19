// PostDetailView.swift
import SwiftUI
import MapKit
import FirebaseFirestore

struct PostDetailView: View {
    let post: ErasmusPost
    @EnvironmentObject var authManager: FirebaseAuthManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var postManager = PostManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var comments: [PostComment] = []
    @State private var newComment = ""
    @State private var isLiked = false
    @State private var likesCount = 0
    @State private var isLiking = false
    @State private var showShareSheet = false
    @State private var showReportAlert = false

    private var isSaved: Bool { favoritesManager.isPostSaved(post.id.uuidString) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero
                    heroSection

                    VStack(alignment: .leading, spacing: 20) {
                        // Action Bar
                        actionBar

                        Divider()

                        // Type-specific content
                        typeSpecificContent

                        Divider()

                        // Meta info
                        metaSection

                        Divider()

                        // Comments
                        commentsSection
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .overlay(alignment: .top) { navBar }
            .overlay(alignment: .bottom) { commentInputBar }
            .alert("Reportar publicación", isPresented: $showReportAlert) {
                Button("Reportar", role: .destructive) {
                    Task { await reportPost() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Quieres reportar esta publicación? Nuestro equipo la revisará.")
            }
            .onAppear {
                Task {
                    let userId = authManager.currentUser?.id ?? ""
                    let (liked, count) = await postManager.fetchLikeStatus(
                        postId: post.id.uuidString, userId: userId
                    )
                    isLiked = liked
                    likesCount = count
                    comments = await postManager.fetchComments(postId: post.id.uuidString)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageName = post.imageName, !imageName.isEmpty {
                    if let url = URL(string: imageName) {
                        AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                            placeholder: { postGradient }
                    } else if UIImage(named: imageName) != nil {
                        Image(imageName).resizable().scaledToFill()
                    } else {
                        postGradient
                    }
                } else {
                    postGradient
                }
            }
            .frame(height: 300)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                postTypeBadge
                Text(post.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                if let location = post.location {
                    Label(location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(20)
        }
    }

    private var postGradient: some View {
        LinearGradient(
            colors: gradientForType(post.type),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var postTypeBadge: some View {
        Text(post.type.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.25))
            .cornerRadius(10)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 20) {
            // Like
            Button(action: {
                guard !isLiking, let userId = authManager.currentUser?.id else { return }
                isLiking = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isLiked.toggle()
                    likesCount += isLiked ? 1 : -1
                }
                Task {
                    await postManager.toggleLike(postId: post.id.uuidString, userId: userId)
                    isLiking = false
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                        .scaleEffect(isLiked ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
                    Text("\(likesCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLiking)

            // Comment
            HStack(spacing: 6) {
                Image(systemName: "bubble.right").foregroundColor(.secondary)
                Text("\(comments.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Save
            Button(action: { Task { await favoritesManager.togglePost(post) } }) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isSaved ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Share
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .font(.title3)
    }

    // MARK: - Type-specific content

    @ViewBuilder
    private var typeSpecificContent: some View {
        switch post.type {
        case .event:
            eventDetailsSection
        case .personalPlan, .openMessage:
            openPlanSection
        case .recommendation:
            recommendationSection
        case .housing:
            housingDetailsSection
        case .announcement:
            announcementDetailsSection
        }
    }

    // Event details
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let date = post.date {
                InfoRow(icon: "calendar", label: "Fecha", value: date.formatted(date: .complete, time: .shortened))
            }
            if let location = post.location {
                InfoRow(icon: "mappin.circle.fill", label: "Lugar", value: location)
            }
            if let isPaid = post.isPaid, isPaid, let price = post.price {
                InfoRow(icon: "eurosign.circle.fill", label: "Precio", value: String(format: "%.2f€", price))
            } else {
                InfoRow(icon: "gift.fill", label: "Precio", value: "Gratis")
            }
            if let participants = post.participantsNeeded {
                InfoRow(icon: "person.3.fill", label: "Plazas", value: "\(participants) máximo")
            }
        }
    }

    // Open Plan section with join button
    private var openPlanSection: some View {
        NavigationLink(destination: OpenPlanDetailView(post: post)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ver plan completo")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Únete y chatea con los participantes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(Color.blue.opacity(0.07))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Recommendation
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let rating = post.rating {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.orange)
                    }
                    Text("(\(rating)/5)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            if let location = post.location {
                InfoRow(icon: "mappin.circle.fill", label: "Dirección", value: location)
            }
            if let category = post.category {
                InfoRow(icon: "tag.fill", label: "Categoría", value: category)
            }
        }
    }

    // Housing
    private var housingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let price = post.price {
                InfoRow(icon: "eurosign.circle.fill", label: "Precio", value: String(format: "%.0f€/mes", price))
            }
            if let location = post.location {
                InfoRow(icon: "mappin.circle.fill", label: "Zona", value: location)
            }
            if let contact = post.contact {
                InfoRow(icon: "phone.fill", label: "Contacto", value: contact)
            }
        }
    }

    // Announcement
    private var announcementDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let price = post.price {
                InfoRow(icon: "tag.fill", label: "Precio", value: String(format: "%.2f€", price))
            }
            if let contact = post.contact {
                InfoRow(icon: "envelope.fill", label: "Contacto", value: contact)
            }
        }
    }

    // MARK: - Meta

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Descripción")
                .font(.headline)
                .fontWeight(.bold)

            Text(post.description.isEmpty ? "Sin descripción." : post.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)

            // Destination tag
            HStack {
                Label(post.destination, systemImage: "location.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
                Text(post.visibility.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Comentarios (\(comments.count))")
                .font(.headline)
                .fontWeight(.bold)

            if comments.isEmpty {
                Text("Sé el primero en comentar 💬")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment)
                    }
                }
            }
        }
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 34, height: 34)
                    .overlay(Image(systemName: "person.fill").font(.caption).foregroundColor(.gray))

                TextField("Comenta algo...", text: $newComment)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(22)

                Button(action: submitComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newComment.isEmpty ? .gray : .blue)
                }
                .disabled(newComment.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.4))
            }
            Spacer()
            Menu {
                Button(action: { Task { await favoritesManager.togglePost(post) } }) {
                    Label(isSaved ? "Quitar de guardados" : "Guardar", systemImage: isSaved ? "bookmark.slash" : "bookmark.fill")
                }
                Button(action: { showShareSheet = true }) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive, action: { showReportAlert = true }) {
                    Label("Reportar", systemImage: "exclamationmark.shield")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, safeAreaTop)
    }

    private var safeAreaTop: CGFloat {
        #if canImport(UIKit)
        guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 50 }
        return ws.windows.first?.safeAreaInsets.top ?? 50
        #else
        return 50
        #endif
    }

    // MARK: - Helpers

    private func gradientForType(_ type: PostType) -> [Color] {
        switch type {
        case .event: return [.purple, .indigo]
        case .housing: return [.teal, .blue]
        case .recommendation: return [.orange, .red]
        case .announcement: return [.blue, .teal]
        case .personalPlan: return [.green, .teal]
        case .openMessage: return [.pink, .purple]
        }
    }

    private func reportPost() async {
        let db = Firestore.firestore()
        let reporterId = authManager.currentUser?.id ?? "anonymous"
        let postId = post.id.uuidString

        // Mark the post itself as reported
        try? await db.collection("posts").document(postId)
            .updateData(["isReported": true])

        // Store a report document for moderation
        let reportData: [String: Any] = [
            "postId": postId,
            "reporterId": reporterId,
            "postTitle": post.title,
            "postUserId": post.userId,
            "createdAt": Timestamp(date: Date())
        ]
        try? await db.collection("reports").addDocument(data: reportData)
    }

    private func submitComment() {
        guard let user = authManager.currentUser, !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        let comment = PostComment(
            postId: post.id.uuidString,
            userId: user.id,
            userName: user.displayName,
            userPhotoURL: user.photoURL.isEmpty ? nil : user.photoURL,
            content: trimmed,
            createdAt: Date()
        )
        // Optimistic update
        comments.append(comment)
        newComment = ""
        // Persist to Firebase
        Task {
            await postManager.addComment(postId: post.id.uuidString, comment: comment)
        }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: PostComment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            UserAvatarView(photoURL: nil, name: comment.userName, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(3)

                HStack(spacing: 14) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart").font(.caption)
                            Text("\(comment.likes)").font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    Button(action: {}) {
                        Text("Responder").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
