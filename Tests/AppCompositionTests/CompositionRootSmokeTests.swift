@testable import AppComposition
import SharedKernel
import SharedNavigation
import SwiftUI
import Testing

@MainActor
@Suite("CompositionRootSmoke")
struct CompositionRootSmokeTests {
    @Test("Composition root starts idempotently and renders all entry points")
    func startsAndRendersAllEntrypoints() async throws {
        let root = CompositionRoot(
            runtime: ShowcaseRuntime.live(
                evaluationCredentials: .default
            )
        )
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-composition",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )

        await root.start()
        await root.start()

        let loginData = try renderedPNG(from: root.makeLoginView())
        let listData = try renderedPNG(from: root.makeFlightListView(session: session))
        let detailData = try renderedPNG(from: root.makeFlightDetailView(flightID: FlightID("IB3456")))
        let passData = try renderedPNG(from: root.makeBoardingPassView(flightID: FlightID("IB3456")))

        #expect(loginData.count > 1_000)
        #expect(listData.count > 1_000)
        #expect(detailData.count > 1_000)
        #expect(passData.count > 1_000)
    }
}

@MainActor
@Suite("RootViewRender")
struct RootViewRenderTests {
    @Test("Root view renders the login route")
    func rendersLoginRoute() throws {
        let viewModel = AppViewModel(store: AppStateStore())

        let data = try renderedPNG(
            from: RootView(
                appViewModel: viewModel,
                syncProtectedPath: { _ in },
                makeLoginView: { Text("Login") },
                makeFlightListView: { _ in Text("Flights") },
                makeFlightDetailView: { flightID in Text("Detail \(flightID.value)") },
                makeBoardingPassView: { flightID in Text("Boarding \(flightID.value)") }
            )
        )

        #expect(data.count > 1_000)
    }

    @Test("Root view renders the authenticated route")
    func rendersAuthenticatedRoute() async throws {
        let bus = DefaultNavigationEventBus()
        let store = AppStateStore()
        let viewModel = AppViewModel(store: store)
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-root",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )

        viewModel.startObservingState()
        defer { viewModel.stopObservingState() }
        await store.apply(
            AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: [.primaryDetail(contextID: "IB3456")]
            )
        )

        for _ in 0..<20 where viewModel.rootRoute != .authenticatedHome {
            await Task.yield()
        }

        let data = try renderedPNG(
            from: RootView(
                appViewModel: viewModel,
                syncProtectedPath: { newPath in
                    await bus.publish(.syncProtectedPath(newPath))
                },
                makeLoginView: { Text("Login") },
                makeFlightListView: { activeSession in Text("Flights \(activeSession.passengerID.value)") },
                makeFlightDetailView: { flightID in Text("Detail \(flightID.value)") },
                makeBoardingPassView: { flightID in Text("Boarding \(flightID.value)") }
            )
        )

        #expect(viewModel.rootRoute == .authenticatedHome)
        #expect(data.count > 1_000)
    }
}
