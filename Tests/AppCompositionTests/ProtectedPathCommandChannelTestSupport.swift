import AppComposition
import SharedNavigation
import Testing

@MainActor
func makeProtectedPathCommandChannelSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<ProtectedPathCommandChannelTestContext> {
    let spy = ProtectedPathPublishSpy()
    let sut = ProtectedPathCommandChannel { path in
        await spy.publish(path)
    }
    return makeLeakTrackedTestContext(
        ProtectedPathCommandChannelTestContext(
            sut: sut,
            spy: spy
        ),
        trackedInstances: spy,
        sourceLocation: sourceLocation
    )
}

struct ProtectedPathCommandChannelTestContext {
    let sut: ProtectedPathCommandChannel
    let spy: ProtectedPathPublishSpy
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
