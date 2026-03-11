import BoardingPassFeature
import SharedKernel
import Testing

@Suite("CatalogBoardingPassRepository")
struct CatalogBoardingPassRepositoryTests {
    @Test("Boarding pass repository returns the boarding pass for an existing flight")
    func fetchesBoardingPass() async throws {
        let repository = CatalogBoardingPassRepository()

        let pass = try await repository.fetch(forFlightID: FlightID("IB3456"))

        #expect(pass.flightID == FlightID("IB3456"))
        #expect(pass.passengerName.isEmpty == false)
    }

    @Test("Boarding pass repository throws not found for an unknown flight")
    func throwsWhenMissing() async {
        let repository = CatalogBoardingPassRepository()

        await #expect(throws: BoardingPassError.notFound) {
            try await repository.fetch(forFlightID: FlightID("IB9999"))
        }
    }
}
