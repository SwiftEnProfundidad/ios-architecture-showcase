# iOS Architecture Showcase

[![CI](https://github.com/SwiftEnProfundidad/ios-architecture-showcase/actions/workflows/ci.yml/badge.svg)](https://github.com/SwiftEnProfundidad/ios-architecture-showcase/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B%20%7C%20macOS%2014%2B-blue.svg)](https://developer.apple.com/)

Proyecto de demostración que implementa una app iOS de gestión de vuelos y tarjeta de embarque. Construido con disciplina de ingeniería enterprise: **BDD → TDD → código de producción**, Clean Architecture feature-first y event-driven navigation inspirada en TCA, sin dependencias de terceros.

---

## Stack técnico demostrado

| Tecnología | Implementación |
|---|---|
| **Swift 6.0** | `swift-tools-version: 6.0`, strict concurrency activado |
| **SwiftUI** | `@Observable`, `@MainActor`, `NavigationStack`, `navigationDestination` |
| **UIKit interop** | `UIViewControllerRepresentable` en `QRCodeView` (CoreImage QR) |
| **async/await** | Todos los use cases, repositorios y ViewModels |
| **Structured concurrency** | `async let` en `GetFlightDetailUseCase`, `TaskGroup` en `ListFlightsUseCase.refreshAll` |
| **actors** | `AppStateStore`, `AppCoordinator`, `DefaultNavigationEventBus` (state), `InMemorySessionStore`, spies de test |
| **Sendable** | Todos los tipos de dominio, protocolos de repositorio y eventos |
| **@MainActor** | ViewModels y `AppCoordinator` (justificado: actualizan UI) |
| **Arquitectura Hexagonal** | Ports en domain (`AuthGatewayProtocol`, `FlightRepositoryProtocol`), adapters en infrastructure |
| **Clean Architecture modular** | Feature-first: Auth / Flights / BoardingPass / SharedNavigation / SharedKernel |
| **SOLID** | SRP: un use case = una responsabilidad; ISP: protocolos segregados por capacidad |
| **Protocol-Oriented Programming** | Todos los contratos son protocolos `Sendable`; generics en use cases |
| **Dependency Injection** | Constructor injection vía `CompositionRoot` (sin Singletons) |
| **MVVM** | `@Observable @MainActor` ViewModels; vistas sin lógica de negocio |
| **Event-driven navigation (TCA-inspired)** | `NavigationEvent` → `AppReducer` → `AppStateStore` → `AppViewModel` |
| **XCTest** | Tests de actores e infraestructura (SessionStore, FlightCache) |
| **Swift Testing** | `@Test`, `#expect`, `@Suite` en todos los tests de dominio y aplicación |
| **GitHub Actions CI** | `swift build` + `swift test --parallel` en macOS 15 / Xcode 16 |
| **String Catalogs** | `Localizable.xcstrings` con todas las cadenas de UI |
| **Accessibility** | `accessibilityLabel`, `accessibilityAddTraits` en todas las vistas |

---

## Arquitectura de navegación (TCA-inspired sin TCA)

```
NavigationEvent (enum Sendable)
    │
    ▼
DefaultNavigationEventBus (actor + AsyncStream)
    │
    ▼
AppCoordinator (actor — escucha stream)
    │
    ▼
AppReducer (struct puro — reduce(state, event) → state)
    │
    ▼
AppStateStore (actor — guarda estado)
    │
    ▼
AppViewModel (@MainActor @Observable — expone activeRoute)
    │
    ▼
RootView (switch sobre activeRoute → SwiftUI)
```

| Concepto TCA | Equivalente en este proyecto |
|---|---|
| `Store` | `AppStateStore` (actor) |
| `Reducer` | `AppReducer` (función pura, testable aisladamente) |
| `Action` | `NavigationEvent` (enum `Sendable`) |
| `State` | `AppState` (struct `Sendable`, inmutable) |

Sin dependencia de terceros — 100% vanilla Swift 6.

---

## Estructura del proyecto

```
Sources/
  Shared/
    Kernel/              ← PassengerID, FlightID (value objects compartidos)
    Navigation/
      Routes/            ← NavigationEvent, AppRoute, AppState, AppReducer
      EventBus/          ← DefaultNavigationEventBus, AppStateStore, AppCoordinator
  Features/
    Auth/
      domain/            ← AuthSession, AuthError, AuthGatewayProtocol, SessionStoreProtocol
      application/       ← LoginUseCase, LogoutUseCase
      infrastructure/    ← InMemoryAuthGateway, InMemorySessionStore
      presentation/      ← AuthViewModel, LoginView
    Flights/
      domain/            ← Flight, WeatherInfo, FlightDetail, FlightError, protocols
      application/       ← ListFlightsUseCase (TaskGroup), GetFlightDetailUseCase (async let)
      infrastructure/    ← InMemoryFlightRepository, InMemoryWeatherRepository
      presentation/      ← FlightListViewModel, FlightDetailViewModel, views
    BoardingPass/
      domain/            ← BoardingPassData, BoardingPassError, protocol
      application/       ← GetBoardingPassUseCase
      infrastructure/    ← InMemoryBoardingPassRepository
      presentation/      ← BoardingPassViewModel, BoardingPassView, QRCodeView (UIKit)
  Presentation/
    Navigation/          ← AppViewModel, RootView, DefaultViewFactory
  AppComposition/        ← CompositionRoot, main.swift
Tests/
  Shared/NavigationTests/    ← AppReducerTests, NavigationEventBusTests, AppCoordinatorTests
  Features/AuthTests/        ← LoginUseCaseTests, LogoutUseCaseTests
  Features/FlightsTests/     ← ListFlightsUseCaseTests, GetFlightDetailUseCaseTests
  Features/BoardingPassTests/ ← GetBoardingPassUseCaseTests
docs/features/               ← auth.feature, flights.feature, boarding-pass.feature, navigation.feature
```

---

## Quick start

```bash
# Build
swift build -c debug

# Tests
swift test --parallel
```

Requisitos: Xcode 16+ / Swift 6.0+, macOS 14+.

---

## Credenciales de demo

```
Email: carlos@iberia.com
Password: Secure123!
```

---

## Principios aplicados

- **BDD → TDD**: feature files Gherkin en `docs/features/` antes de cualquier código; tests en rojo antes de producción
- **Feature-first**: cada bounded context (Auth, Flights, BoardingPass) es independiente
- **Cero dependencias externas**: Foundation + SwiftUI + CoreImage
- **Cero warnings**: strict concurrency completo
- **Cero `any`**: generics con protocolos de frontera
- **Cero `DispatchQueue`**: async/await estructurado en todo el codebase
- **Cero Singletons**: inyección de dependencias por constructor
- **String Catalogs**: sin strings hardcodeadas en UI
- **Accessibility**: labels y traits en todas las vistas
