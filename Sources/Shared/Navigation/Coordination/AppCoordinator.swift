public typealias DefaultAppCoordinator = AppCoordinator<DefaultNavigationEventBus>

public actor AppCoordinator<Bus: NavigationEventBus> {
    private let bus: Bus
    private let store: AppStateStore
    private let reducer: AppReducer
    private let invalidatePersistedSession: (@Sendable () async -> Void)?
    private var listenerTask: Task<Void, Never>?

    public init(
        bus: Bus,
        store: AppStateStore,
        reducer: AppReducer = AppReducer(),
        invalidatePersistedSession: (@Sendable () async -> Void)? = nil
    ) {
        self.bus = bus
        self.store = store
        self.reducer = reducer
        self.invalidatePersistedSession = invalidatePersistedSession
    }

    deinit {
        listenerTask?.cancel()
    }

    public func start() async {
        guard listenerTask == nil else {
            return
        }
        let stream = await bus.events()
        let capturedStore = store
        let capturedReducer = reducer
        let capturedInvalidator = invalidatePersistedSession
        listenerTask = Task {
            for await event in stream {
                guard !Task.isCancelled else { break }
                let current = await capturedStore.currentState
                let next = capturedReducer.reduce(current, event: event)
                if current.session?.isExpired() == true && next.session == nil {
                    await capturedInvalidator?()
                }
                await capturedStore.apply(next)
            }
        }
    }

    public func stop() {
        listenerTask?.cancel()
        listenerTask = nil
    }
}
