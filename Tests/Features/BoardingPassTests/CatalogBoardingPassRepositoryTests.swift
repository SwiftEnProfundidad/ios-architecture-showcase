import BoardingPassFeature
import SharedKernel
import Testing

@Suite("CatalogBoardingPassRepository")
struct CatalogBoardingPassRepositoryTests {
    @Test("Boarding pass repository returns the boarding pass for an existing flight")
    func fetchesBoardingPass() async throws {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let pass = try await context.sut.fetch(forFlightID: FlightID("IB3456"))

        #expect(pass.flightID == FlightID("IB3456"))
        #expect(pass.passengerName.isEmpty == false)
    }

    @Test("Boarding pass repository throws not found for an unknown flight")
    func throwsWhenMissing() async {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await #expect(throws: BoardingPassError.notFound) {
            try await context.sut.fetch(forFlightID: FlightID("IB9999"))
        }
    }

    private func makeSUT(
    ) -> TrackedTestContext<CatalogBoardingPassRepositoryTestContext> {
        let sut = CatalogBoardingPassRepository()
        return makeTestContext(
            CatalogBoardingPassRepositoryTestContext(sut: sut),
        )
    }
}

private struct CatalogBoardingPassRepositoryTestContext {
    let sut: CatalogBoardingPassRepository
}
