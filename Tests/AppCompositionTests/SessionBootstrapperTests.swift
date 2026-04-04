import Testing

@MainActor
@Suite("SessionBootstrapper")
struct SessionBootstrapperTests {
    @Test("Given restore on launch is disabled, when bootstrap runs, then any persisted session is cleared")
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

    @Test("Given a valid persisted session and restore enabled, when bootstrap runs, then app state reflects the session")
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

    @Test("Given a persisted session that is expired, when bootstrap runs, then it is cleared and not restored")
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
