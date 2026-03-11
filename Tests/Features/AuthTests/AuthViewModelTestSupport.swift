import AuthFeature
import SharedKernel
import SharedNavigation
import Testing

typealias AuthViewModelSUT = AuthViewModel<AuthViewModelLoginUseCaseSpy>

@MainActor
struct AuthViewModelTestContext {
    let sut: AuthViewModelSUT
    let loginUseCase: AuthViewModelLoginUseCaseSpy
    let eventBus: NavigationEventBusSpy
}

@MainActor
func makeAuthViewModelSUT(
    quickAccessEmail: String? = nil,
    quickAccessPassword: String? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<AuthViewModelTestContext> {
    let eventBus = NavigationEventBusSpy()
    let loginUseCase = AuthViewModelLoginUseCaseSpy()
    let sut = AuthViewModel(
        loginUseCase: loginUseCase,
        eventBus: eventBus,
        quickAccessEmail: quickAccessEmail,
        quickAccessPassword: quickAccessPassword
    )
    return makeLeakTrackedTestContext(
        AuthViewModelTestContext(
            sut: sut,
            loginUseCase: loginUseCase,
            eventBus: eventBus
        ),
        trackedInstances: [eventBus, loginUseCase, sut],
        sourceLocation: sourceLocation
    )
}

actor AuthViewModelLoginUseCaseSpy: LoginExecuting {
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
