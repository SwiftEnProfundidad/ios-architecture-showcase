import Foundation

public actor AppStateStore {
    public private(set) var currentState: AppState
    private var continuations: [UUID: AsyncStream<AppState>.Continuation] = [:]

    public init(initial: AppState = .initial) {
        self.currentState = initial
    }

    public func apply(_ newState: AppState) {
        currentState = newState
        for continuation in continuations.values {
            continuation.yield(newState)
        }
    }

    public func stateUpdates() -> AsyncStream<AppState> {
        let id = UUID()
        let stream = AsyncStream.makeStream(of: AppState.self)
        continuations[id] = stream.continuation
        stream.continuation.yield(currentState)
        stream.continuation.onTermination = { [id] _ in
            Task { await self.removeContinuation(id: id) }
        }
        return stream.stream
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
