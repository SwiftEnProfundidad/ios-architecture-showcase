import AppComposition
import SharedNavigation
import Testing

@MainActor
func makeRootViewRenderingSUT() -> TrackedTestContext<AppViewModelRenderingContext> {
    let store = AppStateStore()
    let viewModel = AppViewModel(store: store)
    return makeTestContext(
        AppViewModelRenderingContext(viewModel: viewModel)
    )
}

@MainActor
func makeObservedRootNavigationSUT() -> TrackedTestContext<ObservedNavigationTestContext> {
    let bus = DefaultNavigationEventBus()
    let store = AppStateStore()
    let viewModel = AppViewModel(store: store)
    return makeTestContext(
        ObservedNavigationTestContext(bus: bus, store: store, viewModel: viewModel)
    )
}

struct AppViewModelRenderingContext {
    let viewModel: AppViewModel
}

struct ObservedNavigationTestContext {
    let bus: DefaultNavigationEventBus
    let store: AppStateStore
    let viewModel: AppViewModel
}
