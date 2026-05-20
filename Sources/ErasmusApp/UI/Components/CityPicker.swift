// CityPicker.swift — selector unificado con ciudades activas y "Próximamente"
import SwiftUI

/// Selector de ciudad estándar. Solo deja seleccionar las activas; al pulsar
/// una "Próximamente" abre el modal de avisame-cuando-llegue.
struct CityPicker: View {
    @Binding var selected: String
    var label: String = "Destino"

    @State private var showSheet = false
    @State private var pendingComingSoon: AppCity? = nil

    var body: some View {
        Button(action: { showSheet = true }) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(selected.isEmpty ? label : selected)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showSheet) {
            CityPickerSheet(selected: $selected) { city in
                if city.isAvailable {
                    selected = city.name
                    showSheet = false
                } else {
                    pendingComingSoon = city
                }
            }
        }
        .sheet(item: $pendingComingSoon) { city in
            CityComingSoonView(city: city)
        }
    }
}

struct CityPickerSheet: View {
    @Binding var selected: String
    var onSelect: (AppCity) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Disponibles ahora")) {
                    ForEach(AvailableCities.active) { city in
                        cityRow(city)
                    }
                }
                Section(header: Text("Próximamente")) {
                    ForEach(AvailableCities.comingSoon) { city in
                        cityRow(city)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Elige tu destino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func cityRow(_ city: AppCity) -> some View {
        Button(action: { onSelect(city) }) {
            HStack(spacing: 12) {
                Text(city.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(city.name)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if !city.isAvailable {
                            Text("Próximamente")
                                .font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.orange.opacity(0.18))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Text(city.country)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if city.isAvailable && selected == city.name {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else if !city.isAvailable {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.orange.opacity(0.7))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            .opacity(city.isAvailable ? 1.0 : 0.85)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Banner permanente "Solo Salamanca/Madrid"
struct CitiesLimitedBanner: View {
    @State private var showSheet = false

    var body: some View {
        Button(action: { showSheet = true }) {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Solo en Salamanca y Madrid")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Toca aquí para apuntar tu ciudad")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showSheet) {
            CityPickerSheet(selected: .constant("")) { city in
                if !city.isAvailable {
                    showSheet = false
                    // Reabrir como CityComingSoonView no es trivial desde aquí;
                    // El usuario puede usar el picker del header normalmente para apuntarse.
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await CityRequestManager.shared.subscribe(toCity: city.name)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CityPicker(selected: .constant("Salamanca"))
        CitiesLimitedBanner()
    }
    .padding()
}
