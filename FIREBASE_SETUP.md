# 🔥 Configuración de Firebase para Erasmus App

## 📋 Requisitos Previos

- Cuenta de Google
- Xcode 15.0+
- iOS 15.0+ como target mínimo
- Proyecto Firebase creado

## 🚀 Pasos para Configurar Firebase

### 1. Crear Proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Haz clic en **"Crear un proyecto"**
3. Ingresa un nombre para tu proyecto (ej: "Erasmus App")
4. Opcional: Habilita Google Analytics
5. Haz clic en **"Crear proyecto"**

### 2. Configurar App iOS

1. En la consola de Firebase, haz clic en el ícono de iOS
2. Ingresa tu **Bundle ID**: `App.Erasmus-App`
3. Opcional: Ingresa un nombre para la app
4. Haz clic en **"Registrar app"**

### 3. Descargar Configuración

1. Descarga el archivo `GoogleService-Info.plist`
2. **NO** lo abras con un editor de texto
3. Arrastra el archivo al proyecto Xcode

### 4. Agregar al Proyecto Xcode

1. Abre tu proyecto en Xcode
2. Arrastra `GoogleService-Info.plist` a la carpeta raíz del proyecto
3. **IMPORTANTE**: Asegúrate de que esté marcado para el target principal
4. Verifica que aparezca en el proyecto

### 5. Verificar Bundle ID

1. En Xcode, selecciona tu target
2. Ve a **"Signing & Capabilities"**
3. Verifica que el **Bundle Identifier** sea `App.Erasmus-App`
4. Si es diferente, actualízalo para que coincida con Firebase

## 📱 Servicios Configurados

### ✅ Firebase Authentication
- **Email/Password**: Implementado y funcional
- **Google Sign-In**: Preparado para implementar
- **Apple Sign-In**: Preparado para implementar

### ✅ Cloud Firestore
- Base de datos en tiempo real
- Estructura de usuarios y posts
- Reglas de seguridad configuradas

### ✅ Firebase Storage
- Almacenamiento de fotos de perfil
- Almacenamiento de imágenes de posts
- Reglas de seguridad configuradas

## 🔐 Configuración de Autenticación

### 1. Habilitar Email/Password

1. En Firebase Console, ve a **Authentication**
2. Haz clic en **"Sign-in method"**
3. Habilita **"Email/Password"**
4. Opcional: Habilita **"Email link (passwordless sign-in)"**

### 2. Habilitar Google Sign-In (Opcional)

1. En **Sign-in method**, habilita **"Google"**
2. Agrega tu **Support email**
3. Guarda los cambios

### 3. Habilitar Apple Sign-In (Opcional)

1. En **Sign-in method**, habilita **"Apple"**
2. Configura tu **Apple Developer Account**
3. Guarda los cambios

## 🗄️ Configuración de Firestore

### 1. Crear Base de Datos

1. En Firebase Console, ve a **Firestore Database**
2. Haz clic en **"Crear base de datos"**
3. Selecciona **"Comenzar en modo de prueba"**
4. Elige la ubicación más cercana a tus usuarios

### 2. Estructura de Datos

La app está configurada para usar esta estructura:

```
users/
  {userId}/
    id: string
    email: string
    displayName: string
    createdAt: timestamp
    lastLogin: timestamp
    interests: array
    destination: string
    photoURL: string
    onboardingCompleted: boolean

posts/
  {postId}/
    id: string
    userId: string
    type: string
    title: string
    description: string
    location: string
    destination: string
    date: timestamp
    imageURL: string
    createdAt: timestamp
```

### 3. Reglas de Seguridad

Copia estas reglas en **Firestore > Reglas**:

```javascript
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
```

## 📁 Configuración de Storage

### 1. Habilitar Storage

1. En Firebase Console, ve a **Storage**
2. Haz clic en **"Comenzar"**
3. Selecciona **"Comenzar en modo de prueba"**
4. Elige la ubicación más cercana a tus usuarios

### 2. Reglas de Seguridad

Copia estas reglas en **Storage > Reglas**:

```javascript
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
```

## 🧪 Probar la Configuración

### 1. Ejecutar la App

1. Compila y ejecuta la app en el simulador
2. Deberías ver en la consola: `🔥 Firebase configurado exitosamente`
3. La app debería mostrar la pantalla de login moderna

### 2. Crear Usuario de Prueba

1. Toca **"Crear cuenta"**
2. Completa el formulario de registro
3. Verifica que se cree el usuario en Firebase Console

### 3. Verificar Datos

1. En Firebase Console, ve a **Authentication**
2. Deberías ver tu usuario creado
3. En **Firestore**, deberías ver el perfil del usuario

## ⚠️ Solución de Problemas

### Error: "Firebase not configured"

**Solución:**
- Verifica que `GoogleService-Info.plist` esté en el proyecto
- Asegúrate de que esté marcado para el target principal
- Verifica que el Bundle ID coincida

### Error: "Permission denied"

**Solución:**
- Verifica las reglas de Firestore y Storage
- Asegúrate de que el usuario esté autenticado
- Revisa que las reglas permitan la operación

### Error: "Network error"

**Solución:**
- Verifica tu conexión a internet
- Asegúrate de que Firebase esté habilitado en tu proyecto
- Verifica que no haya restricciones de firewall

## 🎯 Próximos Pasos

### Implementaciones Futuras

1. **Google Sign-In**
   - Configurar Google Cloud Console
   - Implementar en la app

2. **Apple Sign-In**
   - Configurar Apple Developer Account
   - Implementar en la app

3. **Push Notifications**
   - Configurar APNs
   - Implementar notificaciones push

4. **Analytics**
   - Habilitar Firebase Analytics
   - Implementar eventos personalizados

## 📞 Soporte

Si tienes problemas:

1. Revisa la [documentación oficial de Firebase](https://firebase.google.com/docs)
2. Consulta el [foro de Firebase](https://firebase.google.com/community)
3. Revisa los logs de la consola de Xcode
4. Verifica la consola de Firebase para errores

---

**¡Firebase está configurado y listo para usar! 🚀**

La app ahora tiene:
- ✅ Autenticación moderna y segura
- ✅ Base de datos en tiempo real
- ✅ Almacenamiento de archivos
- ✅ UI/UX elegante y intuitiva
- ✅ Manejo de errores robusto
- ✅ Arquitectura escalable
