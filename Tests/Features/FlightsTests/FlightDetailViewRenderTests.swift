import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightDetailViewRender")
struct FlightDetailViewRenderTests {
    @Test("Flight detail renders the loading skeleton")
    func rendersLoadingState() async throws {
        let executor = SuspendedFlightDetailExecutor(
            detail: FlightDetail(
                flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
                weather: .stub(description: "Sunny", temperatureCelsius: 22)
            )
        )
        let viewModel = FlightDetailViewModel(
            detailUseCase: executor,
            eventBus: NavigationEventBusSpy(),
            flightID: FlightID("IB3456")
        )

        let task = Task {
            await viewModel.load()
        }
        await Task.yield()

        let data = try renderedPNG(from: FlightDetailView(viewModel: viewModel))

        #expect(viewModel.isLoading)
        #expect(data.count > 1_000)

        await executor.resume()
        await task.value
    }

    @Test("Flight detail renders the content state")
    func rendersContentState() async throws {
        let detail = FlightDetail(
            flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 22)
        )
        let viewModel = FlightDetailViewModel(
            detailUseCase: ImmediateFlightDetailExecutor(result: .success(detail)),
            eventBus: NavigationEventBusSpy(),
            flightID: detail.flight.id
        )

        await viewModel.load()
        let data = try renderedPNG(from: FlightDetailView(viewModel: viewModel), colorScheme: .dark)

        #expect(viewModel.detail == detail)
        #expect(data.count > 1_000)
    }

    @Test("Flight detail renders the error state")
    func rendersErrorState() async throws {
        let viewModel = FlightDetailViewModel(
            detailUseCase: ImmediateFlightDetailExecutor(result: .failure(FlightError.network)),
            eventBus: NavigationEventBusSpy(),
            flightID: FlightID("IB3456")
        )

        await viewModel.load()
        let data = try renderedPNG(from: FlightDetailView(viewModel: viewModel))

        #expect(viewModel.errorMessage == AppStrings.localized("flights.error.detail"))
        #expect(data.count > 1_000)
    }
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
