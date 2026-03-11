import AppComposition
import SharedKernel
import SharedNavigation
import SwiftUI
import Testing

@MainActor
@Suite("RootViewRender")
struct RootViewRenderTests {
    @Test("Root view renders the login route")
    func rendersLoginRoute() throws {
        let tracked = makeRootViewRenderingSUT()
        defer { tracked.assertNoLeaks() }
        let viewModel = tracked.context.viewModel

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
        let tracked = makeObservedRootNavigationSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-root",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )

        context.viewModel.startObservingState()
        defer { context.viewModel.stopObservingState() }
        await context.store.apply(
            AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: [.primaryDetail(contextID: "IB3456")]
            )
        )

        for _ in 0..<20 where context.viewModel.rootRoute != .authenticatedHome {
            await Task.yield()
        }

        let data = try renderedPNG(
            from: RootView(
                appViewModel: context.viewModel,
                syncProtectedPath: { newPath in
                    await context.bus.publish(.syncProtectedPath(newPath))
                },
                makeLoginView: { Text("Login") },
                makeFlightListView: { activeSession in Text("Flights \(activeSession.passengerID.value)") },
                makeFlightDetailView: { flightID in Text("Detail \(flightID.value)") },
                makeBoardingPassView: { flightID in Text("Boarding \(flightID.value)") }
            )
        )

        #expect(context.viewModel.rootRoute == .authenticatedHome)
        #expect(data.count > 1_000)
    }
}
