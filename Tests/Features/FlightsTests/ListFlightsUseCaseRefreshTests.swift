import FlightsFeature
import SharedKernel
import Testing

@Suite("ListFlightsUseCase refresh")
struct ListFlightsUseCaseRefreshTests {

    @Test("Concurrent refresh of multiple flights uses TaskGroup")
    func refreshMultipleFlightsConcurrently() async throws {
        let tracked = makeListFlightsUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")
        let flightIDs = [FlightID("IB001"), FlightID("IB002"), FlightID("IB003")]
        let stubbedFlights = flightIDs.map { Flight.stub(id: $0, passengerID: passengerID) }
        await context.repository.stub(flights: stubbedFlights)

        let refreshed = try await context.sut.refreshAll(flightIDs: flightIDs)

        #expect(refreshed.count == 3)
        let refreshCount = await context.repository.refreshCallCount
        #expect(refreshCount == 3)
    }
}
