import SwiftUI

struct EventCardView: View {
    let evento: Evento
    @State private var isLiked = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with Overlay
            ZStack(alignment: .topTrailing) {
                if let imageURL = evento.imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill().frame(height: 140).clipped()
                        default:
                            eventImagePlaceholder
                        }
                    }
                } else if !evento.imageName.isEmpty, UIImage(systemName: evento.imageName) != nil {
                    ZStack {
                        LinearGradient(colors: [.orange.opacity(0.7), .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 140)
                        Image(systemName: evento.imageName)
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    eventImagePlaceholder
                }
                
                // Date Badge
                VStack(spacing: 0) {
                    if let dateDate = ISO8601DateFormatter().date(from: evento.date) {
                        Text(dateDate.formatted(.dateTime.month()))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text(dateDate.formatted(.dateTime.day()))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    } else {
                        // Fallback using the string directly if it's "12 OCT" style or unparseable
                        // Assuming the string might be simple like "12/10/2025" or we just show a calendar icon
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
                .background(Color(UIColor.systemBackground).opacity(0.9))
                .cornerRadius(12)
                .padding(12)
                
                // Like Button (Overlay)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isLiked.toggle()
                        scale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { scale = 1.0 }
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                        .scaleEffect(scale)
                }
                .padding(12)
                .offset(y: 100) // Position near bottom right of image
            }
            .background(Color.gray.opacity(0.1))
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Business verified badge
                    if evento.isVerifiedBusiness == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption2)
                            Text("Oficial")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    // Promoted badge
                    if evento.isPromoted == true {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                            Text("Destacado")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                    Spacer()
                    if let price = evento.price {
                        Text(price > 0 ? "\(String(format: "%.0f", price))€" : "Gratis")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                HStack {
                    Text(evento.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(evento.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                }
            }
            .padding(12)
            
            // Map View
            LocationMapView(locationName: evento.location)
                .frame(height: 120)
                .cornerRadius(12)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .allowsHitTesting(false) // Disable interaction on the card level to keep it as a mini-map
            
            EventSignUpButton(evento: evento)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var eventImagePlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 140)
            .overlay(
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

// MARK: - Event Sign Up Button
struct EventSignUpButton: View {
    let evento: Evento
    @State private var isSignedUp = false
    @State private var showConfirmation = false
    
    var body: some View {
        Button(action: {
            if !isSignedUp {
                #if os(iOS)
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
                #endif
                
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
