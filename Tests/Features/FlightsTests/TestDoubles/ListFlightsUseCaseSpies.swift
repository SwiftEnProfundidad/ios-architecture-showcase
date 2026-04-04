import FlightsFeature
import SharedKernel

actor ListFlightsUseCaseSpy: ListFlightsExecuting {
    private var pageResults: [Int: FlightListResult] = [:]
    private var refreshResult: [Flight] = []
    private var refreshError: Error?
    private(set) var executePages: [Int] = []
    private(set) var lastRefreshFlightIDs: [FlightID]?

    func stubPage(result: FlightListResult, for page: Int) {
        pageResults[page] = result
    }

    func stubRefreshResult(_ flights: [Flight]) {
        refreshResult = flights
    }

    func stubRefreshError(_ error: Error) {
        refreshError = error
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        executePages.append(page)
        return pageResults[page] ?? FlightListResult(
            flights: [],
            source: .remote,
            isStale: false,
            page: page,
            hasMorePages: false
        )
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        lastRefreshFlightIDs = flightIDs
        if let refreshError {
            throw refreshError
        }
        return refreshResult.isEmpty ? flightIDs.map { Flight.stub(id: $0, passengerID: defaultFlightListPassengerID) } : refreshResult
    }
}

actor SlowListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult

    init(result: FlightListResult) {
        self.result = result
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        try await Task.sleep(nanoseconds: 150_000_000)
        return result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }
}

actor InstantListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult

    init(result: FlightListResult) {
        self.result = result
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }
}

actor SlowExpiringListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult
    private let delayNanoseconds: UInt64

    init(result: FlightListResult, delayNanoseconds: UInt64) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }
}

actor RefreshDelayListFlightsUseCaseSpy: ListFlightsExecuting {
    private let pageResult: FlightListResult
    private let refreshedFlights: [Flight]
    private let delayNanoseconds: UInt64

    init(pageResult: FlightListResult, refreshedFlights: [Flight], delayNanoseconds: UInt64) {
        self.pageResult = pageResult
        self.refreshedFlights = refreshedFlights
        self.delayNanoseconds = delayNanoseconds
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        pageResult
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return refreshedFlights
    }
}

actor SuspendedNextPageListFlightsUseCaseSpy: ListFlightsExecuting {
    private let firstPage: FlightListResult
    private let secondPage: FlightListResult
    private var secondPageRequested = false
    private var continuation: CheckedContinuation<Void, Never>?

    init(firstPage: FlightListResult, secondPage: FlightListResult) {
        self.firstPage = firstPage
        self.secondPage = secondPage
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        if page == 1 {
            return firstPage
        }
        secondPageRequested = true
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        return secondPage
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }

    func awaitSecondPageRequest() async {
        while secondPageRequested == false {
            await Task.yield()
        }
    }

    func finishSecondPageRequest() {
        continuation?.resume()
        continuation = nil
    }
}
