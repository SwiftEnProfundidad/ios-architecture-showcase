import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
@Suite("BoardingPassViewRender")
struct BoardingPassViewRenderTests {
    @Test("Boarding pass renders the loading skeleton")
    func rendersLoadingState() async throws {
        let pass = BoardingPassData.stub(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001")
        )
        let tracked = makeSUT(suspendedPass: pass)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let task = Task {
            await context.viewModel.load()
        }
        await Task.yield()

        let data = try renderedPNG(from: BoardingPassView(viewModel: context.viewModel))

        #expect(context.viewModel.isLoading)
        #expect(data.count > 1_000)

        await context.executor.resume()
        await task.value
    }

    @Test("Boarding pass renders the content state")
    func rendersContentState() async throws {
        let pass = BoardingPassData.stub(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001")
        )
        let tracked = makeSUT(result: .success(pass), flightID: pass.flightID)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        let data = try renderedPNG(from: BoardingPassView(viewModel: context.viewModel), colorScheme: .dark)

        #expect(context.viewModel.boardingPass == pass)
        #expect(data.count > 1_000)
    }

    @Test("Boarding pass renders the error state")
    func rendersErrorState() async throws {
        let tracked = makeSUT(
            result: .failure(BoardingPassError.notFound),
            flightID: FlightID("IB3456")
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        let data = try renderedPNG(from: BoardingPassView(viewModel: context.viewModel))

        #expect(context.viewModel.errorMessage == AppStrings.localized("boardingpass.error.load"))
        #expect(data.count > 1_000)
    }

    private func makeSUT(
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

    private func makeSUT(
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
}

private struct BoardingPassViewRenderContext<Executor: BoardingPassGetting> {
    let viewModel: BoardingPassViewModel<Executor>
    let executor: Executor
}

private actor SuspendedBoardingPassExecutor: BoardingPassGetting {
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

private actor ImmediateBoardingPassExecutor: BoardingPassGetting {
    private let result: Result<BoardingPassData, Error>

    init(result: Result<BoardingPassData, Error>) {
        self.result = result
    }

    func execute(flightID: FlightID) async throws -> BoardingPassData {
        try result.get()
    }
}
