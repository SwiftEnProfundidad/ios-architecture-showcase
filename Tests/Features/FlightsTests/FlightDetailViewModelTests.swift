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
        let viewModel = FlightDetailViewModel(
            detailUseCase: FlightDetailExecutor(result: .success(detail)),
            eventBus: NavigationEventBusSpy(),
            flightID: detail.flight.id
        )

        await viewModel.load()

        #expect(viewModel.detail == detail)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("Loading flight detail exposes a localized error when the use case fails")
    func loadExposesError() async {
        let viewModel = FlightDetailViewModel(
            detailUseCase: FlightDetailExecutor(result: .failure(FlightError.network)),
            eventBus: NavigationEventBusSpy(),
            flightID: FlightID("IB3456")
        )

        await viewModel.load()

        #expect(viewModel.detail == nil)
        #expect(viewModel.errorMessage == AppStrings.localized("flights.error.detail"))
        #expect(viewModel.isLoading == false)
    }

    @Test("Requesting the boarding pass publishes the navigation event")
    func requestBoardingPassPublishesEvent() async {
        let bus = NavigationEventBusSpy()
        let viewModel = FlightDetailViewModel(
            detailUseCase: FlightDetailExecutor(
                result: .success(
                    FlightDetail(
                        flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
                        weather: nil
                    )
                )
            ),
            eventBus: bus,
            flightID: FlightID("IB3456")
        )

        await viewModel.requestBoardingPass()

        let lastEvent = await bus.lastPublishedEvent
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
