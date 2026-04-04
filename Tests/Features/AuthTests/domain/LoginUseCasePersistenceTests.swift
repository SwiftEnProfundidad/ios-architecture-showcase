import AuthFeature
import SharedKernel
import Testing

@Suite("LoginUseCase persistence")
struct LoginUseCasePersistenceTests {

    @Test("Given successful authentication, when login completes, then the session is stored in the SessionStore")
    func loginStoresSessionInSessionStore() async throws {
        let tracked = makeLoginUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")
        let expectedSession = makeAuthSession(passengerID: passengerID)
        await context.gateway.stub(
            result: Result<AuthSession, AuthError>.success(
                expectedSession
            )
        )

        _ = try await context.sut.execute(email: "carlos@iberia.com", password: "Secure123!")

        let storedSession = await context.sessionStore.persistedSession()
        #expect(storedSession?.token == "tok-abc")
        #expect(storedSession?.expiresAt == expectedSession.expiresAt)
    }

    @Test("Given session persistence fails after authentication, when login runs, then throws and does not keep an authenticated session")
    func loginFailsWhenSessionPersistenceFails() async {
        let tracked = makeLoginUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.gateway.stub(
            result: Result<AuthSession, AuthError>.success(
                makeAuthSession()
            )
        )
        await context.sessionStore.stubSaveError(AuthError.storage)

        await #expect(throws: AuthError.storage) {
            try await context.sut.execute(email: "carlos@iberia.com", password: "Secure123!")
        }

        let storedSession = await context.sessionStore.persistedSession()
        #expect(storedSession == nil)
    }
}
