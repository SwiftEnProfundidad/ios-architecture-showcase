import AuthFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("AuthViewModel input")
struct AuthViewModelInputTests {

    @Test("Visible email input normalizes the typed address for the login field")
    func normalizeVisibleEmailInputUpdatesTheFieldState() {
        let tracked = makeAuthViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        context.sut.email = "  Carlos@Iberia.com "

        context.sut.normalizeVisibleEmailInput()

        #expect(context.sut.email == "carlos@iberia.com")
    }

    @Test("Manual login normalizes the email before executing the authentication use case")
    func loginNormalizesEmailBeforeExecutingUseCase() async {
        let session = makeAuthSession(token: "tok-normalized", hour: 15, minute: 0)
        let tracked = makeAuthViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.loginUseCase.stub(result: .success(session))
        context.sut.email = "  Carlos@Iberia.com "
        context.sut.password = "Secure123!"

        await context.sut.login()

        #expect(context.sut.email == "carlos@iberia.com")
        #expect(await context.loginUseCase.lastEmail == "carlos@iberia.com")
    }
}
