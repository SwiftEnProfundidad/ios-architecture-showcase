import Observation
import Flights
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class FlightDetailViewModel {
    public private(set) var detail: FlightDetail?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let detailUseCase: GetFlightDetailUseCase<InMemoryFlightRepository, InMemoryWeatherRepository>
    private let eventBus: NavigationEventPublishing
    private let flightID: FlightID

    public init(
        detailUseCase: GetFlightDetailUseCase<InMemoryFlightRepository, InMemoryWeatherRepository>,
        eventBus: NavigationEventPublishing,
        flightID: FlightID
    ) {
        self.detailUseCase = detailUseCase
        self.eventBus = eventBus
        self.flightID = flightID
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await detailUseCase.execute(flightID: flightID)
        } catch {
            errorMessage = String(localized: "flights.error.detail")
        }
    }

    public func requestBoardingPass() async {
        await eventBus.publish(.showBoardingPass(flightID: flightID))
    }

    public func goBack() async {
        await eventBus.publish(.backToFlightList)
    }
}
