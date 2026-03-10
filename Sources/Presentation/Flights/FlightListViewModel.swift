import Observation
import Flights
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class FlightListViewModel {
    public private(set) var flights: [Flight] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let listUseCase: ListFlightsUseCase<InMemoryFlightRepository>
    private let eventBus: NavigationEventPublishing
    private let passengerID: PassengerID

    public init(
        listUseCase: ListFlightsUseCase<InMemoryFlightRepository>,
        eventBus: NavigationEventPublishing,
        passengerID: PassengerID
    ) {
        self.listUseCase = listUseCase
        self.eventBus = eventBus
        self.passengerID = passengerID
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            flights = try await listUseCase.execute(passengerID: passengerID)
        } catch {
            errorMessage = String(localized: "flights.error.load")
        }
    }

    public func selectFlight(_ flight: Flight) async {
        await eventBus.publish(.showFlightDetail(flightID: flight.id))
    }
}
