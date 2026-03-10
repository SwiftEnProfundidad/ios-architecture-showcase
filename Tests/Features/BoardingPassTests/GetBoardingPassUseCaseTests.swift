import Testing
@testable import BoardingPass
@testable import SharedKernel
@testable import SharedNavigation

private typealias SUT = GetBoardingPassUseCase<BoardingPassRepositorySpy>

@Suite("GetBoardingPassUseCase")
struct GetBoardingPassUseCaseTests {

    @Test("Dado vuelo con tarjeta de embarque, cuando obtiene, entonces devuelve la tarjeta correcta")
    func getBoardingPassReturnsCorrectPass() async throws {
        let flightID = FlightID("IB3456")
        let passengerID = PassengerID("PAX-001")
        let expected = BoardingPassData.stub(flightID: flightID, passengerID: passengerID)
        let repository = BoardingPassRepositorySpy()
        await repository.stub(pass: expected, forFlightID: flightID)
        let bus = NavigationEventBusSpy()
        let sut = SUT(repository: repository, eventBus: bus)

        let result = try await sut.execute(flightID: flightID)

        #expect(result.flightID == flightID)
        #expect(result.passengerID == passengerID)
        let lastEvent = await bus.lastPublishedEvent
        #expect(lastEvent == .showBoardingPass(flightID: flightID))
    }

    @Test("Dado vuelo sin tarjeta, cuando obtiene, entonces lanza BoardingPassError.notFound")
    func getBoardingPassThrowsWhenNotFound() async {
        let flightID = FlightID("IB9999")
        let repository = BoardingPassRepositorySpy()
        await repository.stubError(.notFound, forFlightID: flightID)
        let bus = NavigationEventBusSpy()
        let sut = SUT(repository: repository, eventBus: bus)

        await #expect(throws: BoardingPassError.notFound) {
            try await sut.execute(flightID: flightID)
        }
    }
}
