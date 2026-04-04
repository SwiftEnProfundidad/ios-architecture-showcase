import AuthFeature
import SharedKernel
import Testing

@Suite("LoginUseCase execution")
struct LoginUseCaseExecutionTests {

    @Test("Given valid credentials, when login runs, then returns passenger data")
    func loginWithValidCredentialsReturnsSession() async throws {
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

        let session = try await context.sut.execute(email: "carlos@iberia.com", password: "Secure123!")

        #expect(session.passengerID == passengerID)
        #expect(session.token == "tok-abc")
        #expect(session.expiresAt == expectedSession.expiresAt)
    }

    @Test("Given invalid credentials, when login runs, then throws AuthError.invalidCredentials")
    func loginWithInvalidCredentialsThrows() async {
        let tracked = makeLoginUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.gateway.stub(result: Result<AuthSession, AuthError>.failure(.invalidCredentials))

        await #expect(throws: AuthError.invalidCredentials) {
            try await context.sut.execute(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Given invalid email format, when login, then throws AuthError.invalidEmailFormat without calling the gateway")
    func loginWithInvalidEmailFormatThrowsWithoutCallingGateway() async {
        let tracked = makeLoginUseCaseSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await #expect(throws: AuthError.invalidEmailFormat) {
            try await context.sut.execute(email: "not-an-email", password: "Secure123!")
        }

        let callCount = await context.gateway.executeCallCount
        #expect(callCount == 0)
    }
}
