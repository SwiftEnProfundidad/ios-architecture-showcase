import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightDetailViewModel")
struct FlightDetailViewModelTests {
    @Test("Given a successful detail load, when loading completes, then the detail state is populated")
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

    @Test("Given the detail use case fails, when loading completes, then a localized error is exposed")
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

    @Test("Given previously rendered detail content, when a reload fails, then prior content is cleared")
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

    @Test("Given a flight with boarding pass access, when boarding pass is requested, then the navigation event is published")
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
