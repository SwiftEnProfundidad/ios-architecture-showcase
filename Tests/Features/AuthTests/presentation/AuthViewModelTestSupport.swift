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
