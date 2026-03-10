
public protocol FlightRepositoryProtocol: Sendable {
    func fetchAll(passengerID: PassengerID) async throws -> [Flight]
    func fetchByID(_ id: FlightID) async throws -> Flight
}
