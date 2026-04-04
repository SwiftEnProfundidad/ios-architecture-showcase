import BoardingPassFeature
import SharedKernel

actor SuspendedBoardingPassExecutor: BoardingPassGetting {
    private let pass: BoardingPassData
    private var continuation: CheckedContinuation<BoardingPassData, Error>?

    init(pass: BoardingPassData) {
        self.pass = pass
    }

    func execute(flightID: FlightID) async throws -> BoardingPassData {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume(returning: pass)
        continuation = nil
    }
}

actor ImmediateBoardingPassExecutor: BoardingPassGetting {
    private let result: Result<BoardingPassData, Error>

    init(result: Result<BoardingPassData, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> BoardingPassData {
        try result.get()
    }
}
