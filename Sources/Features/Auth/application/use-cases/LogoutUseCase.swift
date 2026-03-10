
public struct LogoutUseCase<Store: SessionStoreProtocol>: Sendable {
    private let sessionStore: Store
    private let eventBus: NavigationEventPublishing

    public init(sessionStore: Store, eventBus: NavigationEventPublishing) {
        self.sessionStore = sessionStore
        self.eventBus = eventBus
    }

    public func execute() async {
        await sessionStore.clear()
        await eventBus.publish(.logout)
    }
}
