import Testing

@MainActor
@Suite("SessionBootstrapper")
struct SessionBootstrapperTests {
    @Test("Bootstrap clears persisted session when restore on launch is disabled")
    func clearsSessionWhenRestoreIsDisabled() async {
        let session = makeBootstrapSession(expiresAt: .distantFuture)
        let tracked = makeSessionBootstrapperSUT(session: session, policy: .resetSession)
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
        let session = makeBootstrapSession(expiresAt: .distantFuture)
        let tracked = makeSessionBootstrapperSUT(session: session, policy: .restoreValidSession)
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
        let session = makeBootstrapSession(expiresAt: .distantPast)
        let tracked = makeSessionBootstrapperSUT(session: session, policy: .restoreValidSession)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.bootstrapper.bootstrap()

        let clearCount = await context.store.recordedClearCount()
        let state = await context.stateStore.currentState
        #expect(clearCount == 1)
        #expect(state == .initial)
    }
}
