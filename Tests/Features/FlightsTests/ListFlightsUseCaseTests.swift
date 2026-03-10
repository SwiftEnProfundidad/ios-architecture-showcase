import Testing
@testable import Flights
@testable import SharedKernel

@Suite("ListFlightsUseCase")
struct ListFlightsUseCaseTests {

    @Test("Dado pasajero con vuelos, cuando lista, entonces devuelve todos sus vuelos")
    func listFlightsReturnsAllFlights() async throws {
        let passengerID = PassengerID("PAX-001")
        let expectedFlights = [
            Flight.stub(id: FlightID("IB001"), passengerID: passengerID),
            Flight.stub(id: FlightID("IB002"), passengerID: passengerID)
        ]
        let repository = FlightRepositorySpy()
        await repository.stub(flights: expectedFlights)
        let sut = ListFlightsUseCase(repository: repository)

        let flights = try await sut.execute(passengerID: passengerID)

        #expect(flights.count == 2)
        #expect(flights[0].id == FlightID("IB001"))
        #expect(flights[1].id == FlightID("IB002"))
    }

    @Test("Dado error de red, cuando lista, entonces lanza FlightError.network")
    func listFlightsThrowsOnNetworkError() async {
        let repository = FlightRepositorySpy()
        await repository.stubError(FlightError.network)
        let sut = ListFlightsUseCase(repository: repository)

        await #expect(throws: FlightError.network) {
            try await sut.execute(passengerID: PassengerID("PAX-001"))
        }
    }

    @Test("Refresco concurrente de múltiples vuelos usa TaskGroup")
    func refreshMultipleFlightsConcurrently() async throws {
        let passengerID = PassengerID("PAX-001")
        let flightIDs = [FlightID("IB001"), FlightID("IB002"), FlightID("IB003")]
        let repository = FlightRepositorySpy()
        let stubbedFlights = flightIDs.map { Flight.stub(id: $0, passengerID: passengerID) }
        await repository.stub(flights: stubbedFlights)
        let sut = ListFlightsUseCase(repository: repository)

        let refreshed = try await sut.refreshAll(flightIDs: flightIDs)

        #expect(refreshed.count == 3)
        let fetchCount = await repository.fetchByIDCallCount
        #expect(fetchCount == 3)
    }
}
