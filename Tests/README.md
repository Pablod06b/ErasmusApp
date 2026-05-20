# Tests — ErasmusConnect

Estos tests están escritos contra los modelos y utilities de la app. Para ejecutarlos en Xcode:

1. **Crear el target de tests** (una sola vez):
   - Xcode → File → New → Target → **Unit Testing Bundle**
   - Product Name: `Erasmus_AppTests`
   - Target: `Erasmus_App`
   - Language: Swift

2. **Mover/arrastrar los `.swift` de este directorio** dentro del target nuevo en Xcode.

3. **Ejecutar:** Cmd+U (corre todo el bundle de tests).

## Qué cubren

- `FeedBuilderTests.swift` — algoritmos de mezcla del feed (interleaved, shuffledMix determinístico).
- `UserProfileCodableTests.swift` — decode de un perfil sin `blockedUserIds` no debe lanzar (regresión del hotfix #12).
- `PageSizeTests.swift` — los valores no son cero y son razonables.

## Filosofía

Tests de unidad ligeros, sin red ni Firebase. Para probar los managers (que sí dependen de Firestore) habría que hacer mocking del `Firestore.firestore()` que no es trivial — lo dejamos para un sprint posterior cuando se introduzca un protocolo de capa de datos.
