import AuthFeature
import Testing

typealias LogoutUseCaseSUT = LogoutUseCase<SessionClearingSpy>

func makeLogoutUseCaseSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<LogoutUseCaseTestContext> {
    let sessionStore = SessionClearingSpy()
    let sut = LogoutUseCaseSUT(sessionStore: sessionStore)
    return makeLeakTrackedTestContext(
        LogoutUseCaseTestContext(
            sut: sut,
            sessionStore: sessionStore
        ),
        trackedInstances: sessionStore,
        sourceLocation: sourceLocation
    )
}

struct LogoutUseCaseTestContext {
    let sut: LogoutUseCaseSUT
    let sessionStore: SessionClearingSpy
}

actor SessionClearingSpy: SessionClearing {
    private(set) var clearCallCount = 0

    func clear() async {
        clearCallCount += 1
    }

    func recordedClearCallCount() -> Int {
        clearCallCount
    }
}
