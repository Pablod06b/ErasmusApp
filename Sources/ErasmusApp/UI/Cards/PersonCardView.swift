// Views/PersonCardView.swift
import SwiftUI

struct PersonCardView: View {
    let persona: Persona

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile image with modern styling
            AsyncImage(url: URL(string: "https://picsum.photos/300/300?random=\(persona.id)")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                // Name and age
                Text(persona.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Common interests
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                    Text("\(persona.commonInterests) intereses en común")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Action button
                NavigationLink(destination: PerfilView(persona: persona)) {
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct PerfilView: View {
    let persona: Persona

    var body: some View {
        VStack(spacing: 20) {
            Image(persona.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .cornerRadius(16)
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
