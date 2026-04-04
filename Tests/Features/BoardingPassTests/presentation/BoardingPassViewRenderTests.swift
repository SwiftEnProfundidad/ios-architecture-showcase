import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
@Suite("BoardingPassViewRender")
struct BoardingPassViewRenderTests {
    @Test("Given the boarding pass is loading, when the view is rendered, then the loading skeleton is shown")
    func rendersLoadingState() async throws {
        let pass = BoardingPassData.stub(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001")
        )
        let tracked = makeSuspendedBoardingPassViewRenderSUT(suspendedPass: pass)
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

    @Test("Given the boarding pass loaded successfully, when the view is rendered, then the content state is shown")
    func rendersContentState() async throws {
        let pass = BoardingPassData.stub(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001")
        )
        let tracked = makeImmediateBoardingPassViewRenderSUT(result: .success(pass), flightID: pass.flightID)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.load()
        let data = try renderedPNG(from: BoardingPassView(viewModel: context.viewModel), colorScheme: .dark)

        #expect(context.viewModel.boardingPass == pass)
        #expect(data.count > 1_000)
    }

    @Test("Given the boarding pass failed to load, when the view is rendered, then the error state is shown")
    func rendersErrorState() async throws {
        let tracked = makeImmediateBoardingPassViewRenderSUT(
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
}
