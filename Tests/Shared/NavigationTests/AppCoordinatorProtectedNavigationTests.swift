import SharedKernel
import SharedNavigation
import Testing

@Suite("AppCoordinator protected navigation")
struct AppCoordinatorProtectedNavigationTests {

    @Test("Given an ordered sequence of navigation events, when the coordinator processes them, then the final store state matches the expected sequence")
    func coordinatorProcessesEventSequence() async {
        let tracked = makeAppCoordinatorSUT(initial: makeAuthenticatedCoordinatorState())
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let contextID = FlightID("IB3456")
        await context.coordinator.start()

        let result = await nextCoordinatorStateUpdate(from: context.store) {
            await context.bus.publish(.requestProtectedPath([.primaryDetail(contextID: contextID)]))
        }

        #expect(result.path == [.primaryDetail(contextID: contextID)])
        await context.coordinator.stop()
    }

    @Test("Given protected navigation reports an expired session, when the coordinator handles it, then the persisted session is cleared")
    func coordinatorClearsPersistedSessionOnExpiredProtectedNavigation() async {
        let scenario = makeExpiredProtectedNavigationCoordinatorSUT()
        let tracked = scenario.tracked
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.coordinator.start()

        let result = await nextCoordinatorStateUpdate(from: context.store) {
            await context.bus.publish(.requestProtectedPath([.primaryDetail(contextID: FlightID("IB3456"))]))
        }

        #expect(result == .initial)
        #expect(await scenario.cleaner.callCount == 1)
        await context.coordinator.stop()
    }
}
