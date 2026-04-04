import AuthFeature
import FlightsFeature
import SharedKernel
import SharedNavigation
import SwiftUI

@MainActor
struct FlightsFeatureAssembly {
    private let runtime: FlightsRuntime
    private let sessionStore: KeychainSessionStore
    private let navigation: NavigationRuntime

    init(
        runtime: FlightsRuntime,
        sessionStore: KeychainSessionStore,
        navigation: NavigationRuntime
    ) {
        self.runtime = runtime
        self.sessionStore = sessionStore
        self.navigation = navigation
    }

    func makeListView(session: AppSession) -> some View {
        FlightListScene(
            viewModel: FlightListViewModel(
                listUseCase: ListFlightsUseCase(repository: runtime.flightRepository),
                sessionController: FlightListSessionController(
                    logoutUseCase: LogoutUseCase(sessionStore: sessionStore),
                    eventBus: navigation.eventBus,
                    sessionExpiresAt: session.expiresAt
                ),
                eventBus: navigation.eventBus,
                passengerID: session.passengerID,
                minimumInitialSkeletonNanoseconds: runtime.minimumInitialSkeletonNanoseconds,
                minimumNextPageSpinnerNanoseconds: runtime.minimumNextPageSpinnerNanoseconds
            )
        )
    }

    func makeDetailView(flightID: FlightID) -> some View {
        FlightDetailScene(
            viewModel: FlightDetailViewModel(
                detailUseCase: GetFlightDetailUseCase(
                    flightRepository: runtime.flightRepository,
                    weatherRepository: runtime.weatherRepository
                ),
                eventBus: navigation.eventBus,
                flightID: flightID
            )
        )
    }
}

private struct FlightListScene<ListExecutor: ListFlightsExecuting, SessionController: FlightListSessionControlling, FeedbackClock: Clock<Duration>>: View {
    @State private var viewModel: FlightListViewModel<ListExecutor, SessionController, FeedbackClock>

    init(viewModel: FlightListViewModel<ListExecutor, SessionController, FeedbackClock>) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        FlightListView(viewModel: viewModel)
    }
}

private struct FlightDetailScene<DetailUseCase: FlightDetailGetting>: View {
    @State private var viewModel: FlightDetailViewModel<DetailUseCase>

    init(viewModel: FlightDetailViewModel<DetailUseCase>) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        FlightDetailView(viewModel: viewModel)
    }
}
