public protocol NavigationEventPublishing: Sendable {
    func publish(_ event: NavigationEvent) async
}

public protocol NavigationEventStreaming: Sendable {
    func events() async -> AsyncStream<NavigationEvent>
}

public typealias NavigationEventBus = NavigationEventPublishing & NavigationEventStreaming
