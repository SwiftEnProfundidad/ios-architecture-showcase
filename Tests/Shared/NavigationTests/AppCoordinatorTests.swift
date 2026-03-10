import Testing
@testable import SharedNavigation
@testable import SharedKernel

@Suite("AppCoordinator")
struct AppCoordinatorTests {

    @Test("Coordinator aplica reducer y actualiza store cuando recibe LoginSuccess")
    func coordinatorUpdatesStoreOnLoginSuccess() async {
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore()
        let coordinator = AppCoordinator(bus: bus, store: store)
        await coordinator.start()

        let passengerID = PassengerID("PAX-001")

        let result = await firstStateUpdate(from: store) {
            await bus.publish(.loginSuccess(passengerID: passengerID, token: "tok-abc"))
        }

        #expect(result.route == .flightList)
        #expect(result.isAuthenticated == true)
        #expect(result.passengerID == passengerID)
    }

    @Test("Coordinator aplica reducer y actualiza store cuando recibe Logout")
    func coordinatorUpdatesStoreOnLogout() async {
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore(
            initial: AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))
        )
        let coordinator = AppCoordinator(bus: bus, store: store)
        await coordinator.start()

        let result = await firstStateUpdate(from: store) {
            await bus.publish(.logout)
        }

        #expect(result.route == .login)
        #expect(result.isAuthenticated == false)
        #expect(result.passengerID == nil)
    }

    @Test("Coordinator aplica secuencia de eventos correctamente")
    func coordinatorProcessesEventSequence() async {
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore()
        let coordinator = AppCoordinator(bus: bus, store: store)
        await coordinator.start()

        let passengerID = PassengerID("PAX-001")
        let flightID = FlightID("IB3456")

        _ = await firstStateUpdate(from: store) {
            await bus.publish(.loginSuccess(passengerID: passengerID, token: "tok"))
        }

        let result = await firstStateUpdate(from: store) {
            await bus.publish(.showFlightDetail(flightID: flightID))
        }

        #expect(result.route == .flightDetail(flightID))
        #expect(result.isAuthenticated == true)
    }

    private func firstStateUpdate(
        from store: AppStateStore,
        after publish: @escaping @Sendable () async -> Void
    ) async -> AppState {
        await withCheckedContinuation { (continuation: CheckedContinuation<AppState, Never>) in
            Task {
                let updates = await store.stateUpdates()
                for await state in updates {
                    continuation.resume(returning: state)
                    break
                }
            }
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000)
                await publish()
            }
        }
    }
}
