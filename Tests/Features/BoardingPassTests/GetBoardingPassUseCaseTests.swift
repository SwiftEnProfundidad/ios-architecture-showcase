import BoardingPassFeature
import SharedKernel
import Testing

@Suite("GetBoardingPassUseCase")
struct GetBoardingPassUseCaseTests {

    @Test("Given flight with boarding pass, when fetching, then returns the correct pass")
    func getBoardingPassReturnsCorrectPass() async throws {
        let tracked = makeGetBoardingPassUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let flightID = FlightID("IB3456")
        let passengerID = PassengerID("PAX-001")
        let expected = BoardingPassData.stub(flightID: flightID, passengerID: passengerID)
        await context.repository.stub(pass: expected, forFlightID: flightID)

        let result = try await context.sut.execute(flightID: flightID)

        #expect(result.flightID == flightID)
        #expect(result.passengerID == passengerID)
    }

    @Test("Given flight without boarding pass, when fetching, then throws BoardingPassError.notFound")
    func getBoardingPassThrowsWhenNotFound() async {
        let tracked = makeGetBoardingPassUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let flightID = FlightID("IB9999")
        await context.repository.stubError(.notFound, forFlightID: flightID)

        await #expect(throws: BoardingPassError.notFound) {
            try await context.sut.execute(flightID: flightID)
        }
    }
}
