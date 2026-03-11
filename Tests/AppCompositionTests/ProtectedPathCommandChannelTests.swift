import AppComposition
import SharedNavigation
import Testing

@MainActor
@Suite("ProtectedPathCommandChannel")
struct ProtectedPathCommandChannelTests {
    @Test("Publishes the visible path when it differs from projected state")
    func publishesVisiblePathWhenItDiffersFromProjectedState() async {
        let tracked = makeProtectedPathCommandChannelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let visiblePath = [AppRoute.primaryDetail(contextID: "IB3456")]

        await context.sut.synchronize(
            visiblePath: visiblePath,
            projectedPath: []
        )

        #expect(await context.spy.recordedPaths() == [visiblePath])
    }

    @Test("Skips publishing when the visible path already matches projected state")
    func skipsPublishingWhenVisiblePathMatchesProjectedState() async {
        let tracked = makeProtectedPathCommandChannelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let visiblePath = [AppRoute.primaryDetail(contextID: "IB3456")]

        await context.sut.synchronize(
            visiblePath: visiblePath,
            projectedPath: visiblePath
        )

        #expect(await context.spy.recordedPaths().isEmpty)
    }
}
