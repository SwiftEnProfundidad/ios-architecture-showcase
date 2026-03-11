import FlightsFeature
import SharedKernel
import Testing

typealias ListFlightsUseCaseSUT = ListFlightsUseCase<FlightPageRefreshingSpy, FlightPageRefreshingSpy>

struct ListFlightsUseCaseTestContext {
    let sut: ListFlightsUseCaseSUT
    let repository: FlightPageRefreshingSpy
}

func makeListFlightsUseCaseSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<ListFlightsUseCaseTestContext> {
    let repository = FlightPageRefreshingSpy()
    let sut = ListFlightsUseCaseSUT(pageReader: repository, refresher: repository)
    return makeLeakTrackedTestContext(
        ListFlightsUseCaseTestContext(
            sut: sut,
            repository: repository
        ),
        trackedInstances: repository,
        sourceLocation: sourceLocation
    )
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
