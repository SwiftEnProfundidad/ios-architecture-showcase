import AuthFeature
import BoardingPassFeature
import FlightsFeature
import SharedNavigation

struct ShowcaseRuntime {
    let navigation: NavigationRuntime
    let auth: AuthRuntime
    let flights: FlightsRuntime
    let boardingPass: BoardingPassRuntime

    static func live(
        evaluationCredentials: ShowcaseEvaluationCredentials = .default
    ) -> ShowcaseRuntime {
        let navigation = NavigationRuntime(
            eventBus: DefaultNavigationEventBus(),
            stateStore: AppStateStore()
        )
        let authConfiguration = ShowcaseAuthRuntimeConfiguration.live(
            evaluationCredentials: evaluationCredentials
        )
        let auth = AuthRuntime(
            gateway: RemoteAuthGateway(
                client: URLSessionHTTPClient(session: authConfiguration.session),
                baseURL: authConfiguration.baseURL
            ),
            sessionStore: KeychainSessionStore(),
            quickAccessCredentials: authConfiguration.evaluationCredentials,
            launchPolicy: authConfiguration.launchPolicy
        )
        let flights = FlightsRuntime(
            flightRepository: CatalogFlightRepository(),
            weatherRepository: CatalogWeatherRepository(),
            minimumInitialSkeletonNanoseconds: 450_000_000,
            minimumNextPageSpinnerNanoseconds: 180_000_000
        )
        let boardingPass = BoardingPassRuntime(
            repository: CatalogBoardingPassRepository()
        )
        return ShowcaseRuntime(
            navigation: navigation,
            auth: auth,
            flights: flights,
            boardingPass: boardingPass
        )
    }
}

struct NavigationRuntime {
    let eventBus: DefaultNavigationEventBus
    let stateStore: AppStateStore
}

struct AuthRuntime {
    let gateway: RemoteAuthGateway<URLSessionHTTPClient>
    let sessionStore: KeychainSessionStore
    let quickAccessCredentials: ShowcaseEvaluationCredentials?
    let launchPolicy: SessionLaunchPolicy
}

struct FlightsRuntime {
    let flightRepository: CatalogFlightRepository
    let weatherRepository: CatalogWeatherRepository
    let minimumInitialSkeletonNanoseconds: UInt64
    let minimumNextPageSpinnerNanoseconds: UInt64
}

struct BoardingPassRuntime {
    let repository: CatalogBoardingPassRepository
}
