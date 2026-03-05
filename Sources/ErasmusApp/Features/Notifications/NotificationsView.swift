import SwiftUI

struct NotificationsView: View {
    @StateObject private var manager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(manager.notifications) { notification in
                    HStack(spacing: 16) {
                        Image(systemName: notification.type.rawValue)
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(notification.message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            Text(notification.date.formatted(.relative(presentation: .named)))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hecho") {
                        dismiss()
                    }
                }
            }
        }
    }
}
