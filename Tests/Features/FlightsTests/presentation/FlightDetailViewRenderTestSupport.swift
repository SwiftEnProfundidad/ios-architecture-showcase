import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
func makeSuspendedFlightDetailViewRenderSUT(
    suspendedDetail: FlightDetail
) -> TrackedTestContext<FlightDetailViewRenderContext<SuspendedFlightDetailExecutor>> {
    let executor = SuspendedFlightDetailExecutor(detail: suspendedDetail)
    let eventBus = NavigationEventBusSpy()
    let sut = FlightDetailViewModel(
        detailUseCase: executor,
        eventBus: eventBus,
        flightID: suspendedDetail.flight.id
    )
    return makeTestContext(
        FlightDetailViewRenderContext(viewModel: sut, executor: executor)
    )
}

@MainActor
func makeImmediateFlightDetailViewRenderSUT(
    result: Result<FlightDetail, Error>,
    flightID: FlightID
) -> TrackedTestContext<FlightDetailViewRenderContext<FlightDetailExecutor>> {
    let executor = FlightDetailExecutor(result: result)
    let eventBus = NavigationEventBusSpy()
    let sut = FlightDetailViewModel(
        detailUseCase: executor,
        eventBus: eventBus,
        flightID: flightID
    )
    return makeTestContext(
        FlightDetailViewRenderContext(viewModel: sut, executor: executor)
    )
}

struct FlightDetailViewRenderContext<Executor: FlightDetailGetting> {
    let viewModel: FlightDetailViewModel<Executor>
    let executor: Executor
}
