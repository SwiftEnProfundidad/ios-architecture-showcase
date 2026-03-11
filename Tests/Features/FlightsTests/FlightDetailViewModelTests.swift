import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightDetailViewModel")
struct FlightDetailViewModelTests {
    @Test("Loading flight detail populates the detail state")
    func loadPopulatesDetail() async {
        let detail = FlightDetail(
            flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 24)
        )
        let tracked = makeFlightDetailViewModelSUT(
            detailUseCase: FlightDetailExecutor(result: .success(detail)),
            flightID: detail.flight.id
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()

        #expect(context.viewModel.detail == detail)
        #expect(context.viewModel.errorMessage == nil)
        #expect(context.viewModel.isLoading == false)
    }

    @Test("Loading flight detail exposes a localized error when the use case fails")
    func loadExposesError() async {
        let tracked = makeFlightDetailViewModelSUT(
            detailUseCase: FlightDetailExecutor(result: .failure(FlightError.network)),
            flightID: FlightID("IB3456")
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()

        #expect(context.viewModel.detail == nil)
        #expect(context.viewModel.errorMessage == AppStrings.localized("flights.error.detail"))
        #expect(context.viewModel.isLoading == false)
    }

    @Test("Loading flight detail clears previously rendered content when a reload fails")
    func loadClearsStaleDetailAfterFailure() async {
        let flightID = FlightID("IB3456")
        let loadedDetail = FlightDetail(
            flight: Flight.stub(id: flightID, passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 24)
        )
        let executor = ReloadingFlightDetailExecutor(
            results: [
                .success(loadedDetail),
                .failure(FlightError.network)
            ]
        )
        let tracked = makeFlightDetailViewModelSUT(
            detailUseCase: executor,
            flightID: flightID
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        await context.viewModel.load()

        #expect(context.viewModel.detail == nil)
        #expect(context.viewModel.errorMessage == AppStrings.localized("flights.error.detail"))
        #expect(context.viewModel.isLoading == false)
    }

    @Test("Requesting the boarding pass publishes the navigation event")
    func requestBoardingPassPublishesEvent() async {
        let tracked = makeFlightDetailViewModelSUT(
            detailUseCase: FlightDetailExecutor(
                result: .success(
                    FlightDetail(
                        flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
                        weather: nil
                    )
                )
            ),
            flightID: FlightID("IB3456")
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.requestBoardingPass()

        let lastEvent = await context.eventBus.lastPublishedEvent
        #expect(
            lastEvent == .requestProtectedPath([
                .primaryDetail(contextID: "IB3456"),
                .secondaryAttachment(contextID: "IB3456")
            ])
        )
    }
}

private actor FlightDetailExecutor: FlightDetailGetting {
    private let result: Result<FlightDetail, Error>

    init(result: Result<FlightDetail, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try result.get()
    }
}

private actor ReloadingFlightDetailExecutor: FlightDetailGetting {
    private var results: [Result<FlightDetail, Error>]

    init(results: [Result<FlightDetail, Error>]) {
        self.results = results
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        guard results.isEmpty == false else {
            throw FlightError.network
        }
        return try results.removeFirst().get()
    }
}
