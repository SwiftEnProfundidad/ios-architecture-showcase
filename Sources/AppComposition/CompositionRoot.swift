import AuthFeature
import BoardingPassFeature
import FlightsFeature
import SharedKernel
import SharedNavigation
import SwiftUI

@MainActor
public final class CompositionRoot {
    public let appViewModel: AppViewModel
    public let coordinator: DefaultAppCoordinator

    private let authFeatureAssembly: AuthFeatureAssembly
    private let flightsFeatureAssembly: FlightsFeatureAssembly
    private let boardingPassFeatureAssembly: BoardingPassFeatureAssembly
    private let sessionBootstrapper: SessionBootstrapper
    private let syncProtectedPathCommand: @Sendable ([AppRoute]) async -> Void
    private var hasStarted = false

    public convenience init(evaluationCredentials: ShowcaseEvaluationCredentials = .default) {
        self.init(
            runtime: ShowcaseRuntime.live(
                evaluationCredentials: evaluationCredentials
            )
        )
    }

    init(runtime: ShowcaseRuntime) {
        self.authFeatureAssembly = AuthFeatureAssembly(
            runtime: runtime.auth,
            navigation: runtime.navigation
        )
        self.flightsFeatureAssembly = FlightsFeatureAssembly(
            runtime: runtime.flights,
            sessionStore: runtime.auth.sessionStore,
            navigation: runtime.navigation
        )
        self.boardingPassFeatureAssembly = BoardingPassFeatureAssembly(
            runtime: runtime.boardingPass
        )
        self.sessionBootstrapper = SessionBootstrapper(
            sessionStore: runtime.auth.sessionStore,
            stateStore: runtime.navigation.stateStore,
            policy: runtime.auth.launchPolicy
        )
        self.appViewModel = AppViewModel(store: runtime.navigation.stateStore)
        self.syncProtectedPathCommand = { [eventBus = runtime.navigation.eventBus] path in
            await eventBus.publish(.syncProtectedPath(path))
        }
        self.coordinator = AppCoordinator(
            bus: runtime.navigation.eventBus,
            store: runtime.navigation.stateStore,
            invalidatePersistedSession: { [sessionStore = runtime.auth.sessionStore] in
                await sessionStore.clear()
            }
        )
    }

    public func start() async {
        guard hasStarted == false else {
            return
        }
        hasStarted = true
        await coordinator.start()
        await sessionBootstrapper.bootstrap()
    }

    public func makeLoginView() -> some View {
        authFeatureAssembly.makeView()
    }

    public func makeFlightListView(session: AppSession) -> some View {
        flightsFeatureAssembly.makeListView(session: session)
    }

    public func makeFlightDetailView(flightID: FlightID) -> some View {
        flightsFeatureAssembly.makeDetailView(flightID: flightID)
    }

    public func makeBoardingPassView(flightID: FlightID) -> some View {
        boardingPassFeatureAssembly.makeView(flightID: flightID)
    }

    public func syncProtectedPath(_ path: [AppRoute]) async {
        await syncProtectedPathCommand(path)
    }
}
