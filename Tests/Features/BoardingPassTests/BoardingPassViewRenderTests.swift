import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
@Suite("BoardingPassViewRender")
struct BoardingPassViewRenderTests {
    @Test("Boarding pass renders the loading skeleton")
    func rendersLoadingState() async throws {
        let executor = SuspendedBoardingPassExecutor(
            pass: BoardingPassData.stub(
                flightID: FlightID("IB3456"),
                passengerID: PassengerID("PAX-001")
            )
        )
        let viewModel = BoardingPassViewModel(
            useCase: executor,
            flightID: FlightID("IB3456")
        )

        let task = Task {
            await viewModel.load()
        }
        await Task.yield()

        let data = try renderedPNG(from: BoardingPassView(viewModel: viewModel))

        #expect(viewModel.isLoading)
        #expect(data.count > 1_000)

        await executor.resume()
        await task.value
    }

    @Test("Boarding pass renders the content state")
    func rendersContentState() async throws {
        let pass = BoardingPassData.stub(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001")
        )
        let viewModel = BoardingPassViewModel(
            useCase: ImmediateBoardingPassExecutor(result: .success(pass)),
            flightID: pass.flightID
        )

        await viewModel.load()
        let data = try renderedPNG(from: BoardingPassView(viewModel: viewModel), colorScheme: .dark)

        #expect(viewModel.boardingPass == pass)
        #expect(data.count > 1_000)
    }

    @Test("Boarding pass renders the error state")
    func rendersErrorState() async throws {
        let viewModel = BoardingPassViewModel(
            useCase: ImmediateBoardingPassExecutor(result: .failure(BoardingPassError.notFound)),
            flightID: FlightID("IB3456")
        )

        await viewModel.load()
        let data = try renderedPNG(from: BoardingPassView(viewModel: viewModel))

        #expect(viewModel.errorMessage == AppStrings.localized("boardingpass.error.load"))
        #expect(data.count > 1_000)
    }
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
