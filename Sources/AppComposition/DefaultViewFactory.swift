#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class DefaultViewFactory: Sendable {
    private let bus: DefaultNavigationEventBus
    private let passengerID: PassengerID

    public init(bus: DefaultNavigationEventBus, passengerID: PassengerID) {
        self.bus = bus
        self.passengerID = passengerID
    }

    public func makeLoginView() -> LoginView {
        LoginView(viewModel: AuthViewModel(
            loginUseCase: LoginUseCase(
                gateway: InMemoryAuthGateway(),
                sessionStore: InMemorySessionStore(),
                eventBus: bus
            )
        ))
    }

    public func makeFlightListView() -> FlightListView {
        FlightListView(viewModel: FlightListViewModel(
            listUseCase: ListFlightsUseCase(repository: InMemoryFlightRepository()),
            eventBus: bus,
            passengerID: passengerID
        ))
    }

    public func makeFlightDetailView(flightID: FlightID) -> FlightDetailView {
        FlightDetailView(viewModel: FlightDetailViewModel(
            detailUseCase: GetFlightDetailUseCase(
                flightRepository: InMemoryFlightRepository(),
                weatherRepository: InMemoryWeatherRepository()
            ),
            eventBus: bus,
            flightID: flightID
        ))
    }

    public func makeBoardingPassView(flightID: FlightID) -> BoardingPassView {
        BoardingPassView(viewModel: BoardingPassViewModel(
            useCase: GetBoardingPassUseCase(
                repository: InMemoryBoardingPassRepository(),
                eventBus: bus
            ),
            eventBus: bus,
            flightID: flightID
        ))
    }
}
#endif
