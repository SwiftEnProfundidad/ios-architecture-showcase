import SharedKernel

public protocol BoardingPassGetting: Sendable {
    func execute(flightID: FlightID) async throws -> BoardingPassData
}

public struct GetBoardingPassUseCase<Repository: BoardingPassRepositoryProtocol>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(flightID: FlightID) async throws -> BoardingPassData {
        try await repository.fetch(forFlightID: flightID)
    }
}

extension GetBoardingPassUseCase: BoardingPassGetting {}
