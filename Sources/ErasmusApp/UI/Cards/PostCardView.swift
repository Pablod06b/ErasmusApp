import SwiftUI

struct PostCardView: View {
    let post: ErasmusPost
    @State private var isLiked = false
    @State private var scale: CGFloat = 1.0
    @State private var showReportAlert = false
    @State private var showDetail = false
    @StateObject private var favoritesManager = FavoritesManager.shared

    private var isSaved: Bool { favoritesManager.isPostSaved(post.id.uuidString) }

    var body: some View {
        NavigationLink(destination: destinationView) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Contenido reportado", isPresented: $showReportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Gracias. Hemos recibido tu reporte y revisaremos esta publicación lo antes posible.")
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if post.type == .personalPlan || post.type == .openMessage {
            OpenPlanDetailView(post: post)
        } else {
            PostDetailView(post: post)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Type badge
                Text(post.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(colors: typeGradient(post.type), startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                Spacer()

                // Bookmark (Save) Button
                Button(action: { Task { await favoritesManager.togglePost(post) } }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isSaved ? .blue : .secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())

                // Like Button
                Button(action: {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isLiked.toggle()
                        scale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { scale = 1.0 }
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                        .scaleEffect(scale)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Title
            Text(post.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Description
            Text(post.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Rating (For Recommendations)
            if let rating = post.rating {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < rating ? "star.fill" : "star")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    Text("Recomendado")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            // Participants Needed (For Open Plans)
            if let needed = post.participantsNeeded {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("Se buscan \(needed) personas")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Image
            #if canImport(UIKit)
            if let imageName = post.imageName {
                if imageName.starts(with: "http"), let url = URL(string: imageName) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(12)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else if let image = FileManager.loadImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // Fallback for missing local image on iOS
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            } else {
                // Return nothing or an empty view if there is no image name
            }
            #else
            // Fallback for macOS
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .cornerRadius(12)
                .overlay(Text("Imagen no disponible").font(.caption))
            #endif
            
            // Footer
            HStack {
                // Location
                if let location = post.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Date
                if let date = post.date {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(date, style: .date)
                            .font(.caption)
                    }
                }
            }
            
            // Map View (If location exists)
            if let location = post.location {
                LocationMapView(locationName: location)
                    .frame(height: 120)
                    .cornerRadius(12)
                    .allowsHitTesting(false)
                    .padding(.top, 4)
            }
            
            // Price
            if let price = post.price, post.isPaid == true {
                HStack {
                    Image(systemName: "eurosign.circle.fill")
                        .foregroundColor(.green)
                    Text("\(String(format: "%.2f", price)) €")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
            
            // Open Plan Join CTA
            if post.type == .personalPlan || post.type == .openMessage {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.purple)
                    Text("Ver plan y apuntarte")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(10)
            }

            // Action button (events with signup)
            if post.allowSignups == true && post.type == .event {
                SignUpButton(post: post)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .contextMenu {
            Button(action: { Task { await favoritesManager.togglePost(post) } }) {
                Label(isSaved ? "Quitar de guardados" : "Guardar", systemImage: isSaved ? "bookmark.slash" : "bookmark.fill")
            }
            Divider()
            Button(role: .destructive) {
                showReportAlert = true
            } label: {
                Label("Reportar contenido", systemImage: "exclamationmark.bubble")
            }
        }
    }

    // MARK: - Gradient by type
    private func typeGradient(_ type: PostType) -> [Color] {
        switch type {
        case .event: return [.purple, .indigo]
        case .housing: return [.teal, .blue]
        case .recommendation: return [.orange, .red]
        case .announcement: return [.blue, .cyan]
        case .personalPlan: return [.green, .teal]
        case .openMessage: return [.pink, .purple]
        }
    }
}

// MARK: - Sign Up Button Component
struct SignUpButton: View {
    let post: ErasmusPost
    @State private var isSignedUp = false
    @State private var showPaymentSheet = false
    @State private var showConfirmation = false
    
    var body: some View {
        Button(action: {
            if post.isPaid == true && !isSignedUp {
                showPaymentSheet = true
            } else if !isSignedUp {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSignedUp = true
                    showConfirmation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showConfirmation = false
                }
            }
        }) {
            HStack {
                Image(systemName: isSignedUp ? "checkmark.circle.fill" : "hand.raised.fill")
                Text(isSignedUp ? "Apuntado" : "Me apunto")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: isSignedUp ? [.green, .green] : [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .scaleEffect(isSignedUp ? 1.05 : 1.0)
        }
        .disabled(isSignedUp)
        .sheet(isPresented: $showPaymentSheet) {
            ApplePayView(post: post) { success in
                if success {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSignedUp = true
                        showConfirmation = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showConfirmation = false
                    }
                }
            }
        }
        .overlay(
            Group {
                if showConfirmation {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("¡Estás dentro!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
}

// MARK: - Apple Pay View
struct ApplePayView: View {
    let post: ErasmusPost
    let onPaymentComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Pago requerido")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(post.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    if let price = post.price {
                        Text("\(String(format: "%.2f", price)) €")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        processPayment()
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "apple.logo")
                                Text("Pagar con Apple Pay")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .navigationTitle("Pago")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func processPayment() {
        isProcessing = true
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            onPaymentComplete(true)
            dismiss()
        }
    }
}
