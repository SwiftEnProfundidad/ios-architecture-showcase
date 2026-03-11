import AppComposition
import SharedKernel
import SharedNavigation
import SwiftUI
import Testing

@MainActor
@Suite("CompositionRootSmoke")
struct CompositionRootSmokeTests {
    @Test("Composition root starts idempotently and renders all entry points")
    func startsAndRendersAllEntrypoints() async throws {
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-composition",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )
        let tracked = makeCompositionRootSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.root.start()
        await context.root.start()

        let loginData = try renderedPNG(from: context.root.makeLoginView())
        let listData = try renderedPNG(from: context.root.makeFlightListView(session: session))
        let detailData = try renderedPNG(from: context.root.makeFlightDetailView(flightID: FlightID("IB3456")))
        let passData = try renderedPNG(from: context.root.makeBoardingPassView(flightID: FlightID("IB3456")))

        #expect(loginData.count > 1_000)
        #expect(listData.count > 1_000)
        #expect(detailData.count > 1_000)
        #expect(passData.count > 1_000)
    }

    private func makeCompositionRootSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> TrackedTestContext<CompositionRootSmokeContext> {
        let sut = CompositionRoot(evaluationCredentials: .default)
        return makeLeakTrackedTestContext(
            CompositionRootSmokeContext(root: sut),
            trackedInstances: sut,
            sourceLocation: sourceLocation
        )
    }
}

private struct CompositionRootSmokeContext {
    let root: CompositionRoot
}
