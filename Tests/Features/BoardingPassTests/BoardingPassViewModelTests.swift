import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
@Suite("BoardingPassViewModel")
struct BoardingPassViewModelTests {

    @Test("Loading a boarding pass populates the screen state")
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

    @Test("Loading a boarding pass clears previously rendered content when a reload fails")
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
