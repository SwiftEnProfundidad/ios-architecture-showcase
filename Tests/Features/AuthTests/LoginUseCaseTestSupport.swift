import AuthFeature
import SharedKernel
import Testing

typealias LoginUseCaseSUT = LoginUseCase<AuthGatewaySpy, SessionPersistingSpy>

struct LoginUseCaseTestContext {
    let sut: LoginUseCaseSUT
    let gateway: AuthGatewaySpy
    let sessionStore: SessionPersistingSpy
}

func makeLoginUseCaseSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<LoginUseCaseTestContext> {
    let gateway = AuthGatewaySpy()
    let sessionStore = SessionPersistingSpy()
    let sut = LoginUseCaseSUT(gateway: gateway, sessionStore: sessionStore)
    return makeLeakTrackedTestContext(
        LoginUseCaseTestContext(
            sut: sut,
            gateway: gateway,
            sessionStore: sessionStore
        ),
        trackedInstances: [gateway, sessionStore],
        sourceLocation: sourceLocation
    )
}

actor SessionPersistingSpy: SessionPersisting {
    private var session: AuthSession?
    private var saveError: Error?

    func stubSaveError(_ error: Error) {
        saveError = error
    }

    func save(session: AuthSession) async throws {
        if let saveError {
            throw saveError
        }
        self.session = session
    }

    func persistedSession() -> AuthSession? {
        session
    }
}
