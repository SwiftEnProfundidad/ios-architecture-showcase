import SharedKernel

public struct ListFlightsUseCase<Repository: FlightRepositoryProtocol>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(passengerID: PassengerID) async throws -> [Flight] {
        try await repository.fetchAll(passengerID: passengerID)
    }

    public func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        try await withThrowingTaskGroup(of: Flight.self) { group in
            for flightID in flightIDs {
                group.addTask {
                    try await repository.fetchByID(flightID)
                }
            }
            var results: [Flight] = []
            for try await flight in group {
                results.append(flight)
            }
            return results
        }
    }
}
