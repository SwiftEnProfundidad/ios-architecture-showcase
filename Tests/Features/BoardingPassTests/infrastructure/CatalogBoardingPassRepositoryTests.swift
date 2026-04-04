import BoardingPassFeature
import SharedKernel
import Testing

@Suite("CatalogBoardingPassRepository")
struct CatalogBoardingPassRepositoryTests {
    @Test("Given a flight with a boarding pass in the catalog, when fetching the pass, then it is returned")
    func fetchesBoardingPass() async throws {
        let tracked = makeCatalogBoardingPassRepositorySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let pass = try await context.sut.fetch(forFlightID: FlightID("IB3456"))

        #expect(pass.flightID == FlightID("IB3456"))
        #expect(pass.passengerName.isEmpty == false)
    }

    @Test("Given an unknown flight id, when fetching the boarding pass, then not found is thrown")
    func throwsWhenMissing() async {
        let tracked = makeCatalogBoardingPassRepositorySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await #expect(throws: BoardingPassError.notFound) {
            try await context.sut.fetch(forFlightID: FlightID("IB9999"))
        }
    }
}
