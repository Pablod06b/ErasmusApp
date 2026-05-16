// GroupCreateView.swift
import SwiftUI

struct GroupCreateView: View {
    @StateObject private var groupManager = GroupManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @Environment(\.dismiss) var dismiss

    @State private var groupName = ""
    @State private var selectedType: GroupType = .friends
    @State private var city = ""
    @State private var isCreating = false
    @State private var errorMessage = ""
    @State private var showError = false

    let cities = ["Salamanca", "Madrid", "Barcelona", "Valencia", "Roma", "París", "Berlín", "Lisboa", "Milán", "Ámsterdam", "Praga", "Viena", "Budapest", "Varsovia", "Cracovia"]

    var body: some View {
        NavigationView {
            Form {
                // Group Name
                Section(header: Text("Nombre del grupo")) {
                    TextField("Ej: Los Erasmus de Salamanca", text: $groupName)
                        .autocapitalization(.words)
                }

                // Group Type
                Section(header: Text("Tipo de grupo")) {
                    Picker("Tipo", selection: $selectedType) {
                        ForEach(GroupType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    // Description of selected type
                    Text(selectedType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // City
                Section(header: Text("Ciudad Erasmus")) {
                    if !(authManager.currentUser?.destination.isEmpty ?? true) {
                        // Pre-fill with user's destination
                        HStack {
                            Text(authManager.currentUser?.destination ?? "")
                            Spacer()
                            Text("Tu ciudad")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .onAppear {
                            if city.isEmpty {
                                city = authManager.currentUser?.destination ?? ""
                            }
                        }
                    }
                    Picker("Ciudad", selection: $city) {
                        Text("Selecciona ciudad").tag("")
                        ForEach(cities, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Info Section
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Código de invitación")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Se generará automáticamente un código único para que tus amigos puedan unirse al grupo.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Crear Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: createGroup) {
                        if isCreating {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Crear")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createGroup() {
        let name = groupName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isCreating = true
        let code = generateInviteCode()
        let groupCity = city.isEmpty ? (authManager.currentUser?.destination ?? "") : city

        Task {
            let success = await groupManager.createGroup(
                name: name,
                code: code,
                groupType: selectedType,
                city: groupCity
            )
            await MainActor.run {
                isCreating = false
                if success {
                    dismiss()
                } else {
                    errorMessage = groupManager.error ?? "No se pudo crear el grupo. Inténtalo de nuevo."
                    showError = true
                }
            }
        }
    }

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - GroupType Display Extensions
extension GroupType {
    var displayName: String {
        switch self {
        case .friends: return "Amigos"
        case .flatmates: return "Compañeros de piso"
        case .erasmus: return "Grupo Erasmus"
        case .trip: return "Viaje"
        case .plan: return "Plan"
        }
    }

    var description: String {
        switch self {
        case .friends: return "Grupo de amigos para quedadas y planes"
        case .flatmates: return "Comparte el piso con otros erasmus"
        case .erasmus: return "Grupo general para tu ciudad Erasmus"
        case .trip: return "Organiza un viaje con otros erasmus"
        case .plan: return "Coordina un plan o actividad concreta"
        }
    }
}
