import AppComposition
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("ProtectedPathCommandChannel")
struct ProtectedPathCommandChannelTests {
    @Test("Given the visible path differs from projected state, when synchronized, then a publish occurs")
    func publishesVisiblePathWhenItDiffersFromProjectedState() async {
        let tracked = makeProtectedPathCommandChannelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let visiblePath = [AppRoute.primaryDetail(contextID: FlightID("IB3456"))]

        await context.sut.synchronize(
            visiblePath: visiblePath,
            projectedPath: []
        )

        #expect(await context.spy.recordedPaths() == [visiblePath])
    }

    @Test("Given the visible path matches projected state, when synchronized, then nothing is published")
    func skipsPublishingWhenVisiblePathMatchesProjectedState() async {
        let tracked = makeProtectedPathCommandChannelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let visiblePath = [AppRoute.primaryDetail(contextID: FlightID("IB3456"))]

        await context.sut.synchronize(
            visiblePath: visiblePath,
            projectedPath: visiblePath
        )

        #expect(await context.spy.recordedPaths().isEmpty)
    }
}
