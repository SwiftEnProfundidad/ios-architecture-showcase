import AppComposition
import SharedNavigation
import Testing

@MainActor
func makeObservedAppViewModelSUT() -> TrackedTestContext<AppViewModelObservedContext> {
    let bus = DefaultNavigationEventBus()
    let store = AppStateStore()
    let coordinator = AppCoordinator(bus: bus, store: store)
    let viewModel = AppViewModel(store: store)
    return makeTestContext(
        AppViewModelObservedContext(bus: bus, coordinator: coordinator, viewModel: viewModel)
    )
}

@MainActor
func makeStoppedObserverAppViewModelSUT() -> TrackedTestContext<AppViewModelStoppedObserverContext> {
    let store = AppStateStore()
    let viewModel = AppViewModel(store: store)
    return makeTestContext(
        AppViewModelStoppedObserverContext(store: store, viewModel: viewModel)
    )
}

struct AppViewModelObservedContext {
    let bus: DefaultNavigationEventBus
    let coordinator: DefaultAppCoordinator
    let viewModel: AppViewModel
}

struct AppViewModelStoppedObserverContext {
    let store: AppStateStore
    let viewModel: AppViewModel
}
