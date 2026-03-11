@testable import AppComposition
import SharedNavigation
import Testing

@Suite("ProtectedPathCommandChannel")
struct ProtectedPathCommandChannelTests {
    @Test("Publishes the visible path when it differs from projected state")
    func publishesVisiblePathWhenItDiffersFromProjectedState() async {
        let spy = ProtectedPathPublishSpy()
        let sut = ProtectedPathCommandChannel { path in
            await spy.publish(path)
        }
        let visiblePath = [AppRoute.primaryDetail(contextID: "IB3456")]

        await sut.synchronize(
            visiblePath: visiblePath,
            projectedPath: []
        )

        #expect(await spy.recordedPaths() == [visiblePath])
    }

    @Test("Skips publishing when the visible path already matches projected state")
    func skipsPublishingWhenVisiblePathMatchesProjectedState() async {
        let spy = ProtectedPathPublishSpy()
        let sut = ProtectedPathCommandChannel { path in
            await spy.publish(path)
        }
        let visiblePath = [AppRoute.primaryDetail(contextID: "IB3456")]

        await sut.synchronize(
            visiblePath: visiblePath,
            projectedPath: visiblePath
        )

        #expect(await spy.recordedPaths().isEmpty)
    }
}

actor ProtectedPathPublishSpy {
    private var publishedPaths: [[AppRoute]] = []

    func publish(_ path: [AppRoute]) {
        publishedPaths.append(path)
    }

    func recordedPaths() -> [[AppRoute]] {
        publishedPaths
    }
}
