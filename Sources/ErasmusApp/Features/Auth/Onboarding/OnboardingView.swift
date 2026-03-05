
import SwiftUI
import PhotosUI

// Simple local storage for user data
class OldUserDataManager: ObservableObject {
    @Published var currentUser: OldUserProfile?
    
    struct OldUserProfile: Codable {
        let id: String
        var name: String
        var interests: [String]
        var destination: String
        var photoURL: String?
        var onboardingCompleted: Bool
    }
    
    func saveUserProfile(_ profile: OldUserProfile) {
        // Save to UserDefaults for now
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile_\(profile.id)")
        }
    }
    
    func loadUserProfile(id: String) -> OldUserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile_\(id)"),
              let profile = try? JSONDecoder().decode(OldUserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    func createUserProfile(id: String, name: String) -> OldUserProfile {
        let profile = OldUserProfile(
            id: id,
            name: name,
            interests: [],
            destination: "Salamanca",
            photoURL: nil,
            onboardingCompleted: false
        )
        saveUserProfile(profile)
        return profile
    }
}

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var selectedInterests: Set<String> = []
    @State private var selectedDestination = "Salamanca"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoURL: String?
    @State private var isLoading = false
    @State private var userName: String = ""
    @StateObject private var userDataManager = OldUserDataManager()
    @Environment(\.dismiss) var dismiss

    let interests = ["Fiestas", "Viajes", "Cultura", "Deportes", "Música", "Comida", "Estudio"]
    let destinations = ["Salamanca", "Madrid"] // Ajusta según tu lista

    var body: some View {
        TabView(selection: $currentStep) {
            // Pantalla 1: Bienvenida
            VStack(spacing: 20) {
                Text("¡Bienvenido, \(userName)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Erasmus Connect te ayuda a conectar con otros estudiantes, crear eventos y descubrir planes increíbles.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                Button(action: { withAnimation { currentStep += 1 } }) {
                    Text("Comenzar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .tag(0)

            // Pantalla 2: Selección de intereses
            VStack(spacing: 20) {
                Text("Selecciona tus intereses")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Elige al menos 3 intereses para personalizar tu experiencia.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(interests, id: \.self) { interest in
                            Button(action: {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }) {
                                Text(interest)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(selectedInterests.contains(interest) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedInterests.contains(interest) ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Button(action: { withAnimation { currentStep += 1 } }) {
                    Text("Siguiente")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedInterests.count >= 3 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedInterests.count < 3)
                .padding(.horizontal)
            }
            .padding()
            .tag(1)

            // Pantalla 3: Foto de perfil
            VStack(spacing: 20) {
                Text("Añade una foto de perfil")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Sube una foto para que otros te reconozcan.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    #if canImport(UIKit)
                    if let photoURL = photoURL, let url = URL(string: photoURL), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.gray)
                    }
                    #else
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                    #endif
                }
                Button(action: { withAnimation { currentStep += 1 } }) {
                    Text("Siguiente")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(photoURL != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(photoURL != nil)
                .padding(.horizontal)
            }
            .padding()
            .tag(2)
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    #if canImport(UIKit)
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        isLoading = true
                        savePhotoLocally(uiImage: uiImage) { url in
                            self.photoURL = url
                            isLoading = false
                        }
                    }
                    #endif
                }
            }

            // Pantalla 4: Selección de destino
            VStack(spacing: 20) {
                Text("Elige tu destino")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Selecciona tu ciudad principal para ver eventos y posts relevantes.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Destino", selection: $selectedDestination) {
                    ForEach(destinations, id: \.self) { city in
                        Text(city).tag(city)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                Button(action: { saveOnboardingData() }) {
                    Text("Finalizar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .tag(3)
        }
        #if os(iOS)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        #endif
        .onAppear {
            // Get user name from local storage
            if let userId = UserDefaults.standard.string(forKey: "currentUserId"),
               let profile = userDataManager.loadUserProfile(id: userId) {
                self.userName = profile.name
            } else {
                // Create a default user for demo purposes
                let defaultProfile = userDataManager.createUserProfile(id: "demo_user", name: "Usuario")
                self.userName = defaultProfile.name
                UserDefaults.standard.set("demo_user", forKey: "currentUserId")
            }
        }
        .overlay(
            isLoading ? ProgressView().progressViewStyle(.circular) : nil
        )
    }

    #if canImport(UIKit)
    private func savePhotoLocally(uiImage: UIImage, completion: @escaping (String?) -> Void) {
        // Save photo to local documents directory
        if let data = uiImage.jpegData(compressionQuality: 0.8) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let photoPath = documentsPath.appendingPathComponent("profile_photo.jpg")
            
            do {
                try data.write(to: photoPath)
                completion(photoPath.absoluteString)
            } catch {
                print("Error saving photo: \(error)")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    #endif

    private func saveOnboardingData() {
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId") else { return }
        
        if var profile = userDataManager.loadUserProfile(id: userId) {
            profile.interests = Array(selectedInterests)
            profile.destination = selectedDestination
            profile.photoURL = photoURL
            profile.onboardingCompleted = true
            userDataManager.saveUserProfile(profile)
        }
        
        dismiss()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

