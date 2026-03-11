import AuthFeature
import SharedKernel
import Testing

@MainActor
@Suite("LoginViewRender")
struct LoginViewRenderTests {
    @Test("Login screen renders the default state")
    func rendersDefaultState() throws {
        let tracked = makeSUT(mode: .success(sampleSession))
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let data = try renderedPNG(from: LoginView(viewModel: context.viewModel))

        #expect(data.count > 1_000)
    }

    @Test("Login screen renders quick access and error feedback")
    func rendersQuickAccessAndErrorState() async throws {
        let tracked = makeSUT(
            mode: .invalidCredentials,
            quickAccessEmail: ShowcaseLoginFixtures.email,
            quickAccessPassword: ShowcaseLoginFixtures.password
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.login()
        let data = try renderedPNG(
            from: LoginView(viewModel: context.viewModel),
            colorScheme: .dark
        )

        #expect(context.viewModel.errorMessage == AppStrings.localized("auth.error.invalidCredentials"))
        #expect(data.count > 1_000)
    }

    @Test("Login screen renders the loading state while authentication is suspended")
    func rendersLoadingState() async throws {
        let tracked = makeSUT(mode: .suspended(sampleSession))
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let task = Task {
            await context.viewModel.login()
        }
        await Task.yield()

        let data = try renderedPNG(from: LoginView(viewModel: context.viewModel))

        #expect(context.viewModel.isLoading)
        #expect(data.count > 1_000)

        await context.executor.resume()
        await task.value
    }

    private var sampleSession: AuthSession {
        AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-login-render",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )
    }

    private func makeSUT(
        mode: LoginRenderExecutor.Mode,
        quickAccessEmail: String? = nil,
        quickAccessPassword: String? = nil
    ) -> TrackedTestContext<LoginViewRenderTestContext> {
        let executor = LoginRenderExecutor(mode: mode)
        let eventBus = NavigationEventBusSpy()
        let sut = AuthViewModel(
            loginUseCase: executor,
            eventBus: eventBus,
            quickAccessEmail: quickAccessEmail,
            quickAccessPassword: quickAccessPassword
        )
        return makeTestContext(
            LoginViewRenderTestContext(viewModel: sut, executor: executor, eventBus: eventBus)
        )
    }
}

private struct LoginViewRenderTestContext {
    let viewModel: AuthViewModel<LoginRenderExecutor>
    let executor: LoginRenderExecutor
    let eventBus: NavigationEventBusSpy
}

private actor LoginRenderExecutor: LoginExecuting {
    enum Mode {
        case success(AuthSession)
        case invalidCredentials
        case suspended(AuthSession)
    }

    private let mode: Mode
    private var continuation: CheckedContinuation<AuthSession, Error>?

    init(mode: Mode) {
        self.mode = mode
    }

    func execute(email: String, password: String) async throws -> AuthSession {
        switch mode {
        case .success(let session):
            return session
        case .invalidCredentials:
            throw AuthError.invalidCredentials
        case .suspended:
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
    }

    func resume() {
        guard case .suspended(let session) = mode else {
            return
        }
        continuation?.resume(returning: session)
        continuation = nil
    }
}

private enum ShowcaseLoginFixtures {
    static let email = "carlos@iberia.com"
    static let password = "showcase-password"
}
