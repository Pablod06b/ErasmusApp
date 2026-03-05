import SwiftUI
import PhotosUI
import UserNotifications


struct ModernOnboardingFlow: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    let onFinish: () -> Void
    
    // Navigation
    @State private var currentStep: OnboardingStep = .registro1
    
    // Registro 1
    @State private var nombre: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var showPassword: Bool = false
    
    // Universidad y estudios
    @State private var universidadBusqueda: String = ""
    @State private var universidadSeleccionada: String = ""
    @State private var carreraBusqueda: String = ""
    @State private var carreraSeleccionada: String = ""
    
    // Estado Erasmus
    @State private var estadoErasmus: EstadoErasmus? = nil
    
    // Destino
    @State private var destinoBusqueda: String = ""
    @State private var destinoSeleccionado: String = ""
    
    // Idiomas e intereses
    @State private var idiomaEntrada: String = ""
    @State private var idiomas: [LanguageLevel] = []
    @State private var interesesSeleccionados: Set<String> = []
    
    // Grupos
    @State private var opcionGrupo: OpcionGrupo? = nil
    @State private var codigoGrupo: String = ""
    @State private var nombreGrupo: String = ""
    @State private var codigoGrupoGenerado: String = ""
    
    // Permisos
    @State private var permisoUbicacion: Bool = false
    @State private var permisoNotificaciones: Bool = false
    @State private var permisoCamara: Bool = false
    @State private var acceptedEULA: Bool = false
    
    // Control
    @State private var isSubmitting: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?
    #if canImport(UIKit)
    @State private var profileImage: UIImage?
    #else
    @State private var profileImage: Any? = nil // Dummy for macOS
    #endif
    // Removed FirebaseDataManager which is obsolete
    
    // Verificación
    @State private var codigoVerificacion: String = ""
    
    // Validación
    @State private var emailError: String = ""
    @State private var passwordError: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var showImagePicker = false
    #if canImport(UIKit)
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    #endif
    @State private var showImageSourceActionSheet = false
    
    let interesesOpciones: [String] = ["🎭 Cultura", "⚽ Deporte", "🍕 Gastronomía", "🎉 Fiesta", "✈️ Viajes", "🌿 Naturaleza", "💻 Tecnología", "🎨 Arte", "🎵 Música", "📸 Fotografía"]
    
    let idiomasDisponibles: [String] = ["🇪🇸 Español", "🇬🇧 Inglés", "🇫🇷 Francés", "🇩🇪 Alemán", "🇮🇹 Italiano", "🇵🇹 Portugués", "🇳🇱 Holandés", "🇵🇱 Polaco", "🇨🇿 Checo", "🇭🇺 Húngaro", "🇸🇪 Sueco", "🇳🇴 Noruego", "🇩🇰 Danés", "🇫🇮 Finlandés", "🇬🇷 Griego", "🇷🇺 Ruso", "🇨🇳 Chino", "🇯🇵 Japonés", "🇰🇷 Coreano", "🇦🇷 Árabe"]
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.01),
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.02)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                content
                bottomSection
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .padding(.horizontal, 24)
            
            // Title and step counter
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentStep.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = currentStep.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(currentStep.rawValue + 1)/\(OnboardingStep.allCases.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Content
    @ViewBuilder private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch currentStep {
                case .registro1:
                    AnyView(registro1View)
                case .fotoPerfil:
                    AnyView(fotoPerfilView)
                case .universidad:
                    AnyView(universidadView)
                case .estado:
                    AnyView(estadoView)
                case .destinoA:
                    AnyView(destinoAView)
                case .destinoB:
                    AnyView(destinoBView)
                case .idiomas:
                    AnyView(idiomasView)
                case .grupos:
                    AnyView(gruposView)
                case .permisos:
                    AnyView(permisosView)
                case .verificacion:
                    AnyView(verificacionView)
                case .completado:
                    AnyView(completadoView)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 16) {
            if currentStep != .registro1 && currentStep != .completado {
                Button(action: goBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Atrás")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if currentStep != .completado {
                Button(action: goNext) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(currentStep.buttonText)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canContinue ? 
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .foregroundColor(.white)
                }
                .disabled(!canContinue || isSubmitting)
            }
            
            // Login link for registro1
            if currentStep == .registro1 {
                Button(action: { 
                    onFinish()
                }) {
                    Text("¿Ya tienes cuenta? **Inicia sesión aquí**")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        #if canImport(UIKit)
        .padding(.bottom, max(24, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
        #else
        .padding(.bottom, 24)
        #endif
    }
    
    // MARK: - Screen Views
    private var registro1View: some View {
        VStack(spacing: 24) {
            ModernInputField(
                title: "Nombre y apellidos",
                placeholder: "Tu nombre completo",
                text: $nombre,
                icon: "👤"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                ModernInputField(
                    title: "Email",
                    placeholder: "tucorreo@ejemplo.com",
                    text: $email,
                    icon: "📧",
                    keyboardType: .emailAddress
                )
                
                if !emailError.isEmpty {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ModernSecureField(
                    title: "Contraseña",
                    placeholder: "Mínimo 6 caracteres, 1 mayúscula, 1 número",
                    text: $password,
                    showPassword: $showPassword,
                    icon: "🔒"
                )
                
                // Password validation indicators
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(password.count >= 6 ? .green : .red)
                            .font(.caption)
                        Text("Mínimo 6 caracteres")
                            .font(.caption)
                            .foregroundColor(password.count >= 6 ? .green : .secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: password.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(password.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil ? .green : .red)
                            .font(.caption)
                        Text("Al menos 1 mayúscula")
                            .font(.caption)
                            .foregroundColor(password.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil ? .green : .secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil ? .green : .red)
                            .font(.caption)
                        Text("Al menos 1 número")
                            .font(.caption)
                            .foregroundColor(password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil ? .green : .secondary)
                    }
                }
                .padding(.top, 4)
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            
            ModernInputField(
                title: "Nombre de usuario",
                placeholder: "@usuario",
                text: $username,
                icon: "👤"
            )
        }
    }
    
    private var universidadView: some View {
        VStack(spacing: 24) {
            ModernSearchField(
                title: "Universidad de origen",
                placeholder: "Buscar universidad...",
                text: $universidadBusqueda,
                selection: $universidadSeleccionada,
                suggestions: sampleUniversidades(),
                icon: "🎓"
            )
            
            ModernSearchField(
                title: "Estudios o carrera",
                placeholder: "Buscar carrera...",
                text: $carreraBusqueda,
                selection: $carreraSeleccionada,
                suggestions: sampleCarreras(),
                icon: "📚"
            )
        }
    }
    
    private var estadoView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("🤔")
                    .font(.system(size: 60))
                
                Text("¿En qué punto estás con tu Erasmus?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("No te preocupes, podrás actualizarlo en cualquier momento.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(EstadoErasmus.allCases, id: \.self) { estado in
                    ModernOptionCard(
                        isSelected: estadoErasmus == estado,
                        emoji: estado.emoji,
                        title: estado.title,
                        subtitle: estado.subtitle,
                        color: estado.color
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            estadoErasmus = estado
                        }
                    }
                }
            }
        }
    }
    
    private var destinoAView: some View {
        VStack(spacing: 24) {
            ModernSearchField(
                title: "Buscar destino",
                placeholder: "Escribe tu ciudad...",
                text: $destinoBusqueda,
                selection: $destinoSeleccionado,
                suggestions: sampleDestinos(),
                icon: "🗺️"
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Ciudades populares")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(["Salamanca", "Madrid", "Barcelona", "Valencia", "Sevilla", "Granada"], id: \.self) { city in
                        ModernCityCard(
                            city: city,
                            isSelected: destinoSeleccionado == city
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                destinoSeleccionado = city
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var destinoBView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("🌍")
                    .font(.system(size: 60))
                
                Text("Descubre destinos increíbles")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Explora ciudades recomendadas según tus intereses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(["Salamanca", "Madrid", "Barcelona", "Valencia"], id: \.self) { city in
                    ModernDestinationCard(city: city)
                }
            }
        }
    }
    
    private var idiomasView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Idiomas section
            VStack(alignment: .leading, spacing: 16) {
                Text("Idiomas")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Menu(idiomaEntrada.isEmpty ? "Seleccionar idioma" : idiomaEntrada) {
                        ForEach(idiomasDisponibles, id: \.self) { idioma in
                            Button(idioma) {
                                idiomaEntrada = idioma
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Menu("Nivel") {
                        ForEach(["Básico", "Intermedio", "Avanzado", "Nativo"], id: \.self) { nivel in
                            Button(nivel) {
                                addLanguage(nivel: nivel)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(idiomaEntrada.isEmpty)
                }
                
                if !idiomas.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(idiomas.enumerated()), id: \.element.id) { index, idioma in
                            ModernChip(
                                text: "\(idioma.language) (\(idioma.level))",
                                onRemove: { removeLanguage(at: index) }
                            )
                        }
                    }
                }
            }
            
            // Intereses section
            VStack(alignment: .leading, spacing: 16) {
                Text("Intereses")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Selecciona al menos 2 intereses")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(interesesOpciones, id: \.self) { interes in
                        ModernInterestChip(
                            text: interes,
                            isSelected: interesesSeleccionados.contains(interes)
                        ) {
                            toggleInterest(interes)
                        }
                    }
                }
            }
        }
    }
    
    private var gruposView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("👯‍♂️")
                    .font(.system(size: 60))
                
                Text("¿Vas con alguien más?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Puedes crear o unirte a un grupo privado con tus amigos, pareja o compañeros de Erasmus.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ModernOptionCard(
                    isSelected: opcionGrupo == .crear,
                    emoji: "➕",
                    title: "Crear un grupo privado",
                    subtitle: "Crea un grupo con nombre y código para que tus compis se unan. Ideal si eres el primero en registrarte.",
                    color: .green
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        opcionGrupo = .crear
                        if codigoGrupoGenerado.isEmpty {
                            codigoGrupoGenerado = String((0..<5).map{ _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
                        }
                    }
                }
                
                if opcionGrupo == .crear {
                    VStack(alignment: .leading, spacing: 12) {
                        ModernInputField(
                            title: "Nombre del grupo",
                            placeholder: "Ej: Los de Salamanca",
                            text: $nombreGrupo,
                            icon: "📝"
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Código para compartir:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(codigoGrupoGenerado)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                Spacer()
                                Button(action: {
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = codigoGrupoGenerado
                                    #endif
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            Text("Tus compañeros pueden usar este código para unirse al grupo.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.horizontal, 8)
                }
                
                ModernOptionCard(
                    isSelected: opcionGrupo == .unirse,
                    emoji: "🔑",
                    title: "Unirme a un grupo existente",
                    subtitle: "Si alguien de tu grupo ya se ha registrado, únete con el código que te haya compartido.",
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        opcionGrupo = .unirse
                    }
                }
                
                if opcionGrupo == .unirse {
                    ModernInputField(
                        title: "Código del grupo",
                        placeholder: "Ej: X3A7P",
                        text: $codigoGrupo,
                        icon: "🔢"
                    )
                    .transition(.scale.combined(with: .opacity))
                    .padding(.horizontal, 8)
                }
                
                ModernOptionCard(
                    isSelected: opcionGrupo == .solo,
                    emoji: "⏳",
                    title: "Prefiero hacerlo más tarde / Estoy solo/a",
                    subtitle: "Puedes buscar gente y crear grupos después desde la app.",
                    color: .gray
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        opcionGrupo = .solo
                    }
                }
            }
        }
    }
    
    private var permisosView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("🔑")
                    .font(.system(size: 50))
                
                Text("Para una mejor experiencia")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ModernPermissionRow(
                    emoji: "📍",
                    title: "Ubicación",
                    subtitle: "Para encontrar eventos y personas cerca",
                    isOn: $permisoUbicacion
                )
                
                ModernPermissionRow(
                    emoji: "🔔",
                    title: "Notificaciones",
                    subtitle: "Para recibir actualizaciones de eventos",
                    isOn: $permisoNotificaciones
                )
                
                ModernPermissionRow(
                    emoji: "📸",
                    title: "Cámara",
                    subtitle: "Para subir fotos de tus experiencias",
                    isOn: $permisoCamara
                )
                
                Divider().padding(.vertical, 8)
                
                Toggle(isOn: $acceptedEULA) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Acepto los Términos de Uso")
                            .font(.headline)
                        Text("Confirmo que he leído y acepto el EULA.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.2), lineWidth: 1))
            }
        }
    }
    
    private var completadoView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(isSubmitting ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isSubmitting)
                
                VStack(spacing: 12) {
                    Text("¡Ya estás dentro!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Tu aventura Erasmus empieza aquí")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: { onFinish() }) {
                HStack {
                    Text("¡Vamos allá!")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Actions
    private func goBack() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            // Handle special navigation cases when going back
            if currentStep == .idiomas {
                // Go back to the appropriate destination step based on erasmus status
                if estadoErasmus == .noSe || estadoErasmus == .esperando {
                    currentStep = .destinoB
                } else {
                    currentStep = .destinoA
                }
            } else {
                currentStep = currentStep.previous
            }
        }
    }
    
    private func goNext() {
        guard canContinue else { return }
        
        if currentStep == .completado {
            onFinish()
            return
        }
        
        if currentStep == .permisos {
            currentStep = .verificacion
            return
        }
        
        if currentStep == .verificacion {
            submitRegistration()
            return
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            // Logic for estado -> destino routing
            if currentStep == .estado {
                if estadoErasmus == .noSe || estadoErasmus == .esperando {
                    currentStep = .destinoB
                } else {
                    currentStep = .destinoA
                }
            } else if currentStep == .destinoA || currentStep == .destinoB {
                // Skip to idiomas after either destination step
                currentStep = .idiomas
            } else {
                currentStep = currentStep.next
            }
        }
    }
    
    private func submitRegistration() {
        isSubmitting = true
        
        Task {
            do {
                let permissions = UserPermissions(
                    location: permisoUbicacion,
                    notifications: permisoNotificaciones,
                    camera: permisoCamara
                )
                
                // Create user account first
                try await authManager.signUpWithOnboarding(
                    email: email,
                    password: password,
                    displayName: nombre,
                    username: username,
                    university: universidadSeleccionada,
                    career: carreraSeleccionada,
                    erasmusStatus: estadoErasmus?.rawValue ?? "",
                    destination: destinoSeleccionado,
                    languages: idiomas,
                    interests: Array(interesesSeleccionados),
                    groupCode: opcionGrupo == .crear ? codigoGrupoGenerado : (opcionGrupo == .unirse ? codigoGrupo : nil),
                    groupType: opcionGrupo?.rawValue,
                    permissions: permissions
                )
                
                // Upload profile image safely to Firebase Storage
                #if canImport(UIKit)
                if let profileImage = profileImage, let uid = authManager.currentUser?.id {
                    do {
                        let urlString = try await UserProfileManager.shared.uploadProfileImage(profileImage, userId: uid)
                        await MainActor.run {
                            authManager.currentUser?.photoURL = urlString
                        }
                    } catch {
                        print("Error uploading profile photo: \(error)")
                    }
                }
                #endif
                
                requestSystemPermissions()
                
                await MainActor.run {
                    isSubmitting = false
                    currentStep = .completado
                }
                
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func requestSystemPermissions() {
        if permisoUbicacion {
            LocationManager.shared.requestAuthorization()
        }
        if permisoNotificaciones {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }
    // MARK: - Validation
    private var canContinue: Bool {
        switch currentStep {
        case .registro1:
            validateFields()
            return !nombre.isEmpty && isValidEmail(email) && isValidPassword(password) && !username.isEmpty
        case .fotoPerfil:
            return true // Optional step
        case .universidad:
            return !universidadSeleccionada.isEmpty && !carreraSeleccionada.isEmpty
        case .estado:
            return estadoErasmus != nil
        case .destinoA, .destinoB:
            return !destinoSeleccionado.isEmpty
        case .idiomas:
            return idiomas.count >= 1 && interesesSeleccionados.count >= 2
        case .grupos:
            if opcionGrupo == .crear {
                return !nombreGrupo.isEmpty
            } else if opcionGrupo == .unirse {
                return !codigoGrupo.isEmpty
            } else {
                return opcionGrupo != nil
            }
        case .permisos:
            return acceptedEULA
        case .verificacion:
            return codigoVerificacion.count == 6 && codigoVerificacion.allSatisfy { $0.isNumber }
        case .completado:
            return true
        }
    }
    private func addLanguage(nivel: String) {
        guard !idiomaEntrada.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            idiomas.append(LanguageLevel(language: idiomaEntrada, level: nivel))
            idiomaEntrada = ""
        }
    }
    
    private func removeLanguage(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            idiomas.remove(at: index)
        }
    }
    
    private func toggleInterest(_ interest: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if interesesSeleccionados.contains(interest) {
                interesesSeleccionados.remove(interest)
            } else {
                interesesSeleccionados.insert(interest)
            }
        }
    }
    
    private func sampleUniversidades() -> [String] {
        ["Universidad de Salamanca", "Universidad Complutense de Madrid", "Universidad de Valencia", "Universidad de Granada", "Universidad de Sevilla", "Universidad de Barcelona"]
    }
    
    private func sampleCarreras() -> [String] {
        ["Ingeniería Informática", "Administración y Dirección de Empresas", "Medicina", "Derecho", "Arquitectura", "Turismo", "Filología", "Biología"]
    }
    
    private func sampleDestinos() -> [String] {
        ["Salamanca", "Madrid", "Barcelona", "Valencia", "Sevilla", "Granada", "Bilbao", "Málaga"]
    }
    
    // MARK: - Validation Functions
    private func validateFields() {
        // Email validation
        if !email.isEmpty {
            if !isValidEmail(email) {
                emailError = "Ingresa un email válido"
            } else {
                emailError = ""
            }
        } else {
            emailError = ""
        }
        
        // Password validation
        if !password.isEmpty {
            if !isValidPassword(password) {
                passwordError = "Mínimo 6 caracteres, 1 mayúscula y 1 número"
            } else {
                passwordError = ""
            }
        } else {
            passwordError = ""
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 6 else { return false }
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasNumber
    }
    
    // MARK: - Foto Perfil View
    private var fotoPerfilView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("📸")
                    .font(.system(size: 60))
                
                Text("Añade tu foto")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Ayuda a otros estudiantes a reconocerte")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                // Profile image preview
                Button(action: {
                    showImageSourceActionSheet = true
                }) {
                    ZStack {
                        #if canImport(UIKit)
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            placeholderProfileImage
                        }
                        #else
                        placeholderProfileImage
                        #endif
                    }
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    #if canImport(UIKit)
                    Button(action: {
                        imageSourceType = .camera
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Cámara")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    

                    
                    Button(action: {
                        imageSourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Galería")
                        }
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(20)
                    }
                    #endif
                }
                
                Text("Puedes omitir este paso y añadir tu foto más tarde")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage, sourceType: imageSourceType)
        }
        .actionSheet(isPresented: $showImageSourceActionSheet) {
            ActionSheet(
                title: Text("Seleccionar foto"),
                message: Text("Elige de dónde quieres obtener tu foto de perfil"),
                buttons: [
                    .default(Text("Cámara")) {
                        imageSourceType = .camera
                        showImagePicker = true
                    },
                    .default(Text("Galería")) {
                        imageSourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel(Text("Cancelar"))
                ]
            )
        }
        #endif
    }

    
    // MARK: - Verification View
    private var verificacionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("📧")
                    .font(.system(size: 60))
                
                Text("Verifica tu cuenta")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Hemos enviado un código de 6 dígitos a \(email)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ModernInputField(
                    title: "Código de verificación",
                    placeholder: "123456",
                    text: $codigoVerificacion,
                    icon: "🔢",
                    keyboardType: .numberPad
                )
                
                Button(action: {
                    // Resend verification code
                }) {
                    Text("¿No recibiste el código? **Reenviar**")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Placeholder
    private var placeholderProfileImage: some View {
        Circle()
            .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 120, height: 120)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Añadir foto")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            )
    }
}

// MARK: - Image Picker
// MARK: - Image Picker
#if canImport(UIKit)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif


// MARK: - Models
enum OnboardingStep: Int, CaseIterable {
    case registro1 = 0, fotoPerfil, universidad, estado, destinoA, destinoB, idiomas, grupos, permisos, verificacion, completado
    
    var title: String {
        switch self {
        case .registro1: return "Crea tu cuenta"
        case .fotoPerfil: return "Foto de perfil"
        case .universidad: return "Tu perfil académico"
        case .estado: return "¿En qué punto estás con tu Erasmus?"
        case .destinoA: return "¿Cuál es tu destino Erasmus?"
        case .destinoB: return "Descubre tu futuro destino"
        case .idiomas: return "Cuéntanos más sobre ti"
        case .grupos: return "¿Vas con alguien más?"
        case .permisos: return "Permisos necesarios"
        case .verificacion: return "Verifica tu cuenta"
        case .completado: return "¡Registro completado!"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .registro1: return "Completa tus datos básicos"
        case .fotoPerfil: return "Añade una foto para que te reconozcan"
        case .universidad: return "Elige tu universidad y carrera"
        case .estado: return "Podrás actualizarlo en cualquier momento"
        case .destinoA: return "Busca o elige tu destino"
        case .destinoB: return "Explora ciudades recomendadas"
        case .idiomas: return "Idiomas e intereses (mínimo 1 y 2)"
        case .grupos: return "Crea o únete a un grupo"
        case .permisos: return "Para una mejor experiencia"
        case .verificacion: return "Hemos enviado un código a tu email"
        case .completado: return nil
        }
    }
    
    var buttonText: String {
        switch self {
        case .permisos: return "Aceptar y continuar"
        case .verificacion: return "Verificar cuenta"
        case .completado: return "¡Vamos allá!"
        default: return "Continuar"
        }
    }
    
    var next: OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? .completado
    }
    
    var previous: OnboardingStep {
        OnboardingStep(rawValue: rawValue - 1) ?? .registro1
    }
}


enum EstadoErasmus: String, CaseIterable {
    case noSe = "no_se"
    case esperando = "esperando"
    case confirmado = "confirmado"
    case enDestino = "en_destino"
    
    var emoji: String {
        switch self {
        case .noSe: return "🔵"
        case .esperando: return "🟡"
        case .confirmado: return "🟢"
        case .enDestino: return "🟣"
        }
    }
    
    var title: String {
        switch self {
        case .noSe: return "No sé a dónde iré aún"
        case .esperando: return "Estoy esperando destino"
        case .confirmado: return "Ya tengo destino confirmado"
        case .enDestino: return "Ya estoy en mi destino"
        }
    }
    
    var subtitle: String {
        switch self {
        case .noSe: return "Estoy empezando a informarme y explorando opciones."
        case .esperando: return "Ya he hecho la solicitud, pero aún no me han confirmado el lugar."
        case .confirmado: return "Sé a qué ciudad iré y quiero empezar a conectar."
        case .enDestino: return "Estoy viviendo el Erasmus ahora mismo."
        }
    }
    
    var color: Color {
        switch self {
        case .noSe: return .blue
        case .esperando: return .orange
        case .confirmado: return .green
        case .enDestino: return .purple
        }
    }
}


enum OpcionGrupo: String, CaseIterable {
    case crear = "crear"
    case unirse = "unirse"
    case solo = "solo"
}

