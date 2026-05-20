---
description: Contexto completo para seguir trabajando en ErasmusConnect desde el móvil
---

# /remote-control — Contexto completo de ErasmusConnect

Estoy retomando trabajo en mi app **ErasmusConnect**. Antes de hacer nada nuevo, asume todo este contexto:

## 1. Qué es la app

App iOS SwiftUI + Firebase para estudiantes Erasmus. Funcionalidades core ya hechas:
- Auth (email + Google), onboarding completo
- Feed mixto estilo Instagram (posts + eventos + personas) con chips de ordenación: Recientes / Popular / Para ti / Eventos / Personas
- DMs con imágenes adjuntas + read receipts MVP + push notifications FCM
- Grupos privados (código de invitación) con chat propio
- Perfil completo: editar todos los campos, modal seguidores/seguidos tipo Insta, ShareLink
- Sistema de bloqueo de usuarios (filtros en feed/chat)
- Sistema de guardados (FavoritesView en menú perfil)
- Mapa real con eventos+posts+personas geocodificados desde Firestore, centrado en la ciudad seleccionada
- Eliminar cuenta in-app (Cloud Function deleteUserData)
- Settings completos: Help, Bug report, T&C, Privacy, cambio email, etc.
- AppErrorManager con banner global (3 tonos: error rojo / info azul / success verde)
- NetworkMonitor + banner offline persistente
- Pantallas de error: NoConnectionView, ContentNotAvailableView, AppMaintenanceView, AccountSuspendedView
- Analytics events tipados en AppAnalytics

## 2. Stack y proyecto

- **Bundle ID:** `App.Erasmus-App`
- **Firebase project:** `erasmusconnect-2a003` (cuenta `pablo.dominguez.barbero@gmail.com`)
- **Workspace:** `Erasmus_App.xcworkspace` (CocoaPods)
- **Simulator de prueba:** iPhone 17 Pro `id=85B5B062-780C-42F7-B881-E3CBD7CFF1F2`
- **Ciudades activas:** Salamanca + Madrid solamente. El resto (Barcelona, Valencia, Sevilla, Granada, Roma, París, Berlín, Lisboa, Milán, Ámsterdam) aparecen como "Próximamente" con CTA "Avísame cuando llegue" → guarda en `cityRequests/{ciudad}` con array `userIds` + contador.

## 3. Estructura del repo

```
Erasmus_App/
├── Erasmus_App.xcworkspace           ← workspace que se abre
├── Erasmus_App.xcodeproj/project.pbxproj  ← donde se registran nuevos archivos
├── Podfile, Pods/
├── firebase.json, firestore.rules, storage.rules, .firebaserc
├── functions/index.js                ← Cloud Functions (sendPushOnNotification, onReportCreated, deleteUserData, clearBadgeOnAllRead)
├── Tests/                            ← unit tests (target manual aún)
├── Services/                         ← legacy folder con Auth/Chat/Data managers
├── Sources/ErasmusApp/
│   ├── App/                          ← ContentView, Erasmus_AppApp, NavigationRouter, FirebaseConfig
│   ├── Core/Config/                  ← AppConfig, AvailableCities, PageSize
│   ├── Core/Models/                  ← UserProfile, Models, ChatModels, SocialModels, Group
│   ├── Services/Analytics/AppAnalytics.swift
│   ├── Services/Auth/UserProfileManager.swift
│   ├── Services/Data/CityRequestManager.swift
│   ├── Services/Errors/AppErrorManager.swift
│   ├── Services/Favorites/FavoritesManager.swift
│   ├── Services/Map/GeocodeCache.swift
│   ├── Services/Network/NetworkMonitor.swift
│   ├── Services/Notifications/NotificationManager.swift
│   ├── Services/Social/SocialManager.swift
│   ├── UI/Components/                ← CityPicker, AppStates, FlowLayout
│   ├── UI/ErrorScreens/              ← NoConnectionView, ContentNotAvailableView, AppMaintenanceView, CityComingSoonView
│   ├── UI/Cards/                     ← PostCardView, EventCardView, PersonCardView
│   └── Features/
│       ├── Auth/Onboarding/          ← ModernOnboardingFlow + componentes
│       ├── Chat/ChatView.swift       ← ChatView + ChatDetailView + MessageInputBar + UserAvatarView
│       ├── Events/                   ← EventCreateView, EventDetailView
│       ├── Explore/ExploreView.swift
│       ├── Groups/                   ← MyGroupView, GroupDetailView, GroupChatView, GroupCreateView, GroupJoinView, GroupFeaturesView
│       ├── Home/HomeView.swift       ← HomeView + HomeTabView (mixed feed) + FeedSortMode + FeedItem + FeedPostCard + FeedEventCard + FeedPersonCard + ModernHeaderView + Tab + ModernBottomNavigationView
│       ├── Map/SocialMapView.swift
│       ├── Notifications/NotificationsView.swift
│       ├── Plans/OpenPlanDetailView.swift
│       ├── Post/                     ← CreatePostView, ModernCreatePostView, PostDetailView
│       ├── Profile/                  ← UserProfileView (+EditProfileView), SettingsView, BlockedUsersView, SupportViews, EmailChangeView, DeleteAccountView, FollowListView
│       └── Social/FriendRequestsView.swift
```

## 4. Cómo trabajo (CONVENCIONES OBLIGATORIAS)

- **Branch:** todo el trabajo va en `claude/cranky-kilby-42a280` (worktree en `.claude/worktrees/cranky-kilby-42a280/`).
- **Edición:** edito siempre los archivos en la raíz del repo (`Sources/...`), NO directamente en el worktree.
- **Después de cada cambio:**
  1. Si añado un archivo Swift nuevo → registrar en `Erasmus_App.xcodeproj/project.pbxproj` (PBXBuildFile + PBXFileReference + PBXGroup + Sources build phase). Usar UUIDs nuevos con prefijo libre (ej `C01234560000000000000001`).
  2. Build:
     ```
     cd /Users/administrador/Desktop/Trabajo/ErasmusApp/Erasmus_App
     xcodebuild -workspace Erasmus_App.xcworkspace -scheme Erasmus_App -destination 'id=85B5B062-780C-42F7-B881-E3CBD7CFF1F2' -configuration Debug build > /tmp/build.log 2>&1
     ```
     Tarda 3-6 min en arrancar el log; uso `Monitor` con `until grep -qE "BUILD SUCCEEDED|BUILD FAILED" /tmp/build.log; do sleep 15; done`.
  3. Sync al worktree, commit con mensaje descriptivo (formato `feat:` / `fix:` / `feat(módulo):`) y push a `claude/cranky-kilby-42a280`. Pie:
     ```
     Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
     ```

- **Firebase CLI:** instalado en `~/.npm-global/bin/firebase`. Login OK con `pablo.dominguez.barbero@gmail.com`. Para deploy:
  ```
  cd /Users/administrador/Desktop/Trabajo/ErasmusApp/Erasmus_App
  export PATH="$HOME/.npm-global/bin:$PATH"
  firebase deploy --only firestore:rules          # rules
  firebase deploy --only functions                # cloud functions (Node 20)
  ```
- **Errores comunes:**
  - `xcodebuild` falla si se ejecuta desde el worktree (no tiene Pods). Siempre `cd` a la raíz primero.
  - `AppErrorManager.shared.report` es `@MainActor`; si lo llamas desde código no-MainActor, envuélvelo en `await MainActor.run { ... }`.
  - Si añado un campo nuevo a `UserProfile`, **debe ser opcional** (`Type?`) para no romper el decode de perfiles antiguos en Firestore (regresión del hotfix #12).
  - `Evento` no es Equatable: para `onChange(of:)` usar `events.count` en su lugar.

## 5. Estado en producción AHORA

- ✅ Firestore rules desplegadas (14 colecciones + subcolecciones cubiertas)
- ✅ Storage rules desplegadas (validación tipo imagen + tamaño)
- ✅ 4 Cloud Functions activas:
  - `sendPushOnNotification` (europe-southwest1) — trigger Firestore
  - `clearBadgeOnAllRead` (europe-southwest1) — placeholder
  - `onReportCreated` (europe-southwest1) — trigger Firestore con counter en moderationStats
  - `deleteUserData` (us-central1) — HTTP en `https://deleteuserdata-7wqffoff5q-uc.a.run.app` (público con Bearer token de Firebase Auth)

## 6. Cosas pendientes que ya están en el roadmap

Si me dices "sigue" o "qué pendientes hay", estos quedaron sin atacar:

- **Mejorar Explorar** (no prioritario): añadir más guías de ciudades, contenido extra, rediseño potencial
- **Crashlytics activo** — `pod 'Firebase/Crashlytics'` está comentado en Podfile; requiere `pod install` + script de upload-dSYMs en Xcode UI
- **Slack/Discord webhook** para `onReportCreated`: `firebase functions:secrets:set MODERATION_WEBHOOK_URL`
- **Vista admin/moderación** dentro de la app para revisar reports y banear
- **Notificaciones email** (welcome, weekly digest) vía SendGrid/Brevo
- **Stats personal** del usuario (mis posts, gente vista este mes…)
- **i18n** (descartado por decisión: solo España de momento)
- **Tests en Xcode**: el target hay que crearlo manualmente (`Tests/README.md`)

## 7. Mi próxima petición

(Aquí escribe lo que quieras que haga ahora. Si no escribes nada, lista las cosas pendientes y pregúntame por dónde sigo.)
