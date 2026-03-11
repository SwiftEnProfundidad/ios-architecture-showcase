import Observation
import SharedNavigation

@MainActor
@Observable
public final class AppViewModel {
    public private(set) var rootRoute: RootRoute = .login
    public private(set) var session: AppSession?
    public private(set) var path: [AppRoute] = []

    private let store: AppStateStore
    private var observationTask: Task<Void, Never>?

    public init(store: AppStateStore) {
        self.store = store
    }

    public func startObservingState() {
        guard observationTask == nil else {
            return
        }
        observationTask = Task { [store] in
            let updates = await store.stateUpdates()
            for await state in updates {
                apply(state)
            }
        }
    }

    public func stopObservingState() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func apply(_ state: AppState) {
        rootRoute = state.rootRoute
        session = state.isAuthenticated ? state.session : nil
        path = state.path
    }
}
