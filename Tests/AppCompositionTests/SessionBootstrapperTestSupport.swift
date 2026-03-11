import AppComposition
import AuthFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@MainActor
func makeSessionBootstrapperSUT(
    session: AuthSession?,
    policy: SessionLaunchPolicy,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBootstrapperTestContext> {
    let store = TrackingSessionStore(session: session)
    let stateStore = AppStateStore()
    let sut = SessionBootstrapper(
        sessionStore: store,
        stateStore: stateStore,
        policy: policy
    )
    return makeLeakTrackedTestContext(
        SessionBootstrapperTestContext(
            bootstrapper: sut,
            store: store,
            stateStore: stateStore
        ),
        trackedInstances: store,
        stateStore,
        sourceLocation: sourceLocation
    )
}

func makeBootstrapSession(expiresAt: Date) -> AuthSession {
    AuthSession(
        passengerID: PassengerID("PAX-001"),
        token: "tok-bootstrap",
        expiresAt: expiresAt
    )
}

struct SessionBootstrapperTestContext {
    let bootstrapper: SessionBootstrapper<TrackingSessionStore>
    let store: TrackingSessionStore
    let stateStore: AppStateStore
}

actor TrackingSessionStore: SessionReading, SessionClearing {
    private var storedSession: AuthSession?
    private var clearCount = 0

    init(session: AuthSession?) {
        self.storedSession = session
    }

    func save(session: AuthSession) async throws {
        storedSession = session
    }

    func currentSession() async -> AuthSession? {
        storedSession
    }

    func clear() async {
        clearCount += 1
        storedSession = nil
    }

    func recordedClearCount() -> Int {
        clearCount
    }
}
