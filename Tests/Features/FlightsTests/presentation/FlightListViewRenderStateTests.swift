import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightListViewRender.State")
struct FlightListViewRenderStateTests {
    @Test("Given the first page is still loading, when the list is rendered, then the initial skeleton is shown")
    func rendersInitialSkeleton() async throws {
        let context = makeFlightListRenderSUT(
            mode: .initialSkeleton(
                FlightListResult(
                    flights: [Flight.stub(id: FlightID("IB1001"), passengerID: PassengerID("PAX-001"))],
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: true
                )
            )
        )

        let task = Task {
            await context.sut.load()
        }
        await Task.yield()

        let data = try renderedPNG(from: FlightListView(viewModel: context.sut))

        #expect(context.sut.isShowingInitialSkeleton)
        #expect(data.count > 1_000)

        await context.executor.resume()
        await task.value
    }

    @Test("Given stale cached flights, when the list is rendered, then rows and the stale banner are shown")
    func rendersContentAndStaleBanner() async throws {
        let context = makeFlightListRenderSUT(
            mode: .content(
                FlightListResult(
                    flights: makeRenderFlights(range: 1...10),
                    source: .cache,
                    isStale: true,
                    page: 1,
                    hasMorePages: true
                )
            )
        )

        await context.sut.load()
        let data = try renderedPNG(
            from: FlightListView(viewModel: context.sut),
            colorScheme: .dark
        )

        #expect(context.sut.flights.count == 10)
        #expect(context.sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
        #expect(data.count > 1_000)
    }

    @Test("Given the list failed with no rows, when the list is rendered, then the empty error state is shown")
    func rendersEmptyErrorState() async throws {
        let context = makeFlightListRenderSUT(mode: .emptyError(FlightError.network))

        await context.sut.load()
        let data = try renderedPNG(from: FlightListView(viewModel: context.sut))

        #expect(context.sut.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(context.sut.flights.isEmpty)
        #expect(data.count > 1_000)
    }

    @Test("Given a non-empty list and a refresh failure, when the list is rendered, then the refresh error banner is shown")
    func rendersRefreshErrorBanner() async throws {
        let context = makeFlightListRenderSUT(
            mode: .refreshError(
                firstPage: FlightListResult(
                    flights: makeRenderFlights(range: 1...10),
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: false
                ),
                refreshError: FlightError.network
            )
        )

        await context.sut.load()
        await context.sut.refresh()
        let data = try renderedPNG(from: FlightListView(viewModel: context.sut))

        #expect(context.sut.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(context.sut.flights.isEmpty == false)
        #expect(data.count > 1_000)
    }
}
