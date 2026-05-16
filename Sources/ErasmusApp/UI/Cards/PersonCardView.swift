// PersonCardView.swift
import SwiftUI

struct PersonCardView: View {
    let profile: UserProfile
    @EnvironmentObject var authManager: FirebaseAuthManager

    var body: some View {
        NavigationLink(destination: UserProfileView(userToDisplay: profile.toExtendedUserProfile())
            .environmentObject(authManager)) {
            VStack(alignment: .leading, spacing: 12) {
                // Profile image
                Group {
                    if !profile.photoURL.isEmpty, let url = URL(string: profile.photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: personPlaceholder
                            }
                        }
                    } else {
                        personPlaceholder
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    // Name + verified badge
                    HStack(spacing: 6) {
                        Text(profile.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if profile.accountType == .business {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }

                    // Destination
                    if !profile.destination.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(profile.destination)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Common interests count (based on matching interests)
                    if !profile.interests.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.pink)
                            Text("\(profile.interests.count) intereses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // CTA Button
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Ver perfil")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var personPlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
            )
    }
}

// MARK: - Legacy PerfilView (kept for compatibility)
struct PerfilView: View {
    let persona: Persona

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .foregroundColor(.blue)
            Text(persona.name)
                .font(.largeTitle)
            Text("🎯 Intereses en común: \(persona.commonInterests)")
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
        .navigationTitle("Perfil")
    }
}
