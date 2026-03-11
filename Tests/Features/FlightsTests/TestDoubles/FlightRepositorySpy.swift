import FlightsFeature
import SharedKernel

actor FlightRepositorySpy: FlightRepositoryProtocol {
    private var stubbedFlights: [Flight] = []
    private var pageResults: [Int: FlightListResult] = [:]
    private var stubbedError: FlightError?
    private(set) var fetchByIDCallCount = 0
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
        if let error = stubbedError { throw error }
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

    func fetchByID(_ id: FlightID) async throws -> Flight {
        fetchByIDCallCount += 1
        if let error = stubbedError { throw error }
        guard let flight = stubbedFlights.first(where: { $0.id == id }) else {
            throw FlightError.notFound
        }
        return flight
    }

    func refresh(_ id: FlightID) async throws -> Flight {
        refreshCallCount += 1
        return try await fetchByID(id)
    }
}
