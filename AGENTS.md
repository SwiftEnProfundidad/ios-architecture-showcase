# AGENTS.md — ios-architecture-showcase

PROJECT MODE: greenfield

## Skills requeridas

REQUIRED SKILL: enterprise-operating-system
REQUIRED SKILL: ios-enterprise-rules
REQUIRED SKILL: swift-concurrency
REQUIRED SKILL: swiftui-expert-skill

## Fuente de verdad

- Especificaciones BDD: `docs/features/`
- Arquitectura: este fichero + `Package.swift`
- Bounded contexts: Auth, Flights, BoardingPass, Shared/Navigation

## Comando de validación local

```bash
swift build -c debug && swift test --parallel
```

## Bounded contexts

| Context | Responsabilidad |
|---|---|
| Auth | Autenticación de pasajero, gestión de sesión con actor |
| Flights | Consulta y caché de vuelos, concurrencia estructurada |
| BoardingPass | Tarjeta de embarque, interop UIKit |
| Shared/Navigation | Event bus + reducer + coordinator (TCA-inspired, sin TCA) |

## Reglas de dependencias entre features

- Las features NO se importan entre sí
- Solo se comparte `Shared/Kernel` (tipos mínimos)
- `Shared/Navigation` es consumido por todas las features (solo lectura de eventos)
- `AppComposition` es el único punto que conoce todas las features

## Reglas de implementación (no negociables)

- BDD → TDD: feature file → test en rojo → código mínimo → refactor
- Swift 6.2, strict concurrency, cero warnings
- Swift Testing (`@Test`, `#expect`) para todos los tests
- `@Observable` + `@MainActor` justificado para ViewModels
- Generics con protocolos de frontera, prohibido `any`
- Prohibido `DispatchQueue`, `print()`, `AnyView`, `ObservableObject`
- Prohibido `!` force unwrap
- Sin comentarios en código — nombres autodescriptivos
- `os.Logger` para logging
- `String Catalogs` para todos los strings de UI
- Accessibility labels obligatorios en todas las vistas
- Cero dependencias de terceros

## Gates antes de cerrar un slice

- [ ] Feature file BDD escrito y revisado
- [ ] Tests en rojo antes de código de producción
- [ ] `swift build` sin errores ni warnings
- [ ] `swift test --parallel` en verde
- [ ] Sin violaciones de las reglas de este fichero
