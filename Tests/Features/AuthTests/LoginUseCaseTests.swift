import Testing
@testable import Auth
@testable import SharedKernel
@testable import SharedNavigation

private typealias SUT = LoginUseCase<AuthGatewaySpy, SessionStoreSpy>

@Suite("LoginUseCase")
struct LoginUseCaseTests {

    @Test("Given valid credentials, when login, then returns passenger and publishes LoginSuccess")
    func loginWithValidCredentialsPublishesLoginSuccess() async throws {
        let (sut, gateway, bus) = makeSUT()
        let passengerID = PassengerID("PAX-001")
        await gateway.stub(result: .success(AuthSession(passengerID: passengerID, token: "tok-abc")))

        let session = try await sut.execute(email: "carlos@iberia.com", password: "Secure123!")

        #expect(session.passengerID == passengerID)
        #expect(session.token == "tok-abc")
        let publishedEvent = await bus.lastPublishedEvent
        #expect(publishedEvent == .loginSuccess(passengerID: passengerID, token: "tok-abc"))
    }

    @Test("Given invalid credentials, when login, then throws AuthError.invalidCredentials")
    func loginWithInvalidCredentialsThrows() async {
        let (sut, gateway, _) = makeSUT()
        await gateway.stub(result: .failure(.invalidCredentials))

        await #expect(throws: AuthError.invalidCredentials) {
            try await sut.execute(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Given invalid email format, when login, then throws AuthError.invalidEmailFormat without calling the gateway")
    func loginWithInvalidEmailFormatThrowsWithoutCallingGateway() async throws {
        let (sut, gateway, _) = makeSUT()

        await #expect(throws: AuthError.invalidEmailFormat) {
            try await sut.execute(email: "no-es-email", password: "Secure123!")
        }

        let callCount = await gateway.executeCallCount
        #expect(callCount == 0)
    }

    @Test("Given successful login, the token is stored in the SessionStore")
    func loginStoresTokenInSessionStore() async throws {
        let (sut, gateway, _, sessionStore) = makeSUTWithStore()
        let passengerID = PassengerID("PAX-001")
        await gateway.stub(result: .success(AuthSession(passengerID: passengerID, token: "tok-abc")))

        _ = try await sut.execute(email: "carlos@iberia.com", password: "Secure123!")

        let storedToken = await sessionStore.currentToken()
        #expect(storedToken == "tok-abc")
    }

    private func makeSUT() -> (SUT, AuthGatewaySpy, NavigationEventBusSpy) {
        let gateway = AuthGatewaySpy()
        let bus = NavigationEventBusSpy()
        let sessionStore = SessionStoreSpy()
        let sut = SUT(gateway: gateway, sessionStore: sessionStore, eventBus: bus)
        return (sut, gateway, bus)
    }

    private func makeSUTWithStore() -> (SUT, AuthGatewaySpy, NavigationEventBusSpy, SessionStoreSpy) {
        let gateway = AuthGatewaySpy()
        let bus = NavigationEventBusSpy()
        let sessionStore = SessionStoreSpy()
        let sut = SUT(gateway: gateway, sessionStore: sessionStore, eventBus: bus)
        return (sut, gateway, bus, sessionStore)
    }
}
