import Foundation
import SharedKernel
import SharedNavigation
import Auth
import Flights
import BoardingPass
import Presentation

@MainActor
func bootstrap() async {
    let bus = DefaultNavigationEventBus()
    let store = AppStateStore()
    let coordinator = AppCoordinator(bus: bus, store: store)
    await coordinator.start()
}

let task = Task { @MainActor in
    await bootstrap()
}
RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
