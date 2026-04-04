import AuthFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("AuthViewModel input")
struct AuthViewModelInputTests {

    @Test("Given visible email input, when the user types, then the login field receives a normalized address")
    func normalizeVisibleEmailInputUpdatesTheFieldState() {
        let tracked = makeAuthViewModelSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        context.sut.email = "  Carlos@Iberia.com "

        context.sut.normalizeVisibleEmailInput()

        #expect(context.sut.email == "carlos@iberia.com")
    }

    @Test("Given manual login with a typed email, when login is executed, then the email is normalized before the use case runs")
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
