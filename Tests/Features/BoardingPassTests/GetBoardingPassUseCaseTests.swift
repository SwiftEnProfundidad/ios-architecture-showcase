import BoardingPassFeature
import SharedKernel
import Testing

private typealias SUT = GetBoardingPassUseCase<BoardingPassRepositorySpy>

@Suite("GetBoardingPassUseCase")
struct GetBoardingPassUseCaseTests {

    @Test("Given flight with boarding pass, when fetching, then returns the correct pass")
    func getBoardingPassReturnsCorrectPass() async throws {
        let (token, sut, repository) = makeSUT()
        let flightID = FlightID("IB3456")
        let passengerID = PassengerID("PAX-001")
        let expected = BoardingPassData.stub(flightID: flightID, passengerID: passengerID)
        await repository.stub(pass: expected, forFlightID: flightID)

        let result = try await sut.execute(flightID: flightID)

        #expect(result.flightID == flightID)
        #expect(result.passengerID == passengerID)
        _ = token
    }

    @Test("Given flight without boarding pass, when fetching, then throws BoardingPassError.notFound")
    func getBoardingPassThrowsWhenNotFound() async {
        let (token, sut, repository) = makeSUT()
        let flightID = FlightID("IB9999")
        await repository.stubError(.notFound, forFlightID: flightID)

        await #expect(throws: BoardingPassError.notFound) {
            try await sut.execute(flightID: flightID)
        }
        _ = token
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, SUT, BoardingPassRepositorySpy) {
        let token = MemoryLeakToken()
        let repository = BoardingPassRepositorySpy()
        let sut = SUT(repository: repository)
        trackForMemoryLeaks(repository, token: token, sourceLocation: sourceLocation)
        return (token, sut, repository)
    }
}
