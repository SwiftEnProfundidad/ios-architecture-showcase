import AuthFeature
import SharedKernel
import Testing

private typealias SUT = LoginUseCase<AuthGatewaySpy, SessionPersistingSpy>

@Suite("LoginUseCase")
struct LoginUseCaseTests {

    @Test("Given valid credentials, when login, then returns passenger data")
    func loginWithValidCredentialsReturnsSession() async throws {
        let (token, sut, gateway) = makeSUT()
        let passengerID = PassengerID("PAX-001")
        let expiresAt = fixedDate(hour: 12, minute: 0)
        await gateway.stub(
            result: Result<AuthSession, AuthError>.success(
                AuthSession(
                    passengerID: passengerID,
                    token: "tok-abc",
                    expiresAt: expiresAt
                )
            )
        )

        let session = try await sut.execute(email: "carlos@iberia.com", password: "Secure123!")

        #expect(session.passengerID == passengerID)
        #expect(session.token == "tok-abc")
        #expect(session.expiresAt == expiresAt)
        _ = token
    }

    @Test("Given invalid credentials, when login, then throws AuthError.invalidCredentials")
    func loginWithInvalidCredentialsThrows() async {
        let (token, sut, gateway) = makeSUT()
        await gateway.stub(result: Result<AuthSession, AuthError>.failure(.invalidCredentials))

        await #expect(throws: AuthError.invalidCredentials) {
            try await sut.execute(email: "carlos@iberia.com", password: "wrong")
        }
        _ = token
    }

    @Test("Given invalid email format, when login, then throws AuthError.invalidEmailFormat without calling the gateway")
    func loginWithInvalidEmailFormatThrowsWithoutCallingGateway() async {
        let (token, sut, gateway) = makeSUT()

        await #expect(throws: AuthError.invalidEmailFormat) {
            try await sut.execute(email: "not-an-email", password: "Secure123!")
        }

        let callCount = await gateway.executeCallCount
        #expect(callCount == 0)
        _ = token
    }

    @Test("Given successful login, the session is stored in the SessionStore")
    func loginStoresSessionInSessionStore() async throws {
        let (token, sut, gateway, sessionStore) = makeSUTWithStore()
        let passengerID = PassengerID("PAX-001")
        let expiresAt = fixedDate(hour: 12, minute: 0)
        await gateway.stub(
            result: Result<AuthSession, AuthError>.success(
                AuthSession(
                    passengerID: passengerID,
                    token: "tok-abc",
                    expiresAt: expiresAt
                )
            )
        )

        _ = try await sut.execute(email: "carlos@iberia.com", password: "Secure123!")

        let storedSession = await sessionStore.persistedSession()
        #expect(storedSession?.token == "tok-abc")
        #expect(storedSession?.expiresAt == expiresAt)
        _ = token
    }

    @Test("Given session persistence fails after authentication, when login, then throws and does not keep an authenticated session")
    func loginFailsWhenSessionPersistenceFails() async {
        let (token, sut, gateway, sessionStore) = makeSUTWithStore()
        await gateway.stub(
            result: Result<AuthSession, AuthError>.success(
                AuthSession(
                    passengerID: PassengerID("PAX-001"),
                    token: "tok-abc",
                    expiresAt: fixedDate(hour: 12, minute: 0)
                )
            )
        )
        await sessionStore.stubSaveError(AuthError.storage)

        await #expect(throws: AuthError.storage) {
            try await sut.execute(email: "carlos@iberia.com", password: "Secure123!")
        }

        let storedSession = await sessionStore.persistedSession()
        #expect(storedSession == nil)
        _ = token
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, SUT, AuthGatewaySpy) {
        let token = MemoryLeakToken()
        let gateway = AuthGatewaySpy()
        let sessionStore = SessionPersistingSpy()
        let sut = SUT(gateway: gateway, sessionStore: sessionStore)
        trackForMemoryLeaks(gateway, token: token, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sessionStore, token: token, sourceLocation: sourceLocation)
        return (token, sut, gateway)
    }

    private func makeSUTWithStore(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, SUT, AuthGatewaySpy, SessionPersistingSpy) {
        let token = MemoryLeakToken()
        let gateway = AuthGatewaySpy()
        let sessionStore = SessionPersistingSpy()
        let sut = SUT(gateway: gateway, sessionStore: sessionStore)
        trackForMemoryLeaks(gateway, token: token, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sessionStore, token: token, sourceLocation: sourceLocation)
        return (token, sut, gateway, sessionStore)
    }
}

actor SessionPersistingSpy: SessionPersisting {
    private var session: AuthSession?
    private var saveError: Error?

    func stubSaveError(_ error: Error) {
        saveError = error
    }

    func save(session: AuthSession) async throws {
        if let saveError {
            throw saveError
        }
        self.session = session
    }

    func persistedSession() -> AuthSession? {
        session
    }
}
