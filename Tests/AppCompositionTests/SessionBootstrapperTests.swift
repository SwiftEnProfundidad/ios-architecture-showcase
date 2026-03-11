@testable import AppComposition
import AuthFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@Suite("SessionBootstrapper")
struct SessionBootstrapperTests {
    @Test("Bootstrap clears persisted session when restore on launch is disabled")
    func clearsSessionWhenRestoreIsDisabled() async {
        let store = TrackingSessionStore(session: makeSession(expiresAt: .distantFuture))
        let stateStore = AppStateStore()
        let bootstrapper = SessionBootstrapper(
            sessionStore: store,
            stateStore: stateStore,
            policy: .resetSession
        )

        await bootstrapper.bootstrap()

        let clearCount = await store.recordedClearCount()
        let state = await stateStore.currentState
        #expect(clearCount == 1)
        #expect(state == .initial)
    }

    @Test("Bootstrap restores a valid persisted session into app state")
    func restoresValidSession() async {
        let session = makeSession(expiresAt: .distantFuture)
        let store = TrackingSessionStore(session: session)
        let stateStore = AppStateStore()
        let bootstrapper = SessionBootstrapper(
            sessionStore: store,
            stateStore: stateStore,
            policy: .restoreValidSession
        )

        await bootstrapper.bootstrap()

        let state = await stateStore.currentState
        #expect(state.rootRoute == .authenticatedHome)
        #expect(state.session?.passengerID == session.passengerID)
        #expect(state.path.isEmpty)
    }

    @Test("Bootstrap clears expired sessions instead of restoring them")
    func clearsExpiredSession() async {
        let store = TrackingSessionStore(session: makeSession(expiresAt: .distantPast))
        let stateStore = AppStateStore()
        let bootstrapper = SessionBootstrapper(
            sessionStore: store,
            stateStore: stateStore,
            policy: .restoreValidSession
        )

        await bootstrapper.bootstrap()

        let clearCount = await store.recordedClearCount()
        let state = await stateStore.currentState
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
