import Observation
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class AppViewModel {
    public private(set) var activeRoute: AppRoute = .login
    private let store: AppStateStore

    public init(store: AppStateStore) {
        self.store = store
    }

    public func startObservingState() async {
        for await state in await store.stateUpdates() {
            activeRoute = state.route
        }
    }
}
