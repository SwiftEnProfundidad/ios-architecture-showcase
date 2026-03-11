import FlightsFeature
import SharedKernel
import Testing

private typealias SUT = ListFlightsUseCase<FlightPageRefreshingSpy, FlightPageRefreshingSpy>

@Suite("ListFlightsUseCase")
struct ListFlightsUseCaseTests {

    @Test("Given passenger with flights, when listing, then returns all their flights")
    func listFlightsReturnsAllFlights() async throws {
        let (token, sut, repository) = makeSUT()
        let passengerID = PassengerID("PAX-001")
        let expectedFlights = [
            Flight.stub(id: FlightID("IB001"), passengerID: passengerID),
            Flight.stub(id: FlightID("IB002"), passengerID: passengerID)
        ]
        await repository.stubPage(
            FlightListResult(
                flights: expectedFlights,
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            for: 1
        )

        let result = try await sut.execute(passengerID: passengerID, page: 1)

        #expect(result.flights.count == 2)
        #expect(result.source == .remote)
        #expect(result.isStale == false)
        #expect(result.page == 1)
        #expect(result.hasMorePages)
        _ = token
    }

    @Test("Given offline cached page, when listing, then returns stale cache with pagination metadata")
    func listFlightsReturnsCachedFlightsWhenOffline() async throws {
        let (token, sut, repository) = makeSUT()
        let passengerID = PassengerID("PAX-001")
        let cachedFlights = [
            Flight.stub(id: FlightID("IB001"), passengerID: passengerID)
        ]
        await repository.stubPage(
            FlightListResult(
                flights: cachedFlights,
                source: .cache,
                isStale: true,
                page: 2,
                hasMorePages: false
            ),
            for: 2
        )

        let result = try await sut.execute(passengerID: passengerID, page: 2)

        #expect(result.flights.count == 1)
        #expect(result.source == .cache)
        #expect(result.isStale)
        #expect(result.page == 2)
        #expect(result.hasMorePages == false)
        _ = token
    }

    @Test("Given network error, when listing, then throws FlightError.network")
    func listFlightsThrowsOnNetworkError() async {
        let (token, sut, repository) = makeSUT()
        await repository.stubError(FlightError.network)

        await #expect(throws: FlightError.network) {
            try await sut.execute(passengerID: PassengerID("PAX-001"), page: 1)
        }
        _ = token
    }

    @Test("Given requested page, when listing, then use case forwards page and configured page size")
    func listFlightsForwardsPageAndPageSize() async throws {
        let (token, sut, repository) = makeSUT()
        await repository.stubPage(
            FlightListResult(
                flights: [],
                source: .remote,
                isStale: false,
                page: 2,
                hasMorePages: false
            ),
            for: 2
        )

        _ = try await sut.execute(passengerID: PassengerID("PAX-001"), page: 2)

        let requestedPage = await repository.lastRequestedPage
        let requestedPageSize = await repository.lastRequestedPageSize
        #expect(requestedPage == 2)
        #expect(requestedPageSize == 10)
        _ = token
    }

    @Test("Concurrent refresh of multiple flights uses TaskGroup")
    func refreshMultipleFlightsConcurrently() async throws {
        let (token, sut, repository) = makeSUT()
        let passengerID = PassengerID("PAX-001")
        let flightIDs = [FlightID("IB001"), FlightID("IB002"), FlightID("IB003")]
        let stubbedFlights = flightIDs.map { Flight.stub(id: $0, passengerID: passengerID) }
        await repository.stub(flights: stubbedFlights)

        let refreshed = try await sut.refreshAll(flightIDs: flightIDs)

        #expect(refreshed.count == 3)
        let refreshCount = await repository.refreshCallCount
        #expect(refreshCount == 3)
        _ = token
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, SUT, FlightPageRefreshingSpy) {
        let token = MemoryLeakToken()
        let repository = FlightPageRefreshingSpy()
        let sut = SUT(pageReader: repository, refresher: repository)
        trackForMemoryLeaks(repository, token: token, sourceLocation: sourceLocation)
        return (token, sut, repository)
    }
}

actor FlightPageRefreshingSpy: FlightPageReading, FlightRefreshing {
    private var stubbedFlights: [Flight] = []
    private var pageResults: [Int: FlightListResult] = [:]
    private var stubbedError: FlightError?
    private(set) var refreshCallCount = 0
    private(set) var lastRequestedPage: Int?
    private(set) var lastRequestedPageSize: Int?

    func stub(flights: [Flight]) {
        stubbedFlights = flights
        stubbedError = nil
        pageResults = [:]
    }

    func stubPage(_ result: FlightListResult, for page: Int) {
        pageResults[page] = result
        stubbedError = nil
    }

    func stubError(_ error: FlightError) {
        stubbedError = error
    }

    func fetchPage(passengerID: PassengerID, page: Int, pageSize: Int) async throws -> FlightListResult {
        lastRequestedPage = page
        lastRequestedPageSize = pageSize
        if let stubbedError {
            throw stubbedError
        }
        if let result = pageResults[page] {
            return result
        }
        let filteredFlights = stubbedFlights.filter { $0.passengerID == passengerID }
        let startIndex = max((page - 1) * pageSize, 0)
        guard startIndex < filteredFlights.count else {
            return FlightListResult(
                flights: [],
                source: .remote,
                isStale: false,
                page: page,
                hasMorePages: false
            )
        }
        let endIndex = min(startIndex + pageSize, filteredFlights.count)
        return FlightListResult(
            flights: Array(filteredFlights[startIndex..<endIndex]),
            source: .remote,
            isStale: false,
            page: page,
            hasMorePages: endIndex < filteredFlights.count
        )
    }

    func refresh(_ id: FlightID) async throws -> Flight {
        refreshCallCount += 1
        if let stubbedError {
            throw stubbedError
        }
        guard let flight = stubbedFlights.first(where: { $0.id == id }) else {
            throw FlightError.notFound
        }
        return flight
    }
}
