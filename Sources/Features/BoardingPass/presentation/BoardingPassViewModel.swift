import Observation

@MainActor
@Observable
public final class BoardingPassViewModel {
    public private(set) var boardingPass: BoardingPassData?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let useCase: GetBoardingPassUseCase<InMemoryBoardingPassRepository>
    private let eventBus: NavigationEventPublishing
    private let flightID: FlightID

    public init(
        useCase: GetBoardingPassUseCase<InMemoryBoardingPassRepository>,
        eventBus: NavigationEventPublishing,
        flightID: FlightID
    ) {
        self.useCase = useCase
        self.eventBus = eventBus
        self.flightID = flightID
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            boardingPass = try await useCase.execute(flightID: flightID)
        } catch {
            errorMessage = String(localized: "boardingpass.error.load")
        }
    }

    public func goBack() async {
        await eventBus.publish(.backToFlightDetail(flightID: flightID))
    }
}
