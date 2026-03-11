import SharedKernel

public protocol BoardingPassRepositoryProtocol: Sendable {
    func fetch(forFlightID flightID: FlightID) async throws -> BoardingPassData
}
