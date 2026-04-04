import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
@Suite("BoardingPassViewModel")
struct BoardingPassViewModelTests {

    @Test("Given a successful boarding pass load, when loading completes, then screen state is populated")
    func loadPopulatesBoardingPass() async {
        let flightID = FlightID("IB3456")
        let pass = BoardingPassData.stub(flightID: flightID, passengerID: PassengerID("PAX-001"))
        let tracked = makeBoardingPassViewModelSUT(flightID: flightID)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.repository.stub(pass: pass, forFlightID: flightID)

        await context.sut.load()

        #expect(context.sut.boardingPass == pass)
        #expect(context.sut.errorMessage == nil)
    }

    @Test("Given previously rendered boarding pass content, when a reload fails, then prior content is cleared")
    func loadClearsStaleBoardingPassAfterFailure() async {
        let flightID = FlightID("IB3456")
        let pass = BoardingPassData.stub(flightID: flightID, passengerID: PassengerID("PAX-001"))
        let tracked = makeReloadingBoardingPassViewModelSUT(flightID: flightID)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let stubbedResults: [Result<BoardingPassData, Error>] = [
            .success(pass),
            .failure(BoardingPassError.notFound)
        ]

        await context.repository.stub(
            results: stubbedResults,
            forFlightID: flightID
        )

        await context.sut.load()
        await context.sut.load()

        #expect(context.sut.boardingPass == nil)
        #expect(context.sut.errorMessage == AppStrings.localized("boardingpass.error.load"))
        #expect(context.sut.isLoading == false)
    }
}
