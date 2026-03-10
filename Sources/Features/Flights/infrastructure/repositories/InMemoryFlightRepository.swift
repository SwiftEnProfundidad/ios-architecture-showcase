
public struct InMemoryFlightRepository: FlightRepositoryProtocol {
    private let flights: [Flight]

    public init() {
        let passengerID = PassengerID("PAX-001")
        flights = [
            Flight(id: FlightID("IB3456"), passengerID: passengerID, number: "IB3456",
                   origin: "MAD", destination: "BCN", status: .onTime,
                   scheduledDeparture: "10:30", gate: "A12"),
            Flight(id: FlightID("IB7821"), passengerID: passengerID, number: "IB7821",
                   origin: "BCN", destination: "LHR", status: .boarding,
                   scheduledDeparture: "14:15", gate: "B03"),
            Flight(id: FlightID("IB2201"), passengerID: passengerID, number: "IB2201",
                   origin: "LHR", destination: "MAD", status: .delayed,
                   scheduledDeparture: "18:45", gate: "C22")
        ]
    }

    public func fetchAll(passengerID: PassengerID) async throws -> [Flight] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return flights.filter { $0.passengerID == passengerID }
    }

    public func fetchByID(_ id: FlightID) async throws -> Flight {
        try await Task.sleep(nanoseconds: 100_000_000)
        guard let flight = flights.first(where: { $0.id == id }) else {
            throw FlightError.notFound
        }
        return flight
    }
}
