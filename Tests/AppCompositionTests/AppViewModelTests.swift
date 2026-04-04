import AppComposition
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("AppViewModel")
struct AppViewModelTests {

    @Test("Given the coordinator processes an event, when the store updates, then AppViewModel reflects the new state")
    func appViewModelReflectsStateChanges() async {
        let tracked = makeObservedAppViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-abc",
            expiresAt: expiresAt
        )
        context.viewModel.startObservingState()
        defer { context.viewModel.stopObservingState() }

        await context.coordinator.start()
        await context.bus.publish(.sessionStarted(session))
        await context.bus.publish(.requestProtectedPath([.primaryDetail(contextID: "IB3456")]))

        await eventually {
            context.viewModel.rootRoute == .authenticatedHome &&
            context.viewModel.session?.passengerID == PassengerID("PAX-001") &&
            context.viewModel.path == [.primaryDetail(contextID: "IB3456")]
        }

        #expect(context.viewModel.rootRoute == .authenticatedHome)
        #expect(context.viewModel.session?.expiresAt == expiresAt)
        #expect(context.viewModel.path == [.primaryDetail(contextID: "IB3456")])
    }

    @Test("Given observation is cancelled, when further store updates occur, then AppViewModel stops receiving them")
    func appViewModelStopsReflectingStateAfterCancellation() async {
        let tracked = makeStoppedObserverAppViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-stop",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )

        context.viewModel.startObservingState()
        context.viewModel.stopObservingState()

        await context.store.apply(
            AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: [.primaryDetail(contextID: "IB3456")]
            )
        )

        await Task.yield()

        #expect(context.viewModel.rootRoute == .login)
        #expect(context.viewModel.session == nil)
        #expect(context.viewModel.path.isEmpty)
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
