import SwiftUI

struct GroupDetailView: View {
    let group: SocialGroup
    @StateObject private var groupManager = GroupManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    @State private var showLeaveAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 4) {
                            Text("Código:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(group.inviteCode)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Button(action: {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = group.inviteCode
                                #endif
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: { showLeaveAlert = true }) {
                            Label("Abandonar Grupo", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                Picker("Sección", selection: $selectedTab) {
                    Text("Chat").tag(0)
                    Text("Planes").tag(1)
                    Text("Miembros").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            .padding(.bottom)
            .padding(.top, 8)
            .background(Color(UIColor.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 3)
            
            // Content
            TabView(selection: $selectedTab) {
                // Chat Tab
                GroupChatView(group: group)
                .tag(0)
                
                // Calendar Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Próximos Planes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Mock Events
                        ForEach(0..<3) { i in
                            HStack {
                                VStack(alignment: .center) {
                                    Text("JUL")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    Text("\(20 + i)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text("Quedada en Plaza Mayor")
                                        .fontWeight(.semibold)
                                    Text("18:00 - Confirmados: 12")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .tag(1)
                
                // Members Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Miembros del Grupo")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if groupManager.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if groupManager.groupMembers.isEmpty {
                            Text("No hay miembros visibles.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(groupManager.groupMembers) { member in
                                    HStack(spacing: 12) {
                                        if let pUrl = URL(string: member.photoURL) {
                                            AsyncImage(url: pUrl) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Circle().fill(Color.gray.opacity(0.3))
                                            }
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                        } else {
                                            Circle()
                                                .fill(Color.blue.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .overlay(Text(String(member.displayName.prefix(1))).foregroundColor(.blue).fontWeight(.bold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            if !member.university.isEmpty {
                                                Text(member.university)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .task {
            // Avoid refetching if already loaded to persist state smoothly, though refreshing is fine
            groupManager.currentGroup = group
            await groupManager.fetchMembers()
        }
        .alert("Abandonar Grupo", isPresented: $showLeaveAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Abandonar", role: .destructive) {
                Task {
                    if await groupManager.leaveGroup() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("¿Estás seguro de que quieres salir de \(group.name)? Tendrás que usar un código para volver a entrar.")
        }
        .alert("Error", isPresented: .constant(groupManager.error != nil)) {
            Button("OK") { groupManager.error = nil }
        } message: {
            Text(groupManager.error ?? "")
        }
    }
}
