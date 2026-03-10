import Foundation

public final class DefaultNavigationEventBus: NavigationEventBus {

    private let state = NavigationEventBusState()

    public init() {}

    public func publish(_ event: NavigationEvent) async {
        await state.publish(event)
    }

    public func events() async -> AsyncStream<NavigationEvent> {
        await state.makeStream()
    }
}

private actor NavigationEventBusState {
    private var continuations: [UUID: AsyncStream<NavigationEvent>.Continuation] = [:]

    func publish(_ event: NavigationEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    func makeStream() -> AsyncStream<NavigationEvent> {
        let id = UUID()
        return AsyncStream(NavigationEvent.self) { continuation in
            Task {
                self.register(id: id, continuation: continuation)
                continuation.onTermination = { [id] _ in
                    Task { await self.unregister(id: id) }
                }
            }
        }
    }

    private func register(id: UUID, continuation: AsyncStream<NavigationEvent>.Continuation) {
        continuations[id] = continuation
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
