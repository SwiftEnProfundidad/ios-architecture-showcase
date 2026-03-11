import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
func makeSuspendedBoardingPassViewRenderSUT(
    suspendedPass: BoardingPassData
) -> TrackedTestContext<BoardingPassViewRenderContext<SuspendedBoardingPassExecutor>> {
    let executor = SuspendedBoardingPassExecutor(pass: suspendedPass)
    let sut = BoardingPassViewModel(
        useCase: executor,
        flightID: suspendedPass.flightID
    )
    return makeTestContext(
        BoardingPassViewRenderContext(viewModel: sut, executor: executor)
    )
}

@MainActor
func makeImmediateBoardingPassViewRenderSUT(
    result: Result<BoardingPassData, Error>,
    flightID: FlightID
) -> TrackedTestContext<BoardingPassViewRenderContext<ImmediateBoardingPassExecutor>> {
    let executor = ImmediateBoardingPassExecutor(result: result)
    let sut = BoardingPassViewModel(
        useCase: executor,
        flightID: flightID
    )
    return makeTestContext(
        BoardingPassViewRenderContext(viewModel: sut, executor: executor)
    )
}

struct BoardingPassViewRenderContext<Executor: BoardingPassGetting> {
    let viewModel: BoardingPassViewModel<Executor>
    let executor: Executor
}

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
