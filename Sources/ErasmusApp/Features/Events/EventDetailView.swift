// EventDetailView.swift
import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct EventDetailView: View {
    let evento: Evento

    @State private var isAttending = false
    @State private var attendeesCount: Int = 0
    @State private var isLoadingAttend = false
    @State private var showReportAlert = false
    @State private var organizerName: String = "Organizador"
    @State private var organizerPhoto: String? = nil
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var loadFailed: Bool = false
    @StateObject private var favoritesManager = FavoritesManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @Environment(\.dismiss) private var dismiss

    private var firestoreId: String { evento.firestoreId ?? evento.id.uuidString }
    private var isSaved: Bool { favoritesManager.isEventSaved(firestoreId) }

    private var categoryColor: Color {
        switch evento.category.lowercased() {
        case "discoteca", "fiesta", "club": return .purple
        case "deporte", "sport": return .green
        case "cultura", "arte", "museum": return .orange
        case "comida", "gastronomía": return .red
        default: return .blue
        }
    }

    var body: some View {
        Group {
            if loadFailed {
                ContentNotAvailableView(kind: .event, onBack: { dismiss() })
                    .navigationBarBackButtonHidden(true)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        heroSection
                        contentSection
                        mapSection
                        organizerSection
                        actionsSection
                        reportSection
                    }
                }
                .ignoresSafeArea(edges: .top)
                .navigationBarBackButtonHidden(true)
                .overlay(alignment: .topLeading) { topBar }
            }
        }
        .task { await loadEventData() }
        .confirmationDialog("¿Reportar este evento?", isPresented: $showReportAlert, titleVisibility: .visible) {
            Button("Reportar", role: .destructive) { Task { await reportEvent() } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tu reporte se enviará a moderación.")
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let urlStr = evento.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            heroFallback
                        }
                    }
                } else {
                    heroFallback
                }
            }
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center, endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(evento.category)
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(categoryColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    if evento.isVerifiedBusiness == true {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.blue)
                    }
                    Spacer()
                }
                Text(evento.title)
                    .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                    .lineLimit(3)
                HStack(spacing: 14) {
                    Label(evento.date, systemImage: "calendar").font(.subheadline).foregroundColor(.white.opacity(0.95))
                    if let price = evento.price {
                        Label(price == 0 ? "Gratis" : String(format: "%.0f€", price), systemImage: "eurosign.circle.fill")
                            .font(.subheadline).foregroundColor(.white.opacity(0.95))
                    }
                }
            }
            .padding(20)
        }
    }

    private var heroFallback: some View {
        LinearGradient(
            colors: [categoryColor, categoryColor.opacity(0.5)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.4))
        )
    }

    // MARK: - Top Bar (back/save/share)
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            Spacer()
            HStack(spacing: 10) {
                Button { Task { await favoritesManager.toggleEvent(evento) } } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSaved ? .yellow : .white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    private var shareText: String {
        "Mira este evento en ErasmusConnect: \(evento.title) — \(evento.location), \(evento.date)"
    }

    // MARK: - Content
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill").foregroundColor(.red)
                Text(evento.location).font(.headline)
            }

            if let desc = evento.eventDescription, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 16) {
                Label("\(attendeesCount) apuntados", systemImage: "person.2.fill")
                    .font(.subheadline).foregroundColor(.secondary)
                if let max = evento.participants, max > 0 {
                    Text("· max \(max)")
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
    }

    // MARK: - Map
    @ViewBuilder
    private var mapSection: some View {
        if let coord = coordinate {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ubicación").font(.headline).padding(.horizontal, 20)
                Map(position: $mapPosition) {
                    Marker(evento.title, coordinate: coord).tint(categoryColor)
                }
                .frame(height: 180)
                .cornerRadius(14)
                .padding(.horizontal, 20)
                .allowsHitTesting(false)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Organizer
    private var organizerSection: some View {
        HStack(spacing: 12) {
            UserAvatarView(photoURL: organizerPhoto, name: organizerName, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Organizado por")
                    .font(.caption).foregroundColor(.secondary)
                Text(organizerName)
                    .font(.subheadline).fontWeight(.semibold)
            }
            Spacer()
            if let uid = evento.userId, uid != authManager.currentUser?.id {
                Button {
                    // future: open chat with organizer
                } label: {
                    Image(systemName: "message.fill")
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
    }

    // MARK: - Actions (Apuntarse)
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { Task { await toggleAttend() } }) {
                HStack {
                    if isLoadingAttend {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: isAttending ? "checkmark.circle.fill" : "person.badge.plus")
                    }
                    Text(isAttending ? "Apuntado · pulsa para cancelar" : "Apuntarme")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: isAttending ? [.green, .teal] : [categoryColor, categoryColor.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .disabled(isLoadingAttend)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    private var reportSection: some View {
        Button(role: .destructive) { showReportAlert = true } label: {
            Label("Reportar evento", systemImage: "flag.fill")
                .font(.footnote)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 20).padding(.bottom, 40)
    }

    // MARK: - Data loading
    private func loadEventData() async {
        // Verifica que el evento sigue existiendo en Firestore (puede haber sido borrado)
        if let fid = evento.firestoreId {
            let db = Firestore.firestore()
            if let snap = try? await db.collection("events").document(fid).getDocument(), !snap.exists {
                await MainActor.run { loadFailed = true }
                return
            }
        }

        // Resolve organizer
        if let uid = evento.userId {
            let db = Firestore.firestore()
            if let snap = try? await db.collection("users").document(uid).getDocument(),
               let data = snap.data() {
                organizerName = (data["displayName"] as? String) ?? organizerName
                organizerPhoto = data["photoURL"] as? String
            }
        }
        // Resolve attendees subcollection
        await refreshAttendees()
        // Resolve location via geocoder
        let geocoder = CLGeocoder()
        let query = "\(evento.location), \(evento.city ?? "")"
        if let placemark = try? await geocoder.geocodeAddressString(query).first,
           let loc = placemark.location?.coordinate {
            await MainActor.run {
                coordinate = loc
                mapPosition = .region(MKCoordinateRegion(
                    center: loc,
                    latitudinalMeters: 1000, longitudinalMeters: 1000
                ))
            }
        }
    }

    private func refreshAttendees() async {
        guard let firestoreId = evento.firestoreId else {
            await MainActor.run { attendeesCount = 0 }
            return
        }
        let db = Firestore.firestore()
        let attendeesRef = db.collection("events").document(firestoreId).collection("attendees")
        if let snap = try? await attendeesRef.getDocuments() {
            await MainActor.run { attendeesCount = snap.documents.count }
            if let uid = Auth.auth().currentUser?.uid {
                let isIn = snap.documents.contains(where: { $0.documentID == uid })
                await MainActor.run { isAttending = isIn }
            }
        }
    }

    private func toggleAttend() async {
        guard let firestoreId = evento.firestoreId,
              let uid = Auth.auth().currentUser?.uid else { return }
        isLoadingAttend = true
        defer { isLoadingAttend = false }

        let db = Firestore.firestore()
        let ref = db.collection("events").document(firestoreId).collection("attendees").document(uid)
        if isAttending {
            try? await ref.delete()
            await MainActor.run {
                isAttending = false
                attendeesCount = max(0, attendeesCount - 1)
            }
        } else {
            try? await ref.setData([
                "joinedAt": FieldValue.serverTimestamp(),
                "userId": uid
            ])
            await MainActor.run {
                isAttending = true
                attendeesCount += 1
            }
            AppAnalytics.logEventJoin(eventId: firestoreId)
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }

    private func reportEvent() async {
        guard let firestoreId = evento.firestoreId,
              let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        try? await db.collection("reports").addDocument(data: [
            "type": "event",
            "targetId": firestoreId,
            "reportedBy": uid,
            "createdAt": FieldValue.serverTimestamp()
        ])
        AppAnalytics.logReport(targetType: "event")
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
