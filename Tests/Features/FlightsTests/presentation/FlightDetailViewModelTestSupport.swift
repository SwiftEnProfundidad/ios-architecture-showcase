import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
func makeFlightDetailViewModelSUT<UseCase: FlightDetailGetting>(
    detailUseCase: UseCase,
    eventBus: NavigationEventBusSpy = NavigationEventBusSpy(),
    flightID: FlightID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<FlightDetailViewModelTestContext<UseCase>> {
    let sut = FlightDetailViewModel(
        detailUseCase: detailUseCase,
        eventBus: eventBus,
        flightID: flightID
    )
    return makeLeakTrackedTestContext(
        FlightDetailViewModelTestContext(
            viewModel: sut,
            detailUseCase: detailUseCase,
            eventBus: eventBus
        ),
        trackedInstances: eventBus,
        sut,
        sourceLocation: sourceLocation
    )
}

struct FlightDetailViewModelTestContext<UseCase: FlightDetailGetting> {
    let viewModel: FlightDetailViewModel<UseCase>
    let detailUseCase: UseCase
    let eventBus: NavigationEventBusSpy
}
