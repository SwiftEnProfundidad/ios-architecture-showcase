import AppComposition
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("AppViewModel")
struct AppViewModelTests {

    @Test("AppViewModel reflects store updates after coordinator processes an event")
    func appViewModelReflectsStateChanges() async {
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore()
        let coordinator = AppCoordinator(bus: bus, store: store)
        let viewModel = AppViewModel(store: store)
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-abc",
            expiresAt: expiresAt
        )
        viewModel.startObservingState()
        defer { viewModel.stopObservingState() }

        await coordinator.start()
        await bus.publish(.sessionStarted(session))
        await bus.publish(.requestProtectedPath([.primaryDetail(contextID: "IB3456")]))

        await eventually {
            viewModel.rootRoute == .authenticatedHome &&
            viewModel.session?.passengerID == PassengerID("PAX-001") &&
            viewModel.path == [.primaryDetail(contextID: "IB3456")]
        }

        #expect(viewModel.rootRoute == .authenticatedHome)
        #expect(viewModel.session?.expiresAt == expiresAt)
        #expect(viewModel.path == [.primaryDetail(contextID: "IB3456")])
    }

    @Test("AppViewModel stops observing once cancelled")
    func appViewModelStopsReflectingStateAfterCancellation() async {
        let store = AppStateStore()
        let viewModel = AppViewModel(store: store)
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-stop",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )

        viewModel.startObservingState()
        viewModel.stopObservingState()

        await store.apply(
            AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: [.primaryDetail(contextID: "IB3456")]
            )
        )

        await Task.yield()

        #expect(viewModel.rootRoute == .login)
        #expect(viewModel.session == nil)
        #expect(viewModel.path.isEmpty)
    }

    private func eventually(
        attempts: Int = 100,
        assertion: () -> Bool
    ) async {
        for _ in 0..<attempts where assertion() == false {
            await Task.yield()
        }
    }
}
