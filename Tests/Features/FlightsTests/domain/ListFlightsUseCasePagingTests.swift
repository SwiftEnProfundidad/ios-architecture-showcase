import FlightsFeature
import SharedKernel
import Testing

@Suite("ListFlightsUseCase paging")
struct ListFlightsUseCasePagingTests {

    @Test("Given passenger with flights, when listing, then returns all their flights")
    func listFlightsReturnsAllFlights() async throws {
        let tracked = makeListFlightsUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")
        let expectedFlights = [
            Flight.stub(id: FlightID("IB001"), passengerID: passengerID),
            Flight.stub(id: FlightID("IB002"), passengerID: passengerID)
        ]
        await context.repository.stubPage(
            FlightListResult(
                flights: expectedFlights,
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            for: 1
        )

        let result = try await context.sut.execute(passengerID: passengerID, page: 1)

        #expect(result.flights.count == 2)
        #expect(result.source == .remote)
        #expect(result.isStale == false)
        #expect(result.page == 1)
        #expect(result.hasMorePages)
    }

    @Test("Given offline cached page, when listing, then returns stale cache with pagination metadata")
    func listFlightsReturnsCachedFlightsWhenOffline() async throws {
        let tracked = makeListFlightsUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")
        let cachedFlights = [
            Flight.stub(id: FlightID("IB001"), passengerID: passengerID)
        ]
        await context.repository.stubPage(
            FlightListResult(
                flights: cachedFlights,
                source: .cache,
                isStale: true,
                page: 2,
                hasMorePages: false
            ),
            for: 2
        )

        let result = try await context.sut.execute(passengerID: passengerID, page: 2)

        #expect(result.flights.count == 1)
        #expect(result.source == .cache)
        #expect(result.isStale)
        #expect(result.page == 2)
        #expect(result.hasMorePages == false)
    }

    @Test("Given network error, when listing, then throws FlightError.network")
    func listFlightsThrowsOnNetworkError() async {
        let tracked = makeListFlightsUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.repository.stubError(FlightError.network)

        await #expect(throws: FlightError.network) {
            try await context.sut.execute(passengerID: PassengerID("PAX-001"), page: 1)
        }
    }

    @Test("Given requested page, when listing, then use case forwards page and configured page size")
    func listFlightsForwardsPageAndPageSize() async throws {
        let tracked = makeListFlightsUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.repository.stubPage(
            FlightListResult(
                flights: [],
                source: .remote,
                isStale: false,
                page: 2,
                hasMorePages: false
            ),
            for: 2
        )

        _ = try await context.sut.execute(passengerID: PassengerID("PAX-001"), page: 2)

        let requestedPage = await context.repository.lastRequestedPage
        let requestedPageSize = await context.repository.lastRequestedPageSize
        #expect(requestedPage == 2)
        #expect(requestedPageSize == 10)
    }
}
