import AuthFeature
import SharedKernel
import Testing

@MainActor
@Suite("LoginViewRender")
struct LoginViewRenderTests {
    @Test("Login screen renders the default state")
    func rendersDefaultState() throws {
        let viewModel = AuthViewModel(
            loginUseCase: LoginRenderExecutor(mode: .success(sampleSession)),
            eventBus: NavigationEventBusSpy()
        )

        let data = try renderedPNG(from: LoginView(viewModel: viewModel))

        #expect(data.count > 1_000)
    }

    @Test("Login screen renders quick access and error feedback")
    func rendersQuickAccessAndErrorState() async throws {
        let viewModel = AuthViewModel(
            loginUseCase: LoginRenderExecutor(mode: .invalidCredentials),
            eventBus: NavigationEventBusSpy(),
            quickAccessEmail: ShowcaseLoginFixtures.email,
            quickAccessPassword: ShowcaseLoginFixtures.password
        )

        await viewModel.login()
        let data = try renderedPNG(
            from: LoginView(viewModel: viewModel),
            colorScheme: .dark
        )

        #expect(viewModel.errorMessage == AppStrings.localized("auth.error.invalidCredentials"))
        #expect(data.count > 1_000)
    }

    @Test("Login screen renders the loading state while authentication is suspended")
    func rendersLoadingState() async throws {
        let executor = LoginRenderExecutor(mode: .suspended(sampleSession))
        let viewModel = AuthViewModel(
            loginUseCase: executor,
            eventBus: NavigationEventBusSpy()
        )

        let task = Task {
            await viewModel.login()
        }
        await Task.yield()

        let data = try renderedPNG(from: LoginView(viewModel: viewModel))

        #expect(viewModel.isLoading)
        #expect(data.count > 1_000)

        await executor.resume()
        await task.value
    }

    private var sampleSession: AuthSession {
        AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-login-render",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )
    }
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
