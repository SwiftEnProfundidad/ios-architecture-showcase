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
        let stream = AsyncStream.makeStream(of: NavigationEvent.self)
        continuations[id] = stream.continuation
        stream.continuation.onTermination = { [id] _ in
            Task { await self.unregister(id: id) }
        }
        return stream.stream
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
