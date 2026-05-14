// FavoritesView.swift
import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var selectedTab: FavoritesTab = .todos

    enum FavoritesTab: String, CaseIterable {
        case todos = "Todos"
        case publicaciones = "Posts"
        case ciudades = "Ciudades"
        case personas = "Personas"

        var icon: String {
            switch self {
            case .todos: return "bookmark.fill"
            case .publicaciones: return "doc.text.fill"
            case .ciudades: return "globe.europe.africa.fill"
            case .personas: return "person.2.fill"
            }
        }
    }

    var filteredItems: [SavedItem] {
        switch selectedTab {
        case .todos:
            return favoritesManager.savedItems
        case .publicaciones:
            return favoritesManager.savedItems.filter { $0.type == .post || $0.type == .event }
        case .ciudades:
            return favoritesManager.savedItems.filter { $0.type == .city }
        case .personas:
            return favoritesManager.savedItems.filter { $0.type == .user }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector
                tabSelector
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                FavoriteItemRow(item: item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Guardados")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let userId = authManager.currentUser?.id {
                    favoritesManager.loadFavorites(for: userId)
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FavoritesTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon).font(.caption)
                            Text(tab.rawValue).font(.subheadline).fontWeight(.semibold)
                            if tab != .todos {
                                let count = favoritesManager.savedItems.filter {
                                    switch tab {
                                    case .publicaciones: return $0.type == .post || $0.type == .event
                                    case .ciudades: return $0.type == .city
                                    case .personas: return $0.type == .user
                                    default: return false
                                    }
                                }.count
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedTab == tab ? .white.opacity(0.9) : .secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(selectedTab == tab ? Color.white.opacity(0.25) : Color.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            selectedTab == tab ?
                            AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                            AnyShapeStyle(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            Text("Nada guardado aún")
                .font(.title2)
                .fontWeight(.bold)
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .todos: return "Guarda publicaciones, ciudades y personas para encontrarlas fácilmente."
        case .publicaciones: return "Guarda publicaciones o eventos tocando el icono de marcador."
        case .ciudades: return "Guarda ciudades Erasmus para compararlas más tarde."
        case .personas: return "Guarda perfiles de otros erasmus que te interesen."
        }
    }
}

// MARK: - Favorite Item Row

struct FavoriteItemRow: View {
    let item: SavedItem
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        HStack(spacing: 14) {
            // Icon / Thumbnail
            typeIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    typeLabel
                    Spacer()
                    Text(item.savedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Remove Button
            Button(action: {
                Task { await removeItem() }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    private var typeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconBackground)
                .frame(width: 50, height: 50)
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
        }
    }

    private var typeLabel: some View {
        Text(typeLabelText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(iconBackground)
            .foregroundColor(iconColor)
            .cornerRadius(6)
    }

    private var iconName: String {
        switch item.type {
        case .post: return "doc.text.fill"
        case .event: return "calendar.badge.plus"
        case .city: return "globe.europe.africa.fill"
        case .user: return "person.fill"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .post: return .blue
        case .event: return .purple
        case .city: return .orange
        case .user: return .green
        }
    }

    private var iconBackground: Color {
        iconColor.opacity(0.12)
    }

    private var typeLabelText: String {
        switch item.type {
        case .post: return "Publicación"
        case .event: return "Evento"
        case .city: return "Ciudad"
        case .user: return "Persona"
        }
    }

    private func removeItem() async {
        // Remove based on type
        switch item.type {
        case .city:
            let cities = CityInfo.sampleCities.filter { $0.name == item.itemId }
            if let city = cities.first { await favoritesManager.toggleCity(city) }
        default:
            break
        }
    }
}
