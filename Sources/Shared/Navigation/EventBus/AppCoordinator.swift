public final class AppCoordinator: Sendable {

    private let bus: DefaultNavigationEventBus
    private let store: AppStateStore
    private let reducer: AppReducer

    public init(bus: DefaultNavigationEventBus, store: AppStateStore, reducer: AppReducer = AppReducer()) {
        self.bus = bus
        self.store = store
        self.reducer = reducer
    }

    public func start() async {
        Task {
            let stream = await bus.events()
            for await event in stream {
                let current = await store.currentState
                let next = reducer.reduce(current, event: event)
                await store.apply(next)
            }
        }
    }
}
