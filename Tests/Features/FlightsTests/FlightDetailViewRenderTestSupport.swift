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
) -> TrackedTestContext<FlightDetailViewRenderContext<ImmediateFlightDetailExecutor>> {
    let executor = ImmediateFlightDetailExecutor(result: result)
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

actor SuspendedFlightDetailExecutor: FlightDetailGetting {
    private let detail: FlightDetail
    private var continuation: CheckedContinuation<FlightDetail, Error>?

    init(detail: FlightDetail) {
        self.detail = detail
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume(returning: detail)
        continuation = nil
    }
}

actor ImmediateFlightDetailExecutor: FlightDetailGetting {
    private let result: Result<FlightDetail, Error>

    init(result: Result<FlightDetail, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try result.get()
    }
}
