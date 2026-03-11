import AuthFeature
import SharedKernel
import Testing

private typealias SUT = LogoutUseCase<SessionClearingSpy>

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("When logout, the session is removed from the SessionStore")
    func logoutClearsSession() async {
        let (token, sut, sessionStore) = makeSUT()
        await sut.execute()

        let clearCallCount = await sessionStore.recordedClearCallCount()
        #expect(clearCallCount == 1)
        _ = token
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, SUT, SessionClearingSpy) {
        let token = MemoryLeakToken()
        let sessionStore = SessionClearingSpy()
        let sut = SUT(sessionStore: sessionStore)
        trackForMemoryLeaks(sessionStore, token: token, sourceLocation: sourceLocation)
        return (token, sut, sessionStore)
    }
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
