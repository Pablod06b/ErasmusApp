// ModernCreatePostView.swift
import SwiftUI
import PhotosUI

struct ModernCreatePostView: View {
    @Binding var posts: [ErasmusPost]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var selectedType: PostType = .event
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var destination = "Salamanca"
    @State private var category = ""
    @State private var contact = ""
    @State private var date = Date()
    @State private var isPaid = false
    @State private var price = ""
    @State private var allowSignups = true
    @State private var visibility: Visibility = .everyone
    @State private var isLoading = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showError = false
    @State private var errorMessage = ""
    #if canImport(UIKit)
    @State private var selectedImage: UIImage?
    @State private var loadedPreviewImage: UIImage?
    #endif
    @State private var showPreview = false
    @State private var currentStep = 0
    @State private var imageName: String?

    var canProceedToNextStep: Bool {
        switch currentStep {
        case 0: return true  // type always selected
        case 1: return !title.isEmpty && !description.isEmpty
        case 2: return true
        default: return false
        }
    }

    let destinations = AvailableCities.activeNames
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 3)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Step indicator
                HStack {
                    ForEach(0..<3) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        if step < 2 {
                            Rectangle()
                                .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0:
                            AnyView(TypeSelectionView(selectedType: $selectedType))
                        case 1:
                            AnyView(DetailsInputView(
                                title: $title,
                                description: $description,
                                location: $location,
                                destination: $destination,
                                date: $date,
                                category: $category,
                                contact: $contact,
                                destinations: destinations,
                                selectedType: selectedType
                            ))
                        case 2:
                            AnyView(OptionsAndImageView(
                                isPaid: $isPaid,
                                price: $price,
                                allowSignups: $allowSignups,
                                visibility: $visibility,
                                selectedImage: $selectedPhoto,
                                imageName: $imageName,
                                selectedType: selectedType,
                                loadedPreviewImage: $loadedPreviewImage
                            ))
                        default:
                            AnyView(EmptyView())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Atrás") {
                            withAnimation(.spring()) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if currentStep == 2 {
                        Button("Previsualizar") {
                            showPreview = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceedToNextStep)
                    } else {
                        Button("Siguiente") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceedToNextStep)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Nueva Publicación")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        // The "Publicar" button is inside ModernConfirmPostView,
                        // so this toolbar item is for general confirmation if needed elsewhere.
                        // For this specific instruction, we're adding a ProgressView
                        // in the confirmation slot, assuming a "Publish" button would go here.
                        // If there was an explicit "Publish" button in the toolbar, it would be replaced.
                        // Since there isn't, we'll just add the ProgressView conditionally.
                        EmptyView() // Or a placeholder if no other confirmation action is needed here
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                ModernConfirmPostView(
                    post: createPreviewPost(imageUrl: nil),
                    isLoading: isLoading,
                    onCancel: { showPreview = false },
                    onConfirm: {
                        Task { await publishPost() }
                    }
                )
            }
            .alert("Error al publicar", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    #if canImport(UIKit)
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        self.selectedImage = uiImage
                        self.loadedPreviewImage = uiImage
                    }
                    #endif
                }
            }
        }
    }
    
    private func createPreviewPost(imageUrl: String? = nil) -> ErasmusPost {
        let userId = authManager.currentUser?.id ?? ""
        return ErasmusPost(
            id: UUID(),
            userId: userId,
            type: selectedType,
            title: title,
            description: description,
            location: location.isEmpty ? nil : location,
            destination: destination,
            date: date,
            isPaid: isPaid,
            price: isPaid ? Double(price) ?? 0.0 : nil,
            allowSignups: allowSignups,
            visibility: visibility,
            imageName: imageUrl,
            category: category.isEmpty ? nil : category,
            contact: contact.isEmpty ? nil : contact
        )
    }
}

// MARK: - Type Selection View
struct TypeSelectionView: View {
    @Binding var selectedType: PostType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("¿Qué tipo de publicación quieres crear?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach([PostType.event, PostType.housing, PostType.recommendation, PostType.announcement, PostType.personalPlan, PostType.openMessage], id: \.self) { type in
                    TypeCardView(
                        type: type,
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }
        }
    }
}

// MARK: - Type Card View
struct TypeCardView: View {
    let type: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconForType(type))
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                          AnyShapeStyle(Color.gray.opacity(0.1))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.blue.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForType(_ type: PostType) -> String {
        switch type {
        case .event: return "calendar.badge.plus"
        case .openMessage: return "message.circle"
        case .announcement: return "megaphone"
        case .recommendation: return "star.circle"
        case .personalPlan: return "person.crop.circle"
        case .housing: return "house.circle"
        }
    }
}

// MARK: - Details Input View
struct DetailsInputView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var location: String
    @Binding var destination: String
    @Binding var date: Date
    @Binding var category: String
    @Binding var contact: String
    let destinations: [String]
    let selectedType: PostType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Detalles de la publicación")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Title
                CreatePostTextField(
                    title: "Título",
                    text: $title,
                    placeholder: "Escribe un título atractivo",
                    icon: "textformat"
                )
                
                // Description
                CreatePostTextArea(
                    title: "Descripción",
                    text: $description,
                    placeholder: "Describe tu publicación...",
                    icon: "text.quote"
                )
                
                // Location
                CreatePostTextField(
                    title: "Ubicación",
                    text: $location,
                    placeholder: "¿Dónde será?",
                    icon: "location"
                )
                
                // Destination
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Destino")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Picker("Destino", selection: $destination) {
                        ForEach(destinations, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        Text("Fecha")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                // Category
                CreatePostTextField(
                    title: "Categoría",
                    text: $category,
                    placeholder: "Ej: Discotecas, Eventos, etc.",
                    icon: "tag"
                )
                
                // Contact
                CreatePostTextField(
                    title: "Contacto (opcional)",
                    text: $contact,
                    placeholder: "Teléfono, email, etc.",
                    icon: "phone"
                )
            }
        }
    }
}

// MARK: - Options and Image View
struct OptionsAndImageView: View {
    @Binding var isPaid: Bool
    @Binding var price: String
    @Binding var allowSignups: Bool
    @Binding var visibility: Visibility
    @Binding var selectedImage: PhotosPickerItem?
    @Binding var imageName: String?
    let selectedType: PostType
    #if canImport(UIKit)
    @Binding var loadedPreviewImage: UIImage?
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Opciones e imagen")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Price section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "eurosign.circle")
                            .foregroundColor(.green)
                        Text("¿Es de pago?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Toggle("", isOn: $isPaid)
                    }
                    
                    if isPaid {
                        #if os(iOS)
                        CreatePostTextField(
                            title: "Precio (€)",
                            text: $price,
                            placeholder: "0.00",
                            icon: "eurosign",
                            keyboardType: .decimalPad
                        )
                        #else
                        CreatePostTextField(
                            title: "Precio (€)",
                            text: $price,
                            placeholder: "0.00",
                            icon: "eurosign"
                        )
                        #endif
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Signups
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.blue)
                        Text("Permitir apuntarse")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Toggle("", isOn: $allowSignups)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Visibility
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.purple)
                        Text("Visibilidad")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Picker("Visibilidad", selection: $visibility) {
                        ForEach(Visibility.allCases, id: \.self) { visibility in
                            Text(visibility.rawValue).tag(visibility)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Image picker
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(.orange)
                        Text("Imagen (opcional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    #if canImport(UIKit)
                    if let uiImg = loadedPreviewImage {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                    }
                    #endif

                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text(loadedPreviewImage == nil ? "Seleccionar imagen" : "Cambiar imagen")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Create Post Text Field
struct CreatePostTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    #if os(iOS)
    var keyboardType: UIKeyboardType = .default
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - Create Post Text Area
struct CreatePostTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Modern Confirm Post View
struct ModernConfirmPostView: View {
    let post: ErasmusPost
    let isLoading: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview card
                    // Post preview placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title)
                            .font(.headline)
                        Text(post.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Confirmation message
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("¿Todo listo?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Revisa los detalles de tu publicación antes de publicarla.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Confirmar Publicación")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Publicar") { onConfirm() }
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

extension ModernCreatePostView {
    // MARK: - Firebase Integration
    @MainActor
    private func publishPost() async {
        isLoading = true
        
        do {
            var finalImageUrl: String? = nil
            
            #if canImport(UIKit)
            if let imageToUpload = selectedImage {
                let tempPostId = UUID().uuidString
                finalImageUrl = try await PostManager.shared.uploadPostImage(imageToUpload, postId: tempPostId)
            }
            #endif
            
            let newPost = createPreviewPost(imageUrl: finalImageUrl)
            try await PostManager.shared.createPost(newPost)
            
            // Also save locally for immediate UI update (optional if we listen to Firestore)
            posts.append(newPost)
            
            showPreview = false
            dismiss()
        } catch {
            errorMessage = "No se pudo publicar. Comprueba tu conexión e inténtalo de nuevo."
            showError = true
        }

        isLoading = false
    }
}

