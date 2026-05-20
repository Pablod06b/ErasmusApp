// CreatePostView.swift
import SwiftUI
import PhotosUI
import FirebaseAuth
import MapKit

struct CreatePostView: View {
    @Binding var posts: [ErasmusPost]
    @Binding var showSheet: Bool
    @State private var selectedType: PostType
    
    // Core Fields
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var destination = "Salamanca"
    @State private var date = Date()
    @State private var isPaid = false
    @State private var price = ""
    @State private var allowSignups = true
    @State private var visibility: Visibility = .everyone
    @State private var category = ""
    @State private var contact = ""
    
    // New Fields
    @State private var rating = 5
    @State private var participantsNeeded = 3
    
    // Images
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageName: String?
    #if canImport(UIKit)
    @State private var previewImage: UIImage?
    #endif
    
    @State private var showPreview = false
    @State private var isUploading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @Environment(\.dismiss) var dismiss

    let destinations = AvailableCities.activeNames
    
    init(posts: Binding<[ErasmusPost]>, showSheet: Binding<Bool>, preselectedType: PostType = .event) {
        self._posts = posts
        self._showSheet = showSheet
        self._selectedType = State(initialValue: preselectedType)
    }

    var body: some View {
        NavigationView {
            ZStack {
                if showPreview {
                    ConfirmPostView(
                        post: createPreviewPost(),
                        onCancel: { showPreview = false },
                        onConfirm: publishPost
                    )
                } else {
                    ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header indicating type
                        HStack {
                            Image(systemName: iconForType(selectedType))
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(colorForType(selectedType))
                                .clipShape(Circle())
                            
                            Text(titleForType(selectedType))
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Dynamic Form Content
                        VStack(spacing: 24) {
                            
                            // 1. Basic Info (Title depends on type)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(headerTitleForType(selectedType))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                TextField(placeholderTitleForType(selectedType), text: $title)
                                    .textFieldStyle(PostTextFieldStyle())
                                
                                if selectedType != .openMessage {
                                    Picker("Destino", selection: $destination) {
                                        ForEach(destinations, id: \.self) { city in
                                            Text(city).tag(city)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // 2. Specific Fields
                            switch selectedType {
                            case .recommendation:
                                AnyView(RecommendationFields(rating: $rating, category: $category))
                            case .event:
                                AnyView(EventFields(date: $date, location: $location, isPaid: $isPaid, price: $price, allowSignups: $allowSignups))
                            case .personalPlan: // Plan Abierto
                                AnyView(OpenPlanFields(date: $date, participantsNeeded: $participantsNeeded, description: $description))
                            case .announcement: // Anuncio
                                AnyView(AnnouncementFields(category: $category, contact: $contact, description: $description))
                            case .openMessage: // Mensaje Libre
                                AnyView(TextField("Escribe lo que piensas...", text: $description, axis: .vertical)
                                    .lineLimit(4...8)
                                    .textFieldStyle(PostTextFieldStyle()))
                            default:
                                AnyView(EmptyView())
                            }
                            
                            // 3. Description (if not handled above)
                            if selectedType == .recommendation || selectedType == .event {
                                VStack(alignment: .leading) {
                                    Text("Descripción")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    TextField("Cuéntanos más...", text: $description, axis: .vertical)
                                        .lineLimit(3...6)
                                        .textFieldStyle(PostTextFieldStyle())
                                }
                            }
                            
                            // 4. Image Picker
                            #if canImport(UIKit)
                            ImageSection(
                                selectedImage: $selectedImage,
                                previewImage: $previewImage,
                                imageName: $imageName
                            )
                            #else
                            ImageSection(
                                selectedImage: $selectedImage,
                                imageName: $imageName
                            )
                            #endif
                        }
                        .padding()
                    }
                }
                .navigationTitle("Nueva Publicación")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Publicar") {
                            showPreview = true
                        }
                        .disabled(!isFormValid)
                    }
                }
                .onChange(of: selectedImage) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            #if canImport(UIKit)
                            if let uiImage = UIImage(data: data) {
                                let uniqueName = "user_image_\(UUID().uuidString).jpg"
                                if let savedName = FileManager.saveImage(uiImage, withName: uniqueName) {
                                    self.imageName = savedName
                                    self.previewImage = uiImage
                                }
                            }
                            #endif
                        }
                    }
                }
            }
            
            if isUploading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("Publicando...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
            }
            .alert("Error al publicar", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // Helper Functions using switches
    private func iconForType(_ type: PostType) -> String {
        switch type {
        case .recommendation: return "star.fill"
        case .event: return "party.popper.fill"
        case .personalPlan: return "calendar.badge.plus"
        case .announcement: return "megaphone.fill"
        case .openMessage: return "bubble.left.and.bubble.right.fill"
        default: return "doc.text"
        }
    }
    
    private func colorForType(_ type: PostType) -> Color {
        switch type {
        case .recommendation: return .orange
        case .event: return .purple
        case .personalPlan: return .blue
        case .announcement: return .green
        case .openMessage: return .pink
        default: return .gray
        }
    }
    
    private func titleForType(_ type: PostType) -> String {
        switch type {
        case .recommendation: return "Nueva Recomendación"
        case .event: return "Nuevo Evento"
        case .personalPlan: return "Nuevo Plan"
        case .announcement: return "Nuevo Anuncio"
        case .openMessage: return "Mensaje Rápido"
        default: return "Publicación"
        }
    }
    
    private func headerTitleForType(_ type: PostType) -> String {
        switch type {
        case .recommendation: return "Nombre del lugar"
        case .event: return "Nombre del evento"
        case .personalPlan: return "Título del plan"
        case .announcement: return "Título"
        case .openMessage: return "Título (opcional)"
        default: return "Título"
        }
    }
    
    private func placeholderTitleForType(_ type: PostType) -> String {
        switch type {
        case .recommendation: return "Ej. Bar La Viga"
        case .event: return "Ej. Fiesta Erasmus"
        case .personalPlan: return "Ej. Ir a IKEA"
        case .announcement: return "Ej. Se busca compañero"
        case .openMessage: return "Ej. Alguien para jugar pádel?"
        default: return "Escribe aquí..."
        }
    }

    private var isFormValid: Bool {
        if selectedType != .openMessage && title.isEmpty { return false }
        
        switch selectedType {
        case .recommendation:
            return !category.isEmpty
        case .event:
            if location.isEmpty { return false }
            if isPaid && price.isEmpty { return false }
            return true
        case .personalPlan:
            return !description.isEmpty
        case .announcement:
            return !category.isEmpty && !description.isEmpty
        case .openMessage:
            return !description.isEmpty
        default:
            return true
        }
    }

    private func createPreviewPost() -> ErasmusPost {
        ErasmusPost(
            userId: "temp_user",
            type: selectedType,
            title: title.isEmpty ? "Sin título" : title,
            description: description.isEmpty ? "Sin descripción" : description,
            location: location.isEmpty ? nil : location,
            destination: destination,
            date: (selectedType == .event || selectedType == .personalPlan) ? date : nil,
            isPaid: (selectedType == .event) ? isPaid : nil,
            price: isPaid ? Double(price) : nil,
            allowSignups: (selectedType == .event) ? allowSignups : nil,
            visibility: visibility,
            imageName: imageName,
            category: (selectedType == .announcement || selectedType == .recommendation) ? (category.isEmpty ? nil : category) : nil,
            contact: selectedType == .announcement ? (contact.isEmpty ? nil : contact) : nil,
            rating: selectedType == .recommendation ? rating : nil,
            participantsNeeded: selectedType == .personalPlan ? participantsNeeded : nil
        )
    }
    
    // MARK: - Firebase Upload Logic
    private func publishPost() {
        Task {
            var newPost = createPreviewPost()
            
            await MainActor.run {
                isUploading = true
            }
            
            do {
                if let currentUserId = Auth.auth().currentUser?.uid {
                    // Inject real user ID
                    newPost = ErasmusPost(id: newPost.id, userId: currentUserId, type: newPost.type, title: newPost.title, description: newPost.description, location: newPost.location, destination: newPost.destination, date: newPost.date, isPaid: newPost.isPaid, price: newPost.price, allowSignups: newPost.allowSignups, visibility: newPost.visibility, imageName: newPost.imageName, category: newPost.category, contact: newPost.contact, isReported: newPost.isReported, rating: newPost.rating, participantsNeeded: newPost.participantsNeeded)
                }
                
                #if canImport(UIKit)
                if let imageToUpload = previewImage {
                    let imageUrl = try await PostManager.shared.uploadPostImage(imageToUpload, postId: newPost.id.uuidString)
                    newPost = ErasmusPost(id: newPost.id, userId: newPost.userId, type: newPost.type, title: newPost.title, description: newPost.description, location: newPost.location, destination: newPost.destination, date: newPost.date, isPaid: newPost.isPaid, price: newPost.price, allowSignups: newPost.allowSignups, visibility: newPost.visibility, imageName: imageUrl, category: newPost.category, contact: newPost.contact, isReported: newPost.isReported, rating: newPost.rating, participantsNeeded: newPost.participantsNeeded)
                }
                #endif
                
                try await PostManager.shared.createPost(newPost)
                
                await MainActor.run {
                    if let currentUserId = Auth.auth().currentUser?.uid {
                        NotificationManager.shared.addNotification(
                            type: .system,
                            title: "¡Publicación Creada!",
                            message: "Tu \(newPost.type.rawValue) se ha publicado correctamente.",
                            targetUserId: currentUserId
                        )
                    }
                    
                    isUploading = false
                    showSheet = false
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    print("Error publicando el post: \(error)")
                }
            }
        }
    }
}

// MARK: - Subviews for Specific Forms

struct RecommendationFields: View {
    @Binding var rating: Int
    @Binding var category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Valoración").font(.headline).foregroundColor(.secondary)
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundColor(.orange)
                        .onTapGesture { rating = star }
                }
            }
            .font(.title)
            
            Text("Categoría").font(.headline).foregroundColor(.secondary)
            TextField("Ej. Comida, Vistas, Estudio", text: $category)
                .textFieldStyle(PostTextFieldStyle())
        }
    }
}

struct EventFields: View {
    @Binding var date: Date
    @Binding var location: String
    @Binding var isPaid: Bool
    @Binding var price: String
    @Binding var allowSignups: Bool
    
    @StateObject private var locationSearch = LocationSearchViewModel()
    @FocusState private var isLocationFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DatePicker("Fecha y Hora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)

            Text("Ubicación exacta").font(.headline).foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.blue)
                    TextField("Busca la calle, local o ciudad...", text: $locationSearch.searchQuery)
                        .focused($isLocationFocused)
                        .onChange(of: locationSearch.searchQuery) { newValue in
                            // If the user manually edits, we haven't selected a final location yet
                            if location != newValue {
                                location = ""
                            }
                        }
                    
                    if !locationSearch.searchQuery.isEmpty {
                        Button(action: {
                            locationSearch.searchQuery = ""
                            location = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
                
                // Autocomplete Dropdown
                if isLocationFocused && !locationSearch.completions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(locationSearch.completions, id: \.self) { completion in
                                VStack(alignment: .leading) {
                                    Text(completion.title)
                                        .font(.body)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .onTapGesture {
                                    // When selected, fill the search bar and the actual location variable
                                    let fullLocation = "\(completion.title), \(completion.subtitle)".trimmingCharacters(in: CharacterSet(charactersIn: ", "))
                                    locationSearch.searchQuery = fullLocation
                                    location = fullLocation
                                    isLocationFocused = false
                                }
                                
                                Divider()
                            }
                        }
                        .background(Color(UIColor.tertiarySystemBackground))
                    }
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, y: 5)
                    .padding(.top, 4)
                }
            }
            if isPaid {
                TextField("Precio (€)", text: $price)
                    .textFieldStyle(PostTextFieldStyle())
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            
            Toggle("Permitir que la gente se apunte", isOn: $allowSignups)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct OpenPlanFields: View {
    @Binding var date: Date
    @Binding var participantsNeeded: Int
    @Binding var description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DatePicker("Fecha aproximada", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)

            Stepper("Personas necesarias: \(participantsNeeded)", value: $participantsNeeded, in: 1...20)
            
            Text("Detalles del plan").font(.headline).foregroundColor(.secondary)
            TextField("¿Qué vamos a hacer?", text: $description, axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(PostTextFieldStyle())
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AnnouncementFields: View {
    @Binding var category: String
    @Binding var contact: String
    @Binding var description: String
    
    let categories = ["Piso", "Compañero", "Venta", "Objetos", "Otro"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tipo de anuncio").font(.headline).foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { cat in
                        Button(action: { category = cat }) {
                            Text(cat)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(category == cat ? Color.green : Color.gray.opacity(0.2))
                                .foregroundColor(category == cat ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            
            Text("Descripción").font(.headline).foregroundColor(.secondary)
            TextField("Describe lo que buscas/ofreces...", text: $description, axis: .vertical)
                .lineLimit(4...6)
                .textFieldStyle(PostTextFieldStyle())
            
            Text("Contacto (Opcional)").font(.headline).foregroundColor(.secondary)
            TextField("Instagram, WhatsApp...", text: $contact)
                .textFieldStyle(PostTextFieldStyle())
        }
    }
}

struct PostTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
    }
}

// Keep ImageSection and ConfirmPostView from previous implementation or minimal version
struct ImageSection: View {
    @Binding var selectedImage: PhotosPickerItem?
    #if canImport(UIKit)
    @Binding var previewImage: UIImage? // Correct binding type
    #endif
    @Binding var imageName: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Imagen (Opcional)").font(.headline).foregroundColor(.secondary)
            PhotosPicker(selection: $selectedImage, matching: .images) {
                #if canImport(UIKit)
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(8)
                        }
                } else {
                    PlaceholderView()
                }
                #else
                PlaceholderView()
                #endif
            }
        }
    }
}

struct PlaceholderView: View {
    var body: some View {
        HStack {
            Image(systemName: "photo.badge.plus")
            Text("Añadir foto")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .foregroundColor(.blue)
    }
}


struct ConfirmPostView: View {
    let post: ErasmusPost
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Vista Previa")
            .font(.title2)
            .fontWeight(.bold)
            
            PostCardView(post: post)
            .padding()
            .shadow(radius: 5)
            
            HStack(spacing: 20) {
                Button("Seguir editando", action: onCancel)
                .foregroundColor(.secondary)
                
                Button(action: onConfirm) {
                    Text("Publicar ahora")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

// MARK: - Post Type Selection (Moved here to ensure visibility)

struct CreatePostOptionsView: View {
    @Binding var showSheet: Bool
    @Binding var posts: [ErasmusPost]
    @State private var selectedType: PostType?
    @State private var showEventCreate = false
    
    // Grid layout for cards
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("¿Qué quieres compartir?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Recomendación
                        OptionCard(
                            icon: "star.fill",
                            color: .orange,
                            title: "Recomendación",
                            subtitle: "Lugares, experiencias",
                            action: { selectedType = .recommendation }
                        )
                        
                        // Evento
                        OptionCard(
                            icon: "party.popper.fill",
                            color: .purple,
                            title: "Evento",
                            subtitle: "Fiestas, viajes",
                            action: { showEventCreate = true }
                        )
                        
                        // Plan Abierto (Plan Personal)
                        OptionCard(
                            icon: "calendar.badge.plus",
                            color: .blue,
                            title: "Plan abierto",
                            subtitle: "Organizar algo",
                            action: { selectedType = .personalPlan }
                        )
                        
                        // Anuncio
                        OptionCard(
                            icon: "megaphone.fill",
                            color: .green,
                            title: "Anuncio",
                            subtitle: "Piso, objetos",
                            action: { selectedType = .announcement }
                        )
                        
                        // Mensaje Libre
                        OptionCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .pink,
                            title: "Mensaje libre",
                            subtitle: "Algo rápido",
                            isFullWidth: true,
                            action: { selectedType = .openMessage }
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showSheet = false
                    }
                }
            }
            .sheet(item: $selectedType) { type in
                CreatePostView(
                    posts: $posts,
                    showSheet: $showSheet,
                    preselectedType: type
                )
            }
            .sheet(isPresented: $showEventCreate) {
                EventCreateView()
            }
        }
    }
}

struct OptionCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    var isFullWidth: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .if(isFullWidth) { view in
            view.gridCellColumns(2)
        }
    }
}

// Extension to handle conditional modifiers comfortably
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
