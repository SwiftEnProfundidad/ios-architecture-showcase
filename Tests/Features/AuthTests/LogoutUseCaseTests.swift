import Testing
@testable import Auth
@testable import SharedKernel
@testable import SharedNavigation

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("Cuando logout, el token se elimina del SessionStore y se publica Logout")
    func logoutClearsTokenAndPublishesEvent() async {
        let sessionStore = SessionStoreSpy()
        await sessionStore.save(token: "tok-abc")
        let bus = NavigationEventBusSpy()
        let sut = LogoutUseCase(sessionStore: sessionStore, eventBus: bus)

        await sut.execute()

        let storedToken = await sessionStore.currentToken()
        #expect(storedToken == nil)
        let publishedEvent = await bus.lastPublishedEvent
        #expect(publishedEvent == .logout)
    }
}
