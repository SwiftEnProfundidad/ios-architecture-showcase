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

actor SuspendedExecuteListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult
    private var continuation: CheckedContinuation<FlightListResult, Error>?
    private(set) var executeWasCalled = false

    init(result: FlightListResult) {
        self.result = result
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        executeWasCalled = true
        return try await withCheckedThrowingContinuation { self.continuation = $0 }
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }

    func awaitExecuteCall() async {
        while !executeWasCalled {
            await Task.yield()
        }
    }

    func resumeExecute() {
        continuation?.resume(returning: result)
        continuation = nil
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

actor SuspendedRefreshListFlightsUseCaseSpy: ListFlightsExecuting {
    private let pageResult: FlightListResult
    private let refreshedFlights: [Flight]
    private var continuation: CheckedContinuation<[Flight], Error>?
    private(set) var refreshWasCalled = false

    init(pageResult: FlightListResult, refreshedFlights: [Flight]) {
        self.pageResult = pageResult
        self.refreshedFlights = refreshedFlights
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        pageResult
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        refreshWasCalled = true
        return try await withCheckedThrowingContinuation { self.continuation = $0 }
    }

    func awaitRefreshCall() async {
        while !refreshWasCalled {
            await Task.yield()
        }
    }

    func resumeRefresh() {
        continuation?.resume(returning: refreshedFlights)
        continuation = nil
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
