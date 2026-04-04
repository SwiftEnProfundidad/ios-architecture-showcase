import FlightsFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@MainActor
func makeFlightListSessionControllerSUT(
    sessionExpiresAt: Date,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<FlightListSessionControllerTestContext> {
    let logoutUseCase = SessionEndingSpy()
    let bus = NavigationEventBusSpy()
    let sut = FlightListSessionController(
        logoutUseCase: logoutUseCase,
        eventBus: bus,
        sessionExpiresAt: sessionExpiresAt
    )
    return makeLeakTrackedTestContext(
        FlightListSessionControllerTestContext(
            sut: sut,
            logoutUseCase: logoutUseCase,
            bus: bus
        ),
        trackedInstances: logoutUseCase,
        bus,
        sut,
        sourceLocation: sourceLocation
    )
}

struct FlightListSessionControllerTestContext {
    let sut: FlightListSessionController<SessionEndingSpy>
    let logoutUseCase: SessionEndingSpy
    let bus: NavigationEventBusSpy
}
