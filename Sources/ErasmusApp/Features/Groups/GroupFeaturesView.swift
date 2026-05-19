// GroupFeaturesView.swift
import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Group Features Main View (Calendar + Tasks + QR)

struct GroupFeaturesView: View {
    @StateObject private var groupManager = GroupManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var selectedTab: GroupFeatureTab = .tasks
    @State private var showAddTask = false
    @State private var showAddEvent = false
    @State private var showQRCode = false
    @State private var newTaskTitle = ""
    @State private var newEventTitle = ""
    @State private var newEventDate = Date()
    @State private var newEventDesc = ""

    enum GroupFeatureTab: String, CaseIterable {
        case tasks = "Tareas"
        case calendar = "Calendario"
        case members = "Miembros"
        case invite = "Invitar"

        var icon: String {
            switch self {
            case .tasks: return "checkmark.square.fill"
            case .calendar: return "calendar"
            case .members: return "person.3.fill"
            case .invite: return "qrcode"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GroupFeatureTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon).font(.caption)
                                Text(tab.rawValue).font(.subheadline).fontWeight(.semibold)
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
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 10)

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .tasks:
                        tasksView
                    case .calendar:
                        calendarView
                    case .members:
                        membersView
                    case .invite:
                        inviteView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
            }
        }
    }

    // MARK: - Tasks

    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Lista de tareas")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showAddTask = true }) {
                    Label("Añadir", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            if groupManager.currentGroup?.tasks.isEmpty ?? true {
                EmptyFeatureState(
                    icon: "checkmark.square",
                    title: "Sin tareas",
                    subtitle: "Añade tareas para organizar el grupo"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(groupManager.currentGroup?.tasks ?? []) { task in
                        TaskRow(task: task) { updatedTask in
                            Task { @MainActor in
                                GroupManager.shared.updateTask(updatedTask)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(onAdd: { title in
                Task { @MainActor in
                    GroupManager.shared.addTask(title: title)
                }
            })
        }
    }

    // MARK: - Calendar

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Eventos del grupo")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showAddEvent = true }) {
                    Label("Añadir", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            if groupManager.currentGroup?.calendarEvents.isEmpty ?? true {
                EmptyFeatureState(
                    icon: "calendar.badge.plus",
                    title: "Sin eventos",
                    subtitle: "Añade eventos y recordatorios para el grupo"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(groupManager.currentGroup?.calendarEvents ?? []) { event in
                        CalendarEventRow(event: event)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddCalendarEventSheet(onAdd: { title, date, desc in
                let userId = self.authManager.currentUser?.id ?? ""
                Task { @MainActor in
                    GroupManager.shared.addCalendarEvent(title: title, date: date, description: desc, createdBy: userId)
                }
            })
        }
    }

    // MARK: - Members

    private var membersView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Miembros (\(groupManager.groupMembers.count))")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            LazyVStack(spacing: 10) {
                ForEach(groupManager.groupMembers) { member in
                    GroupMemberRow(member: member, group: groupManager.currentGroup, currentUserId: authManager.currentUser?.id)
                }
            }
        }
    }

    // MARK: - Invite

    private var inviteView: some View {
        VStack(spacing: 20) {
            if let group = groupManager.currentGroup {
                // QR Code
                VStack(spacing: 12) {
                    Text("Código QR")
                        .font(.headline)
                        .fontWeight(.bold)

                    QRCodeView(code: group.inviteCode)
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 10)

                    Text("Muestra este QR a tus amigos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Invite Code
                VStack(spacing: 10) {
                    Text("Código de invitación")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(group.inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .tracking(8)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(16)

                    // Copy Button
                    Button(action: {
                        UIPasteboard.general.string = group.inviteCode
                    }) {
                        Label("Copiar código", systemImage: "doc.on.doc.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }

                    // Share Link Button
                    Button(action: {
                        let url = "erasmusconnect://join/\(group.inviteCode)"
                        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        if let wc = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            wc.windows.first?.rootViewController?.present(av, animated: true)
                        }
                    }) {
                        Label("Compartir enlace", systemImage: "link.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: GroupTask
    let onToggle: (GroupTask) -> Void
    @State private var isDone: Bool

    init(task: GroupTask, onToggle: @escaping (GroupTask) -> Void) {
        self.task = task
        self.onToggle = onToggle
        self._isDone = State(initialValue: task.isDone)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isDone.toggle()
                    var updated = task
                    updated.isDone = isDone
                    onToggle(updated)
                }
            }) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isDone ? .green : .gray.opacity(0.5))
            }

            Text(task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .strikethrough(isDone, color: .secondary)
                .foregroundColor(isDone ? .secondary : .primary)

            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: GroupCalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date Pill
            VStack(spacing: 2) {
                Text(event.date.formatted(.dateTime.day()))
                    .font(.headline)
                    .fontWeight(.bold)
                Text(event.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(event.date.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "calendar.circle.fill")
                .foregroundColor(.blue.opacity(0.5))
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Group Member Row

struct GroupMemberRow: View {
    let member: UserProfile
    let group: SocialGroup?
    let currentUserId: String?

    var role: GroupRole {
        group?.role(for: member.id) ?? .member
    }

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(photoURL: member.photoURL.isEmpty ? nil : member.photoURL, name: member.displayName, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(member.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if member.id == currentUserId {
                        Text("Tú")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                Text("@\(member.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            roleBadge
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var roleBadge: some View {
        Text(role.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(roleColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(roleColor.opacity(0.12))
            .cornerRadius(8)
    }

    private var roleColor: Color {
        switch role {
        case .admin: return .orange
        case .moderator: return .blue
        case .member: return .gray
        }
    }
}

// MARK: - QR Code View

struct QRCodeView: View {
    let code: String

    var body: some View {
        if let qrImage = generateQR(from: code) {
            Image(uiImage: qrImage)
                .resizable()
                .interpolation(.none)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(Text("QR").font(.largeTitle).foregroundColor(.gray))
        }
    }

    private func generateQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Add Task Sheet

struct AddTaskSheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Nueva tarea") {
                    TextField("Ej: Buscar vuelos a Roma", text: $title)
                }
            }
            .navigationTitle("Añadir tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        onAdd(title)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - Add Calendar Event Sheet

struct AddCalendarEventSheet: View {
    let onAdd: (String, Date, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var description = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Evento") {
                    TextField("Título del evento", text: $title)
                    DatePicker("Fecha y hora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    TextField("Descripción (opcional)", text: $description)
                }
            }
            .navigationTitle("Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onAdd(title, date, description)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Empty Feature State

struct EmptyFeatureState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
