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
                    Text("Organización").tag(1)
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

                // Organization Tab (Tasks + Calendar + Members + Invite)
                GroupFeaturesView()
                    .tag(1)
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
