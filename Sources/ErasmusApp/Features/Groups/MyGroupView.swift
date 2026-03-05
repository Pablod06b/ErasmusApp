import SwiftUI

struct MyGroupView: View {
    @StateObject private var groupManager = GroupManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if groupManager.isLoading && groupManager.currentGroup == nil {
                    ProgressView("Cargando tu grupo...")
                } else if let group = groupManager.currentGroup {
                    // User has a group, show the detail view
                    GroupDetailView(group: group)
                } else {
                    // User has no group
                    noGroupView
                }
            }
            .navigationTitle(groupManager.currentGroup != nil ? "" : "Mis Grupos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    await groupManager.fetchUserGroup()
                }
            }
            .sheet(isPresented: $showJoinSheet) {
                GroupJoinView()
            }
            .sheet(isPresented: $showCreateSheet) {
                GroupCreateView()
            }
        }
    }
    
    private var noGroupView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text("Aún no tienes grupo")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Crea un grupo privado con tus amigos o únete a uno existente usando un código de invitación.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                Button(action: { showCreateSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Crear un grupo nuevo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                }
                
                Button(action: { showJoinSheet = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Unirme con un código")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

struct GroupCreateView: View {
    @StateObject private var groupManager = GroupManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var groupName = ""
    @State private var generatedCode = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(spacing: 8) {
                    Text("Crear Grupo")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Dale un nombre a tu grupo y comparte el código con tus amigos.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                TextField("Nombre del grupo", text: $groupName)
                    .font(.title3)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                if !generatedCode.isEmpty {
                    VStack(spacing: 8) {
                        Text("Código de Invitación:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(generatedCode)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .tracking(5)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                if let error = groupManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: handleCreate) {
                    if groupManager.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(generatedCode.isEmpty ? "Crear Grupo" : "Finalizar")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(groupName.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(groupName.isEmpty || groupManager.isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Nuevo Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if generatedCode.isEmpty {
                    generatedCode = String((0..<5).map{ _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func handleCreate() {
        Task {
            if await GroupManager.shared.createGroup(name: groupName, code: generatedCode) {
                dismiss()
            }
        }
    }
}
