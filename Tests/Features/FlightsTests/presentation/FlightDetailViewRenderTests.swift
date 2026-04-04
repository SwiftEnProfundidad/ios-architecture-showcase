import FlightsFeature
import SharedKernel
import Testing

@MainActor
@Suite("FlightDetailViewRender")
struct FlightDetailViewRenderTests {
    @Test("Given detail is loading, when the detail view is rendered, then the loading skeleton is shown")
    func rendersLoadingState() async throws {
        let detail = FlightDetail(
            flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 22)
        )
        let tracked = makeSuspendedFlightDetailViewRenderSUT(suspendedDetail: detail)
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

    @Test("Given detail loaded successfully, when the detail view is rendered, then the content state is shown")
    func rendersContentState() async throws {
        let detail = FlightDetail(
            flight: Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001")),
            weather: .stub(description: "Sunny", temperatureCelsius: 22)
        )
        let tracked = makeImmediateFlightDetailViewRenderSUT(result: .success(detail), flightID: detail.flight.id)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        let data = try renderedPNG(from: FlightDetailView(viewModel: context.viewModel), colorScheme: .dark)

        #expect(context.viewModel.detail == detail)
        #expect(data.count > 1_000)
    }

    @Test("Given detail failed to load, when the detail view is rendered, then the error state is shown")
    func rendersErrorState() async throws {
        let tracked = makeImmediateFlightDetailViewRenderSUT(
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
}
