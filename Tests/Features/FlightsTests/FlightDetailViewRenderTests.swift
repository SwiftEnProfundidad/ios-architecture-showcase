import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightDetailViewRender")
struct FlightDetailViewRenderTests {
    @Test("Flight detail renders the loading skeleton")
    func rendersLoadingState() async throws {
        let detail = FlightDetail(
            flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 22)
        )
        let tracked = makeSUT(suspendedDetail: detail)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let task = Task {
            await context.viewModel.load()
        }
        await Task.yield()

        let data = try renderedPNG(from: FlightDetailView(viewModel: context.viewModel))

        #expect(context.viewModel.isLoading)
        #expect(data.count > 1_000)

        await context.executor.resume()
        await task.value
    }

    @Test("Flight detail renders the content state")
    func rendersContentState() async throws {
        let detail = FlightDetail(
            flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 22)
        )
        let tracked = makeSUT(result: .success(detail), flightID: detail.flight.id)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        let data = try renderedPNG(from: FlightDetailView(viewModel: context.viewModel), colorScheme: .dark)

        #expect(context.viewModel.detail == detail)
        #expect(data.count > 1_000)
    }

    @Test("Flight detail renders the error state")
    func rendersErrorState() async throws {
        let tracked = makeSUT(
            result: .failure(FlightError.network),
            flightID: FlightID("IB3456")
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        let data = try renderedPNG(from: FlightDetailView(viewModel: context.viewModel))

        #expect(context.viewModel.errorMessage == AppStrings.localized("flights.error.detail"))
        #expect(data.count > 1_000)
    }

    private func makeSUT(
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

    private func makeSUT(
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
}

private struct FlightDetailViewRenderContext<Executor: FlightDetailGetting> {
    let viewModel: FlightDetailViewModel<Executor>
    let executor: Executor
}

private actor SuspendedFlightDetailExecutor: FlightDetailGetting {
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

private actor ImmediateFlightDetailExecutor: FlightDetailGetting {
    private let result: Result<FlightDetail, Error>

    init(result: Result<FlightDetail, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try result.get()
    }
}
