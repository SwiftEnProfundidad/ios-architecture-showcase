import Testing
@testable import Auth
@testable import SharedKernel
@testable import SharedNavigation

private typealias SUT = LoginUseCase<AuthGatewaySpy, SessionStoreSpy>

@Suite("LoginUseCase")
struct LoginUseCaseTests {

    @Test("Dado credenciales válidas, cuando login, entonces devuelve pasajero y publica LoginSuccess")
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

    @Test("Dado credenciales inválidas, cuando login, entonces lanza AuthError.invalidCredentials")
    func loginWithInvalidCredentialsThrows() async {
        let (sut, gateway, _) = makeSUT()
        await gateway.stub(result: .failure(.invalidCredentials))

        await #expect(throws: AuthError.invalidCredentials) {
            try await sut.execute(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Dado email con formato inválido, cuando login, entonces lanza AuthError.invalidEmailFormat sin llamar al gateway")
    func loginWithInvalidEmailFormatThrowsWithoutCallingGateway() async throws {
        let (sut, gateway, _) = makeSUT()

        await #expect(throws: AuthError.invalidEmailFormat) {
            try await sut.execute(email: "no-es-email", password: "Secure123!")
        }

        let callCount = await gateway.executeCallCount
        #expect(callCount == 0)
    }

    @Test("Dado login exitoso, el token queda almacenado en el SessionStore")
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
