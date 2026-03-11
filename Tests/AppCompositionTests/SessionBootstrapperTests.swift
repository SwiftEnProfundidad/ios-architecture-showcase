import AppComposition
import AuthFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("SessionBootstrapper")
struct SessionBootstrapperTests {
    @Test("Bootstrap clears persisted session when restore on launch is disabled")
    func clearsSessionWhenRestoreIsDisabled() async {
        let session = makeSession(expiresAt: .distantFuture)
        let tracked = makeSUT(session: session, policy: .resetSession)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.bootstrapper.bootstrap()

        let clearCount = await context.store.recordedClearCount()
        let state = await context.stateStore.currentState
        #expect(clearCount == 1)
        #expect(state == .initial)
    }

    @Test("Bootstrap restores a valid persisted session into app state")
    func restoresValidSession() async {
        let session = makeSession(expiresAt: .distantFuture)
        let tracked = makeSUT(session: session, policy: .restoreValidSession)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.bootstrapper.bootstrap()

        let state = await context.stateStore.currentState
        #expect(state.rootRoute == .authenticatedHome)
        #expect(state.session?.passengerID == session.passengerID)
        #expect(state.path.isEmpty)
    }

    @Test("Bootstrap clears expired sessions instead of restoring them")
    func clearsExpiredSession() async {
        let session = makeSession(expiresAt: .distantPast)
        let tracked = makeSUT(session: session, policy: .restoreValidSession)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.bootstrapper.bootstrap()

        let clearCount = await context.store.recordedClearCount()
        let state = await context.stateStore.currentState
        #expect(clearCount == 1)
        #expect(state == .initial)
    }

    private func makeSession(expiresAt: Date) -> AuthSession {
        AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-bootstrap",
            expiresAt: expiresAt
        )
    }

    private func makeSUT(
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
}

private struct SessionBootstrapperTestContext {
    let bootstrapper: SessionBootstrapper<TrackingSessionStore>
    let store: TrackingSessionStore
    let stateStore: AppStateStore
}

private actor TrackingSessionStore: SessionReading, SessionClearing {
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
