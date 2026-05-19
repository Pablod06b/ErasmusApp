// SupportViews.swift — vistas de soporte e información legal
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Help Center
struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Preguntas frecuentes") {
                HelpItem(question: "¿Cómo creo un post?", answer: "Pulsa el botón + en la parte superior de Inicio y elige el tipo de publicación: recomendación, evento, plan abierto, anuncio o mensaje libre.")
                HelpItem(question: "¿Cómo cambio mi destino Erasmus?", answer: "Ve a tu perfil → menú de tres puntos → Editar perfil → cambia el campo Destino.")
                HelpItem(question: "¿Cómo bloqueo a alguien?", answer: "Abre su perfil, pulsa los tres puntos arriba a la derecha y elige Bloquear. Dejará de ver tus posts y no podrá enviarte mensajes.")
                HelpItem(question: "¿Cómo me uno a un evento?", answer: "Pulsa el evento en el feed y luego el botón Apuntarme. Verás los demás asistentes y la ubicación.")
                HelpItem(question: "¿Cómo creo o me uno a un grupo?", answer: "En tu perfil verás tu grupo actual. Si no tienes, puedes crear uno nuevo o unirte usando un código de invitación.")
            }
            Section("Necesitas ayuda?") {
                Link(destination: URL(string: "mailto:soporte@erasmusconnect.app")!) {
                    Label("Escríbenos a soporte@erasmusconnect.app", systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle("Centro de ayuda")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelpItem: View {
    let question: String
    let answer: String
    @State private var expanded = false
    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Text(answer).font(.subheadline).foregroundColor(.secondary)
                .padding(.top, 4)
        } label: {
            Text(question).font(.subheadline).fontWeight(.medium)
        }
    }
}

// MARK: - Bug Report
struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isSending = false
    @State private var sent = false

    var canSend: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section(header: Text("Describe el problema")) {
                TextField("Título corto", text: $title)
                TextField("¿Qué ha pasado?", text: $description, axis: .vertical)
                    .lineLimit(5...10)
            }
            Section {
                Button(action: send) {
                    HStack {
                        if isSending { ProgressView() }
                        Text(sent ? "¡Reporte enviado!" : "Enviar reporte")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!canSend || isSending || sent)
            }
            if sent {
                Section {
                    Text("Gracias por ayudarnos a mejorar la app.")
                        .font(.footnote).foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Reportar un problema")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        isSending = true
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "title": title,
            "description": description,
            "userId": Auth.auth().currentUser?.uid ?? "anon",
            "createdAt": FieldValue.serverTimestamp(),
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        ]
        db.collection("bugReports").addDocument(data: data) { error in
            isSending = false
            if error == nil {
                sent = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } else {
                AppErrorManager.shared.report("No se pudo enviar el reporte. Inténtalo más tarde.")
            }
        }
    }
}

// MARK: - Terms & Conditions
struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Términos y Condiciones")
                    .font(.title2).fontWeight(.bold)
                Text("Última actualización: mayo de 2026")
                    .font(.caption).foregroundColor(.secondary)

                Group {
                    sectionTitle("1. Aceptación de los términos")
                    Text("Al usar ErasmusConnect aceptas estos términos en su totalidad. Si no estás de acuerdo, no utilices la aplicación.")

                    sectionTitle("2. Uso del servicio")
                    Text("La app está pensada para estudiantes Erasmus y otros usuarios universitarios. Debes tener al menos 16 años para usarla. Eres responsable de la información que publicas y del trato hacia otros usuarios.")

                    sectionTitle("3. Contenido")
                    Text("No puedes publicar contenido ilegal, ofensivo, discriminatorio, sexual sin consentimiento, ni hacer spam comercial sin permiso. Nos reservamos el derecho a eliminar contenido y suspender cuentas que infrinjan estas normas.")

                    sectionTitle("4. Propiedad intelectual")
                    Text("Tú mantienes la propiedad del contenido que subes, pero nos concedes licencia no exclusiva para mostrarlo dentro de la app a otros usuarios.")

                    sectionTitle("5. Limitación de responsabilidad")
                    Text("ErasmusConnect facilita la conexión entre usuarios pero no se responsabiliza de los encuentros, transacciones o acuerdos entre ellos. Verifica la identidad de la gente que conozcas a través de la app.")

                    sectionTitle("6. Cambios en los términos")
                    Text("Podemos actualizar estos términos. Te avisaremos por la propia app cuando haya cambios sustanciales.")
                }

                Text("Contacto: soporte@erasmusconnect.app")
                    .font(.footnote).foregroundColor(.secondary)
                    .padding(.top, 12)
            }
            .padding(20)
        }
        .navigationTitle("Términos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).font(.headline).padding(.top, 8)
    }
}

// MARK: - Privacy Policy
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Política de Privacidad")
                    .font(.title2).fontWeight(.bold)
                Text("Última actualización: mayo de 2026")
                    .font(.caption).foregroundColor(.secondary)

                Group {
                    sectionTitle("Qué datos recogemos")
                    Text("Email, nombre, universidad, destino, intereses, idiomas, foto de perfil y bio que tú nos proporcionas. Adicionalmente: posts, eventos, mensajes y reacciones que generas en la app.")

                    sectionTitle("Cómo los usamos")
                    Text("Para mostrarte a otros usuarios, sugerirte gente cercana y enviarte notificaciones relevantes. No vendemos tus datos a terceros.")

                    sectionTitle("Compartición con terceros")
                    Text("Usamos Firebase (Google) para autenticación, almacenamiento y notificaciones. Esos datos se procesan según la política de privacidad de Google.")

                    sectionTitle("Tus derechos")
                    Text("Puedes ver, modificar y eliminar tus datos en cualquier momento desde Ajustes. También puedes solicitar la eliminación total de tu cuenta, lo que borra de forma irreversible todos tus contenidos.")

                    sectionTitle("Conservación")
                    Text("Mantenemos tus datos mientras tu cuenta esté activa. Tras eliminar la cuenta, los datos personales se borran en 30 días, salvo cuando la ley nos obligue a conservarlos más tiempo.")

                    sectionTitle("Contacto")
                    Text("Para cualquier consulta sobre privacidad escríbenos a privacidad@erasmusconnect.app")
                }
            }
            .padding(20)
        }
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).font(.headline).padding(.top, 8)
    }
}
