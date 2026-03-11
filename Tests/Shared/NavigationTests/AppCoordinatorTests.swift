import SharedKernel
import SharedNavigation
import Testing

@Suite("AppCoordinator")
struct AppCoordinatorTests {

    @Test("Coordinator applies reducer and updates store when it receives SessionStarted")
    func coordinatorUpdatesStoreOnSessionStarted() async {
        let (token, coordinator, bus, store) = makeSUT()
        let passengerID = PassengerID("PAX-001")
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let session = AppSession(passengerID: passengerID, token: "tok-abc", expiresAt: expiresAt)
        await coordinator.start()

        let result = await nextStateUpdate(from: store) {
            await bus.publish(.sessionStarted(session))
        }

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.session == session)
        #expect(result.path.isEmpty)
        await coordinator.stop()
        _ = token
    }

    @Test("Coordinator applies reducer and updates store when it receives Logout")
    func coordinatorUpdatesStoreOnLogout() async {
        let (token, coordinator, bus, store) = makeSUT(initial: authenticatedState())
        await coordinator.start()

        let result = await nextStateUpdate(from: store) { await bus.publish(.sessionEnded(.userInitiated)) }

        #expect(result == .initial)
        await coordinator.stop()
        _ = token
    }

    @Test("Coordinator processes event sequence correctly")
    func coordinatorProcessesEventSequence() async {
        let (token, coordinator, bus, store) = makeSUT(initial: authenticatedState())
        let contextID = "IB3456"
        await coordinator.start()

        let result = await nextStateUpdate(from: store) {
            await bus.publish(.requestProtectedPath([.primaryDetail(contextID: contextID)]))
        }

        #expect(result.path == [.primaryDetail(contextID: contextID)])
        await coordinator.stop()
        _ = token
    }

    @Test("Coordinator clears persisted session when protected navigation detects an expired session")
    func coordinatorClearsPersistedSessionOnExpiredProtectedNavigation() async {
        let cleaner = SessionInvalidationSpy()
        let expiredState = AppState(
            rootRoute: .authenticatedHome,
            session: AppSession(
                passengerID: PassengerID("PAX-001"),
                token: "tok-abc",
                expiresAt: .distantPast
            ),
            path: []
        )
        let (token, coordinator, bus, store) = makeSUT(initial: expiredState, sessionInvalidator: {
            await cleaner.invalidate()
        })
        await coordinator.start()

        let result = await nextStateUpdate(from: store) {
            await bus.publish(.requestProtectedPath([.primaryDetail(contextID: "IB3456")]))
        }

        #expect(result == .initial)
        #expect(await cleaner.callCount == 1)
        await coordinator.stop()
        _ = token
    }

    private func makeSUT(
        initial: AppState = .initial,
        sessionInvalidator: (@Sendable () async -> Void)? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, DefaultAppCoordinator, DefaultNavigationEventBus, AppStateStore) {
        let token = MemoryLeakToken()
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore(initial: initial)
        let coordinator = AppCoordinator(
            bus: bus,
            store: store,
            invalidatePersistedSession: sessionInvalidator
        )
        trackForMemoryLeaks(coordinator, token: token, sourceLocation: sourceLocation)
        return (token, coordinator, bus, store)
    }

    private func authenticatedState() -> AppState {
        AppState(
            rootRoute: .authenticatedHome,
            session: AppSession(
                passengerID: PassengerID("PAX-001"),
                token: "tok-abc",
                expiresAt: fixedDate(hour: 12, minute: 0)
            ),
            path: []
        )
    }

    private func nextStateUpdate(
        from store: AppStateStore,
        after publish: @escaping @Sendable () async -> Void
    ) async -> AppState {
        await withCheckedContinuation { continuation in
            Task {
                let updates = await store.stateUpdates()
                var iterator = updates.makeAsyncIterator()
                _ = await iterator.next()
                await publish()
                let next = await iterator.next() ?? .initial
                continuation.resume(returning: next)
            }
        }
    }
}

private actor SessionInvalidationSpy {
    private(set) var callCount = 0

    func invalidate() {
        callCount += 1
    }
}
