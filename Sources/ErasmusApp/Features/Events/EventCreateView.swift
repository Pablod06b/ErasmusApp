// EventCreateView.swift
import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct EventCreateView: View {
    @Environment(\.dismiss) var dismiss

    // Form fields
    @State private var title = ""
    @State private var eventDescription = ""
    @State private var location = ""
    @State private var city = "Salamanca"
    @State private var category = "Social"
    @State private var date = Date()
    @State private var isPaid = false
    @State private var price = ""

    // Image
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    // State
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private let cities = ["Salamanca", "Madrid", "Barcelona", "Valencia", "Roma",
                          "París", "Berlín", "Lisboa", "Milán", "Ámsterdam",
                          "Praga", "Viena", "Budapest", "Varsovia", "Dublín"]

    private let categories = ["Social", "Deporte", "Cultura", "Música",
                               "Gastronomía", "Tecnología", "Arte", "Naturaleza", "Otro"]

    var canPublish: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        !(isPaid && price.isEmpty)
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: Basic Info
                Section {
                    TextField("Título del evento", text: $title)
                    TextField("Descripción (opcional)", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Label("Información básica", systemImage: "calendar.badge.plus")
                }

                // MARK: Location & Date
                Section {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        TextField("Dirección o lugar", text: $location)
                    }

                    HStack {
                        Image(systemName: "globe.europe.africa")
                            .foregroundColor(.blue)
                        Picker("Ciudad", selection: $city) {
                            ForEach(cities, id: \.self) { Text($0).tag($0) }
                        }
                    }

                    DatePicker("Fecha y hora", selection: $date,
                               in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Label("Lugar y fecha", systemImage: "location")
                }

                // MARK: Category
                Section {
                    Picker("Categoría", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Categoría", systemImage: "tag")
                }

                // MARK: Price
                Section {
                    Toggle(isOn: $isPaid) {
                        Label("Evento de pago", systemImage: "eurosign.circle")
                    }
                    if isPaid {
                        HStack {
                            Image(systemName: "eurosign")
                                .foregroundColor(.green)
                            TextField("Precio", text: $price)
                                .keyboardType(.decimalPad)
                        }
                    }
                } header: {
                    Label("Precio", systemImage: "creditcard")
                }

                // MARK: Image
                Section {
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(10)
                            .listRowInsets(EdgeInsets())
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(selectedImage == nil ? "Añadir imagen" : "Cambiar imagen",
                              systemImage: "photo.badge.plus")
                    }
                } header: {
                    Label("Imagen", systemImage: "photo")
                }
            }
            .navigationTitle("Nuevo Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Publicar") {
                            Task { await publishEvent() }
                        }
                        .fontWeight(.semibold)
                        .disabled(!canPublish)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("¡Evento publicado!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Tu evento ya está visible para la comunidad.")
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        selectedImage = uiImg
                    }
                }
            }
        }
    }

    // MARK: - Publish

    private func publishEvent() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Debes estar autenticado para publicar."
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Upload image if selected
            var imageURL: String? = nil
            if let img = selectedImage {
                imageURL = try await uploadImage(img, uid: uid)
            }

            // 2. Format date as string
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_ES")
            let dateString = formatter.string(from: date)

            // 3. Build Firestore doc
            let db = Firestore.firestore()
            let ref = db.collection("events").document()

            let data: [String: Any] = [
                "id": ref.documentID,
                "title": title.trimmingCharacters(in: .whitespaces),
                "eventDescription": eventDescription.trimmingCharacters(in: .whitespaces),
                "location": location.trimmingCharacters(in: .whitespaces),
                "city": city,
                "category": category,
                "date": dateString,
                "timestamp": Timestamp(date: date),
                "isPaid": isPaid,
                "price": isPaid ? (Double(price) ?? 0.0) : 0.0,
                "userId": uid,
                "imageName": "calendar",
                "imageURL": imageURL as Any,
                "isVerifiedBusiness": false,
                "isPromoted": false,
                "participants": 0,
                "createdAt": Timestamp(date: Date())
            ]

            try await ref.setData(data)

            showSuccess = true
        } catch {
            errorMessage = "No se pudo publicar el evento. Comprueba tu conexión."
            showError = true
        }
    }

    private func uploadImage(_ image: UIImage, uid: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw URLError(.cannotDecodeContentData)
        }
        let storageRef = Storage.storage().reference()
            .child("events/\(uid)/\(UUID().uuidString).jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await storageRef.putDataAsync(data, metadata: meta)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
}
