import AuthFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
func makeLoginViewRenderSUT(
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

func makeLoginViewRenderSession() -> AuthSession {
    AuthSession(
        passengerID: PassengerID("PAX-001"),
        token: "tok-login-render",
        expiresAt: fixedDate(hour: 12, minute: 0)
    )
}

struct LoginViewRenderTestContext {
    let viewModel: AuthViewModel<LoginRenderExecutor>
    let executor: LoginRenderExecutor
    let eventBus: NavigationEventBusSpy
}

enum ShowcaseLoginFixtures {
    static let email = "carlos@iberia.com"
    static let password = "showcase-password"
}
