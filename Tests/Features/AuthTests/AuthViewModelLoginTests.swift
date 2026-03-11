import AuthFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("AuthViewModel login")
struct AuthViewModelLoginTests {

    @Test("Successful login publishes SessionStarted from presentation")
    func successfulLoginPublishesSessionStarted() async {
        let session = makeAuthSession()
        let tracked = makeAuthViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.loginUseCase.stub(result: .success(session))
        context.sut.email = "carlos@iberia.com"
        context.sut.password = "Secure123!"

        await context.sut.login()

        let publishedEvent = await context.eventBus.lastPublishedEvent
        #expect(
            publishedEvent == .sessionStarted(
                AppSession(
                    passengerID: session.passengerID,
                    token: session.token,
                    expiresAt: session.expiresAt
                )
            )
        )
        #expect(context.sut.errorMessage == nil)
    }

    @Test("Invalid credentials publish SessionStartRejected and expose localized error")
    func invalidCredentialsPublishFailure() async {
        let tracked = makeAuthViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.loginUseCase.stub(result: .failure(AuthError.invalidCredentials))
        context.sut.email = "carlos@iberia.com"
        context.sut.password = "wrong"

        await context.sut.login()

        let publishedEvent = await context.eventBus.lastPublishedEvent
        #expect(publishedEvent == .sessionStartRejected)
        #expect(context.sut.errorMessage == AppStrings.localized("auth.error.invalidCredentials"))
    }

    @Test("Quick access uses configured evaluation credentials without manual typing")
    func quickAccessUsesConfiguredEvaluationCredentials() async {
        let session = makeAuthSession(token: "tok-quick", hour: 13, minute: 30)
        let tracked = makeAuthViewModelSUT(
            quickAccessEmail: "carlos@iberia.com",
            quickAccessPassword: "Secure123!"
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.loginUseCase.stub(result: .success(session))

        await context.sut.loginWithQuickAccess()

        let publishedEvent = await context.eventBus.lastPublishedEvent
        let recordedEmail = await context.loginUseCase.lastEmail
        let recordedPassword = await context.loginUseCase.lastPassword
        #expect(context.sut.hasQuickAccess)
        #expect(context.sut.email == "carlos@iberia.com")
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
}
