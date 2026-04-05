# Reviewer Guide

## Goal

This repository is designed to demonstrate an interview-sized iOS solution that still enforces modular boundaries, BDD-driven behavior, strict Swift concurrency, and a measurable quality gate.

## Fast evaluation path

1. Open `README.md` and review the architecture diagrams.
2. Run `./scripts/validate.sh`.
3. Open `docs/features/` and inspect the behavioral source of truth.
4. Open `Package.swift` and `project.yml` to confirm module boundaries and toolchain settings.
5. Launch the app and exercise the happy path:
   - login with the evaluation account
   - browse paginated flights
   - pull to refresh
   - open flight detail
   - open the boarding pass
   - logout

Evaluation account:

- Email: `carlos@iberia.com`
- Password: `Secure123!`

In local bootstrap mode, the app intentionally starts from login so the reviewer can always see the authentication flow before entering protected screens.

## What is intentionally enforced

- Swift 6.2 and strict concurrency
- Feature-first modularization with SwiftPM
- No feature-to-feature imports
- App composition as the only module that knows every feature
- BDD source of truth under `docs/features/`
- Coverage gate enforced from the same local validation command used in CI
- No third-party runtime dependencies

## If you only have 5 minutes

1. Run `./scripts/validate.sh`.
2. Open `Package.swift`.
3. Open `Sources/AppComposition/CompositionRoot.swift`.
4. Open `docs/features/`.
5. Launch the app and follow the evaluation login flow.

## How to verify modularity quickly in code

1. Open `Package.swift` and confirm the product split:
   - `SharedKernel`
   - `SharedNetworking`
   - `SharedNavigation`
   - `AuthFeature`
   - `FlightsFeature`
   - `BoardingPassFeature`
   - `AppComposition`
   - `CoverageGate` (tooling library exercised by tests and validation scripts)
2. Confirm that feature modules depend only on shared modules, not on each other.
3. Open `Sources/AppComposition/CompositionRoot.swift` and verify that composition is the single place that wires all features together.
4. Open `Sources/Shared/Navigation/` and verify that navigation state, reducer, eventing, and coordination are isolated from feature implementation details.

## What is intentionally out of scope for this delivery

- Large UI automation suites
- Broad performance automation
- Full accessibility automation infrastructure
- Pixel-baseline snapshot suites

Those layers are documented as consciously deferred, not forgotten.

Internal delivery notes for handoff and interview preparation are not required to review the technical submission itself.

## Artifacts worth checking

- `README.md`
- `docs/features/`
- `Package.swift`
- `project.yml`
- `scripts/validate.sh`

## Evidence map

| Claim | Primary evidence |
|---|---|
| Modular boundaries are real, not cosmetic | `Package.swift` |
| App composition is the only place that knows every feature | `Sources/AppComposition/CompositionRoot.swift` |
| Features do not import each other | `Package.swift` + `Sources/Features/` |
| Navigation is event-driven and centralized | `Sources/Shared/Navigation/` |
| BDD is the behavioral source of truth | `docs/features/` |
| Local and CI validation use the same contract | `scripts/validate.sh` + `.github/workflows/ci.yml` |
| Coverage is enforced as a gate | `Sources/Tooling/CoverageGate/` + `scripts/coverage_gate.py` + `scripts/validate.sh` |
| Showcase auth is HTTP-shaped and not a separate fake flow | `Sources/AppComposition/Runtime/Auth/ShowcaseAuthRuntimeConfiguration.swift` + `Sources/AppComposition/Runtime/Auth/ShowcaseBootstrapAuthURLProtocol.swift` |
| Secure session persistence exists in runtime | `Sources/Features/Auth/infrastructure/repositories/KeychainSessionStore.swift` |
| Flights demonstrate pagination, refresh, and cache fallback | `Sources/Features/Flights/` + `docs/features/flights.feature` |
