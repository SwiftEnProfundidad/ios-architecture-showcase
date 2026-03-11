import AuthFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("AuthViewModel")
struct AuthViewModelTests {

    @Test("Successful login publishes SessionStarted from presentation")
    func successfulLoginPublishesSessionStarted() async {
        let eventBus = NavigationEventBusSpy()
        let loginUseCase = LoginUseCaseSpy()
        let session = AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-abc",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )
        await loginUseCase.stub(result: .success(session))
        let sut = AuthViewModel(loginUseCase: loginUseCase, eventBus: eventBus)
        sut.email = "carlos@iberia.com"
        sut.password = "Secure123!"

        await sut.login()

        let publishedEvent = await eventBus.lastPublishedEvent
        #expect(
            publishedEvent == .sessionStarted(
                AppSession(
                    passengerID: session.passengerID,
                    token: session.token,
                    expiresAt: session.expiresAt
                )
            )
        )
        #expect(sut.errorMessage == nil)
    }

    @Test("Invalid credentials publish SessionStartRejected and expose localized error")
    func invalidCredentialsPublishFailure() async {
        let eventBus = NavigationEventBusSpy()
        let loginUseCase = LoginUseCaseSpy()
        await loginUseCase.stub(result: .failure(AuthError.invalidCredentials))
        let sut = AuthViewModel(loginUseCase: loginUseCase, eventBus: eventBus)
        sut.email = "carlos@iberia.com"
        sut.password = "wrong"

        await sut.login()

        let publishedEvent = await eventBus.lastPublishedEvent
        #expect(publishedEvent == .sessionStartRejected)
        #expect(sut.errorMessage == AppStrings.localized("auth.error.invalidCredentials"))
    }

    @Test("Quick access uses configured evaluation credentials without manual typing")
    func quickAccessUsesConfiguredEvaluationCredentials() async {
        let eventBus = NavigationEventBusSpy()
        let loginUseCase = LoginUseCaseSpy()
        let session = AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-quick",
            expiresAt: fixedDate(hour: 13, minute: 30)
        )
        await loginUseCase.stub(result: .success(session))
        let sut = AuthViewModel(
            loginUseCase: loginUseCase,
            eventBus: eventBus,
            quickAccessEmail: "carlos@iberia.com",
            quickAccessPassword: "Secure123!"
        )

        await sut.loginWithQuickAccess()

        let publishedEvent = await eventBus.lastPublishedEvent
        let recordedEmail = await loginUseCase.lastEmail
        let recordedPassword = await loginUseCase.lastPassword
        #expect(sut.hasQuickAccess)
        #expect(sut.email == "carlos@iberia.com")
        #expect(recordedEmail == "carlos@iberia.com")
        #expect(recordedPassword == "Secure123!")
        #expect(
            publishedEvent == .sessionStarted(
                AppSession(
                    passengerID: session.passengerID,
                    token: session.token,
                    expiresAt: session.expiresAt
                )
            )
        )
    }

    @Test("Manual login normalizes the email before executing the authentication use case")
    func loginNormalizesEmailBeforeExecutingUseCase() async {
        let eventBus = NavigationEventBusSpy()
        let loginUseCase = LoginUseCaseSpy()
        let session = AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-normalized",
            expiresAt: fixedDate(hour: 15, minute: 0)
        )
        await loginUseCase.stub(result: .success(session))
        let sut = AuthViewModel(loginUseCase: loginUseCase, eventBus: eventBus)
        sut.email = "  Carlos@Iberia.com "
        sut.password = "Secure123!"

        await sut.login()

        #expect(sut.email == "carlos@iberia.com")
        #expect(await loginUseCase.lastEmail == "carlos@iberia.com")
    }
}

private actor LoginUseCaseSpy: LoginExecuting {
    private var result: Result<AuthSession, Error> = .failure(AuthError.network)
    private(set) var lastEmail: String?
    private(set) var lastPassword: String?

    func stub(result: Result<AuthSession, Error>) {
        self.result = result
    }

    func execute(email: String, password: String) async throws -> AuthSession {
        lastEmail = email
        lastPassword = password
        return try result.get()
    }
}
