import SharedKernel
import SharedNavigation
import Testing

@Suite("AppCoordinator protected navigation")
struct AppCoordinatorProtectedNavigationTests {

    @Test("Coordinator processes event sequence correctly")
    func coordinatorProcessesEventSequence() async {
        let tracked = makeAppCoordinatorSUT(initial: makeAuthenticatedCoordinatorState())
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let contextID = "IB3456"
        await context.coordinator.start()

        let result = await nextCoordinatorStateUpdate(from: context.store) {
            await context.bus.publish(.requestProtectedPath([.primaryDetail(contextID: contextID)]))
        }

        #expect(result.path == [.primaryDetail(contextID: contextID)])
        await context.coordinator.stop()
    }

    @Test("Coordinator clears persisted session when protected navigation detects an expired session")
    func coordinatorClearsPersistedSessionOnExpiredProtectedNavigation() async {
        let scenario = makeExpiredProtectedNavigationCoordinatorSUT()
        let tracked = scenario.tracked
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.coordinator.start()

        let result = await nextCoordinatorStateUpdate(from: context.store) {
            await context.bus.publish(.requestProtectedPath([.primaryDetail(contextID: "IB3456")]))
        }

        #expect(result == .initial)
        #expect(await scenario.cleaner.callCount == 1)
        await context.coordinator.stop()
    }
}
