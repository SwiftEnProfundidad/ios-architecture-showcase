import FlightsFeature
import SharedKernel

actor FlightDetailExecutor: FlightDetailGetting {
    private let result: Result<FlightDetail, Error>

    init(result: Result<FlightDetail, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try result.get()
    }
}

actor ReloadingFlightDetailExecutor: FlightDetailGetting {
    private var results: [Result<FlightDetail, Error>]

    init(results: [Result<FlightDetail, Error>]) {
        self.results = results
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        guard results.isEmpty == false else {
            throw FlightError.network
        }
        return try results.removeFirst().get()
    }
}

actor SuspendedFlightDetailExecutor: FlightDetailGetting {
    private let detail: FlightDetail
    private var continuation: CheckedContinuation<FlightDetail, Error>?

    init(detail: FlightDetail) {
        self.detail = detail
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume(returning: detail)
        continuation = nil
    }
}

actor ImmediateFlightDetailExecutor: FlightDetailGetting {
    private let result: Result<FlightDetail, Error>

    init(result: Result<FlightDetail, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> FlightDetail {
        try result.get()
    }
}
