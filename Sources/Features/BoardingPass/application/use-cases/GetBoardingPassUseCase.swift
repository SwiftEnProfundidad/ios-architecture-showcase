
public struct GetBoardingPassUseCase<Repository: BoardingPassRepositoryProtocol>: Sendable {
    private let repository: Repository
    private let eventBus: NavigationEventPublishing

    public init(repository: Repository, eventBus: NavigationEventPublishing) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func execute(flightID: FlightID) async throws -> BoardingPassData {
        let pass = try await repository.fetch(forFlightID: flightID)
        await eventBus.publish(.showBoardingPass(flightID: flightID))
        return pass
    }
}
