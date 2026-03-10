import Testing
@testable import iOSArchitectureShowcase

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("When logout, the token is removed from the SessionStore and Logout is published")
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
