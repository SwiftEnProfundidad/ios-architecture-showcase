import AuthFeature
import SharedKernel
import Testing

private typealias SUT = LogoutUseCase<SessionClearingSpy>

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("When logout, the session is removed from the SessionStore")
    func logoutClearsSession() async {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.sut.execute()

        let clearCallCount = await context.sessionStore.recordedClearCallCount()
        #expect(clearCallCount == 1)
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> TrackedTestContext<LogoutUseCaseTestContext> {
        let sessionStore = SessionClearingSpy()
        let sut = SUT(sessionStore: sessionStore)
        return makeLeakTrackedTestContext(
            LogoutUseCaseTestContext(
                sut: sut,
                sessionStore: sessionStore
            ),
            trackedInstances: sessionStore,
            sourceLocation: sourceLocation
        )
    }
}

private struct LogoutUseCaseTestContext {
    let sut: SUT
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
