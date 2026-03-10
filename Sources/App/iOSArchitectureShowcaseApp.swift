import SwiftUI

@main
struct iOSArchitectureShowcaseApp: App {

    @State private var appViewModel: AppViewModel
    @State private var coordinator: AppCoordinator
    private let factory: DefaultViewFactory

    init() {
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore()
        let coordinator = AppCoordinator(bus: bus, store: store)
        let appViewModel = AppViewModel(store: store)
        let factory = DefaultViewFactory(bus: bus, passengerID: PassengerID("PAX-001"))

        _appViewModel = State(initialValue: appViewModel)
        _coordinator = State(initialValue: coordinator)
        self.factory = factory
    }

    var body: some Scene {
        WindowGroup {
            RootView(appViewModel: appViewModel, factory: factory)
                .task {
                    await coordinator.start()
                }
        }
    }
}
