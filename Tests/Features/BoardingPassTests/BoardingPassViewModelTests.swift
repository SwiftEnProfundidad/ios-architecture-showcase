import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
@Suite("BoardingPassViewModel")
struct BoardingPassViewModelTests {

    @Test("Loading a boarding pass populates the screen state")
    func loadPopulatesBoardingPass() async {
        let repository = BoardingPassRepositorySpy()
        let flightID = FlightID("IB3456")
        let pass = BoardingPassData.stub(flightID: flightID, passengerID: PassengerID("PAX-001"))
        await repository.stub(pass: pass, forFlightID: flightID)
        let sut = BoardingPassViewModel(
            useCase: GetBoardingPassUseCase(repository: repository),
            flightID: flightID
        )

        await sut.load()

        #expect(sut.boardingPass == pass)
        #expect(sut.errorMessage == nil)
    }
}
