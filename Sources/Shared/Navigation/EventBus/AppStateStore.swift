import Foundation

public actor AppStateStore {
    public private(set) var currentState: AppState
    private var continuations: [UUID: AsyncStream<AppState>.Continuation] = [:]

    public init(initial: AppState = .initial) {
        self.currentState = initial
    }

    func apply(_ newState: AppState) {
        currentState = newState
        for continuation in continuations.values {
            continuation.yield(newState)
        }
    }

    public func stateUpdates() -> AsyncStream<AppState> {
        let id = UUID()
        return AsyncStream(AppState.self) { continuation in
            Task {
                self.continuations[id] = continuation
                continuation.onTermination = { [id] _ in
                    Task { await self.removeContinuation(id: id) }
                }
            }
        }
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
