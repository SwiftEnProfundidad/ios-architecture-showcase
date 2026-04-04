import SharedKernel
import SharedNavigation
import Testing

@Suite("AppCoordinator session")
struct AppCoordinatorSessionTests {

    @Test("Given the coordinator, when it receives SessionStarted, then the reducer output is applied and the store is updated")
    func coordinatorUpdatesStoreOnSessionStarted() async {
        let tracked = makeAppCoordinatorSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let session = AppSession(passengerID: passengerID, token: "tok-abc", expiresAt: expiresAt)
        await context.coordinator.start()

        let result = await nextCoordinatorStateUpdate(from: context.store) {
            await context.bus.publish(.sessionStarted(session))
        }

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.session == session)
        #expect(result.path.isEmpty)
        await context.coordinator.stop()
    }

    @Test("Given the coordinator, when it receives Logout, then the reducer output is applied and the store is updated")
    func coordinatorUpdatesStoreOnLogout() async {
        let tracked = makeAppCoordinatorSUT(initial: makeAuthenticatedCoordinatorState())
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.coordinator.start()

        let result = await nextCoordinatorStateUpdate(from: context.store) {
            await context.bus.publish(.sessionEnded(.userInitiated))
        }

        #expect(result == .initial)
        await context.coordinator.stop()
    }
}
