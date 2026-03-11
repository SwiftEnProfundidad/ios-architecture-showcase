import AuthFeature
import Testing

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("When logout, the session is removed from the SessionStore")
    func logoutClearsSession() async {
        let tracked = makeLogoutUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.sut.execute()

        let clearCallCount = await context.sessionStore.recordedClearCallCount()
        #expect(clearCallCount == 1)
    }
}
