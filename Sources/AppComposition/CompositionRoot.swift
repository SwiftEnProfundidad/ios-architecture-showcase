import Auth
import Flights
import BoardingPass
import SharedKernel
import SharedNavigation

@MainActor
public enum CompositionRoot {

    public static func makeEventBus() -> DefaultNavigationEventBus {
        DefaultNavigationEventBus()
    }

    public static func makeAppStateStore() -> AppStateStore {
        AppStateStore()
    }

    public static func makeAppCoordinator(
        bus: DefaultNavigationEventBus,
        store: AppStateStore
    ) -> AppCoordinator {
        AppCoordinator(bus: bus, store: store)
    }

    public static func makeLoginUseCase(
        bus: DefaultNavigationEventBus
    ) -> LoginUseCase<InMemoryAuthGateway, InMemorySessionStore> {
        LoginUseCase(
            gateway: InMemoryAuthGateway(),
            sessionStore: InMemorySessionStore(),
            eventBus: bus
        )
    }

    public static func makeLogoutUseCase(
        sessionStore: InMemorySessionStore,
        bus: DefaultNavigationEventBus
    ) -> LogoutUseCase<InMemorySessionStore> {
        LogoutUseCase(sessionStore: sessionStore, eventBus: bus)
    }

    public static func makeListFlightsUseCase() -> ListFlightsUseCase<InMemoryFlightRepository> {
        ListFlightsUseCase(repository: InMemoryFlightRepository())
    }

    public static func makeGetFlightDetailUseCase()
        -> GetFlightDetailUseCase<InMemoryFlightRepository, InMemoryWeatherRepository>
    {
        GetFlightDetailUseCase(
            flightRepository: InMemoryFlightRepository(),
            weatherRepository: InMemoryWeatherRepository()
        )
    }

    public static func makeGetBoardingPassUseCase(
        bus: DefaultNavigationEventBus
    ) -> GetBoardingPassUseCase<InMemoryBoardingPassRepository> {
        GetBoardingPassUseCase(
            repository: InMemoryBoardingPassRepository(),
            eventBus: bus
        )
    }
}
