// DestinationExplorerView.swift
import SwiftUI

struct DestinationExplorerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared

    @State private var searchText = ""
    @State private var selectedCostFilter: CityInfo.CostLevel? = nil
    @State private var selectedSortBy: SortOption = .popular
    @State private var selectedCity: CityInfo? = nil
    @State private var showCityDetail = false

    enum SortOption: String, CaseIterable {
        case popular = "Populares"
        case cheapest = "Más baratas"
        case party = "Más fiesta"
        case culture = "Más cultura"
        case safety = "Más seguras"
    }

    var filteredCities: [CityInfo] {
        var cities = CityInfo.sampleCities

        if !searchText.isEmpty {
            cities = cities.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.country.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let cost = selectedCostFilter {
            cities = cities.filter { $0.costOfLiving == cost }
        }

        switch selectedSortBy {
        case .popular:
            cities = cities.sorted { $0.studentPopulation > $1.studentPopulation }
        case .cheapest:
            let order: [CityInfo.CostLevel] = [.low, .medium, .high, .veryHigh]
            cities = cities.sorted { (order.firstIndex(of: $0.costOfLiving) ?? 0) < (order.firstIndex(of: $1.costOfLiving) ?? 0) }
        case .party:
            cities = cities.sorted { $0.partyScene > $1.partyScene }
        case .culture:
            cities = cities.sorted { $0.cultureScore > $1.cultureScore }
        case .safety:
            cities = cities.sorted { $0.safetyScore > $1.safetyScore }
        }

        return cities
    }

    var savedCities: [CityInfo] {
        CityInfo.sampleCities.filter { favoritesManager.isCitySaved($0.name) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Banner
                    heroBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Saved Destinations (if any)
                    if !savedCities.isEmpty {
                        savedCitiesSection
                            .padding(.horizontal, 16)
                    }

                    // Filters
                    filtersSection

                    // Cities Grid
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(filteredCities.count) destinos encontrados")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 16)
                            Spacer()
                        }

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 14
                        ) {
                            ForEach(filteredCities) { city in
                                NavigationLink(destination: CityGuideView(city: city)) {
                                    DestinationCityCard(city: city)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 60)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Explorador de Destinos")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar ciudad o país...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.8), .purple.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 130)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("¿Aún no tienes destino?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Explora las \(CityInfo.sampleCities.count) ciudades Erasmus más populares y elige la tuya.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(3)
                }
                Spacer()
                Image(systemName: "map.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(20)
        }
    }

    // MARK: - Saved Cities Section

    private var savedCitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bookmark.fill").foregroundColor(.blue)
                Text("Mis destinos guardados")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(savedCities.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.blue)
                    .clipShape(Circle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(savedCities) { city in
                        NavigationLink(destination: CityGuideView(city: city)) {
                            HStack(spacing: 8) {
                                Text(city.countryFlag)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(city.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(city.country)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Sort options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        FilterChip(label: option.rawValue, isSelected: selectedSortBy == option) {
                            selectedSortBy = option
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Cost filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "Todos los precios", isSelected: selectedCostFilter == nil) {
                        selectedCostFilter = nil
                    }
                    ForEach([CityInfo.CostLevel.low, .medium, .high], id: \.self) { level in
                        FilterChip(label: "\(level.icon) \(level.rawValue)", isSelected: selectedCostFilter == level) {
                            selectedCostFilter = selectedCostFilter == level ? nil : level
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Destination City Card (Larger, richer version)

struct DestinationCityCard: View {
    let city: CityInfo
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Group {
                if city.coverImageName != "default_image",
                   UIImage(named: city.coverImageName) != nil {
                    Image(city.coverImageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: gradientColors(for: city.id),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 190)
            .clipped()

            // Overlay gradient
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(city.countryFlag).font(.title2)
                    Spacer()
                    Button(action: { Task { await favoritesManager.toggleCity(city) } }) {
                        Image(systemName: favoritesManager.isCitySaved(city.name) ? "bookmark.fill" : "bookmark")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text(city.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Score Pills
                HStack(spacing: 4) {
                    ScorePill(value: city.costOfLiving.icon, label: "Precio")
                    ScorePill(value: "🎉\(city.partyScene)", label: "Fiesta")
                    ScorePill(value: "🛡️\(city.safetyScore)", label: "Seg.")
                }
            }
            .padding(10)
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .clipped()
    }

    func gradientColors(for id: String) -> [Color] {
        let gradients: [[Color]] = [
            [.blue, .purple], [.orange, .red], [.green, .teal],
            [.pink, .purple], [.indigo, .blue], [.teal, .green],
            [.red, .orange], [.purple, .pink]
        ]
        return gradients[((id.hashValue % gradients.count) + gradients.count) % gradients.count]
    }
}

struct ScorePill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.2))
        .cornerRadius(6)
    }
}
