// OpenPlanDetailView.swift
import SwiftUI

struct OpenPlanDetailView: View {
    let post: ErasmusPost
    @EnvironmentObject var authManager: FirebaseAuthManager
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var participants: [PlanParticipant] = []
    @State private var isJoined = false
    @State private var isLoading = false
    @State private var chatMessage = ""
    @State private var chatMessages: [PlanChatMessage] = []
    @State private var showParticipants = false

    private var currentUserId: String? { authManager.currentUser?.id }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Image
                    heroSection

                    VStack(alignment: .leading, spacing: 20) {
                        // Title & Meta
                        headerSection

                        Divider()

                        // Participants
                        participantsSection

                        Divider()

                        // Description
                        if !post.description.isEmpty {
                            descriptionSection
                            Divider()
                        }

                        // Mini Chat
                        miniChatSection
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) { joinBar }
            .overlay(alignment: .top) { navBar }
            .task { await loadData() }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageName = post.imageName, !imageName.isEmpty,
                   let url = URL(string: imageName) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                        placeholder: { planGradient }
                } else {
                    planGradient
                }
            }
            .frame(height: 260)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                typeBadge
                Text(post.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(20)
        }
    }

    private var planGradient: some View {
        LinearGradient(
            colors: [.blue.opacity(0.8), .purple.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var typeBadge: some View {
        Text(post.type.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.25))
            .cornerRadius(8)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date & Location
            HStack(spacing: 16) {
                if let date = post.date {
                    Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let location = post.location {
                    Label(location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Participants count + limit
            HStack {
                HStack(spacing: -8) {
                    ForEach(participants.prefix(5)) { participant in
                        AsyncImage(url: URL(string: participant.userPhotoURL ?? "https://picsum.photos/40/40?random=\(participant.userId.prefix(6))")) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                    }
                }

                Text("\(participants.count) apuntados")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let max = post.participantsNeeded {
                    Text("de \(max) máx.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if participants.count >= max {
                        Text("Completo")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(8)
                    } else {
                        let remaining = max - participants.count
                        Text("\(remaining) plazas libres")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    // MARK: - Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showParticipants.toggle() }) {
                HStack {
                    Text("Participantes")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showParticipants ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if showParticipants {
                LazyVStack(spacing: 10) {
                    ForEach(participants) { participant in
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: participant.userPhotoURL ?? "https://picsum.photos/40/40?random=\(participant.userId.prefix(6))")) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(participant.userName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Se apuntó \(participant.joinedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()

                            if participant.userId == currentUserId {
                                Text("Tú")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sobre el plan")
                .font(.headline)
                .fontWeight(.bold)
            Text(post.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Mini Chat

    private var miniChatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chat del plan")
                .font(.headline)
                .fontWeight(.bold)

            if chatMessages.isEmpty {
                Text("Sé el primero en escribir algo 👋")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(chatMessages) { msg in
                        PlanChatBubble(message: msg, isOwn: msg.userId == currentUserId)
                    }
                }
            }

            // Message input (only if joined)
            if isJoined {
                HStack(spacing: 10) {
                    TextField("Escribe algo...", text: $chatMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(22)

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(chatMessage.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(chatMessage.isEmpty)
                }
            } else {
                Text("Únete al plan para participar en el chat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Join Bar (Bottom)

    private var joinBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isJoined ? "Estás apuntado" : "¿Te apuntas?")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    if let max = post.participantsNeeded {
                        Text("\(participants.count)/\(max) participantes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: toggleJoin) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: isJoined ? "checkmark.circle.fill" : "plus.circle.fill")
                        }
                        Text(isJoined ? "Apuntado" : "Apuntarme")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        isJoined ?
                        AnyShapeStyle(Color.green) :
                        AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    )
                    .cornerRadius(24)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading || (post.participantsNeeded != nil && !isJoined && participants.count >= (post.participantsNeeded ?? 0)))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
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
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up.circle.fill")
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

    // MARK: - Actions

    private func loadData() async {
        participants = await socialManager.fetchPlanParticipants(postId: post.id.uuidString)
        isJoined = participants.contains { $0.userId == (currentUserId ?? "") }
    }

    private func toggleJoin() {
        Task {
            isLoading = true
            do {
                if isJoined {
                    try await socialManager.leavePlan(postId: post.id.uuidString)
                } else {
                    try await socialManager.joinPlan(postId: post.id.uuidString)
                }
                await loadData()
            } catch {
                print("Error toggling plan: \(error)")
            }
            isLoading = false
        }
    }

    private func sendMessage() {
        guard let userId = currentUserId, let name = authManager.currentUser?.displayName else { return }
        let msg = PlanChatMessage(
            userId: userId,
            userName: name,
            content: chatMessage,
            createdAt: Date()
        )
        chatMessages.append(msg)
        chatMessage = ""
    }
}

// MARK: - Plan Chat Bubble

struct PlanChatBubble: View {
    let message: PlanChatMessage
    let isOwn: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOwn { Spacer() }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 3) {
                if !isOwn {
                    Text(message.userName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isOwn ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(isOwn ? .white : .primary)
                    .cornerRadius(18)

                Text(message.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isOwn { Spacer() }
        }
    }
}
