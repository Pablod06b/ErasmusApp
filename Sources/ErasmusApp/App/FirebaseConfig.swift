import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firebase Configuration
struct FirebaseConfig {

    // MARK: - Configuration
    static func configure() {
        // Check if Firebase is already configured
        guard FirebaseApp.app() == nil else { return }

        // Configure Firebase
        FirebaseApp.configure()

        // Habilitar persistencia offline de Firestore (la app funciona sin red)
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024)) // 100 MB
        Firestore.firestore().settings = settings

        // En simulator desactivamos la verificación del dispositivo para Phone Auth.
        // Esto exige usar números de prueba configurados en Firebase Console
        // (Authentication > Settings > Phone numbers for testing).
        // En device real (DEBUG y RELEASE) la verificación silenciosa funciona normalmente.
        #if targetEnvironment(simulator)
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        print("📱 Simulator detectado: usar números de prueba para Phone Auth")
        #endif

        print("🔥 Firebase configurado con persistencia offline (cache 100 MB)")
    }
    
    // MARK: - Project Configuration
    // Para configurar Firebase, necesitas:
    // 1. Crear un proyecto en Firebase Console (https://console.firebase.google.com)
    // 2. Agregar una app iOS con tu Bundle ID
    // 3. Descargar el archivo GoogleService-Info.plist
    // 4. Agregarlo al proyecto Xcode
    
    // MARK: - Bundle ID Configuration
    // Asegúrate de que tu Bundle ID en Xcode coincida con el configurado en Firebase
    // Bundle ID actual: App.Erasmus-App
    
    // MARK: - Services to Enable
    // Los siguientes servicios están configurados en el proyecto:
    // ✅ Firebase Authentication - Para login/registro
    // ✅ Cloud Firestore - Para base de datos
    // ✅ Firebase Storage - Para archivos e imágenes
    
    // MARK: - Authentication Methods
    // Métodos de autenticación configurados:
    // ✅ Email/Password
    // 🔄 Google Sign-In (preparado para implementar)
    // 🔄 Apple Sign-In (preparado para implementar)
    
    // MARK: - Security Rules
    // Reglas de seguridad recomendadas para Firestore:
    /*
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        // Usuarios solo pueden leer/escribir sus propios datos
        match /users/{userId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
        
        // Posts públicos para todos los usuarios autenticados
        match /posts/{postId} {
          allow read: if request.auth != null;
          allow write: if request.auth != null;
        }
      }
    }
    */
    
    // MARK: - Storage Rules
    // Reglas de seguridad recomendadas para Storage:
    /*
    rules_version = '2';
    service firebase.storage {
      match /b/{bucket}/o {
        // Usuarios solo pueden subir archivos a su carpeta
        match /profile_photos/{userId}/{allPaths=**} {
          allow read: if request.auth != null;
          allow write: if request.auth != null && request.auth.uid == userId;
        }
        
        // Posts de imágenes para usuarios autenticados
        match /post_images/{allPaths=**} {
          allow read: if request.auth != null;
          allow write: if request.auth != null;
        }
      }
    }
    */
}

// MARK: - Environment Configuration
enum AppEnvironment {
    case development
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var firebaseProjectID: String {
        switch self {
        case .development:
            return "erasmus-app-dev" // Cambiar por tu Project ID de desarrollo
        case .production:
            return "erasmus-app-prod" // Cambiar por tu Project ID de producción
        }
    }
}

// MARK: - Usage Instructions
/*
 
 🔥 CÓMO CONFIGURAR FIREBASE:
 
 1. Ve a https://console.firebase.google.com
 2. Crea un nuevo proyecto o selecciona uno existente
 3. Haz clic en "Agregar app" y selecciona iOS
 4. Ingresa tu Bundle ID: App.Erasmus-App
 5. Descarga el archivo GoogleService-Info.plist
 6. Arrastra el archivo al proyecto Xcode (asegúrate de que esté en el target principal)
 7. En Xcode, ve a tu target y en "Signing & Capabilities" verifica que el Bundle ID coincida
 8. Ejecuta la app - Firebase se configurará automáticamente
 
 📱 SERVICIOS CONFIGURADOS:
 - Authentication: Login/registro con email y contraseña
 - Firestore: Base de datos en tiempo real
 - Storage: Almacenamiento de archivos e imágenes
 
 🔐 MÉTODOS DE AUTENTICACIÓN:
 - Email/Password (implementado)
 - Google Sign-In (preparado)
 - Apple Sign-In (preparado)
 
 ⚠️ IMPORTANTE:
 - Asegúrate de que GoogleService-Info.plist esté en el proyecto
 - Verifica que el Bundle ID coincida en Firebase y Xcode
 - Las reglas de seguridad están comentadas arriba para referencia
 
 */
