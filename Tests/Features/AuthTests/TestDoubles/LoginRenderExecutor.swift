import AuthFeature
import SharedKernel

actor LoginRenderExecutor: LoginExecuting {
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
