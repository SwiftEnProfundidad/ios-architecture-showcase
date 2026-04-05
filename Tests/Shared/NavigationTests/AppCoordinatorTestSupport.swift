import SharedKernel
import SharedNavigation
import Testing

struct AppCoordinatorTestContext {
    let coordinator: DefaultAppCoordinator
    let bus: DefaultNavigationEventBus
    let store: AppStateStore
}

struct ExpiredProtectedNavigationCoordinatorContext {
    let tracked: TrackedTestContext<AppCoordinatorTestContext>
    let cleaner: SessionInvalidationSpy
}

func makeAppCoordinatorSUT(
    initial: AppState = .initial,
    sessionInvalidator: (@Sendable () async -> Void)? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<AppCoordinatorTestContext> {
    let bus = DefaultNavigationEventBus()
    let store = AppStateStore(initial: initial)
    let coordinator = AppCoordinator(
        bus: bus,
        store: store,
        invalidatePersistedSession: sessionInvalidator
    )
    return makeTestContext(
        AppCoordinatorTestContext(
            coordinator: coordinator,
            bus: bus,
            store: store
        )
    )
}

func makeAuthenticatedCoordinatorState() -> AppState {
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

func makeExpiredProtectedNavigationCoordinatorSUT() -> ExpiredProtectedNavigationCoordinatorContext {
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
    let tracked = makeAppCoordinatorSUT(
        initial: expiredState,
        sessionInvalidator: {
            await cleaner.invalidate()
        }
    )
    return ExpiredProtectedNavigationCoordinatorContext(tracked: tracked, cleaner: cleaner)
}

func nextCoordinatorStateUpdate(
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

actor SessionInvalidationSpy {
    private(set) var callCount = 0

    func invalidate() {
        callCount += 1
    }
}
