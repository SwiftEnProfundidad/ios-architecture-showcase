import AuthFeature
import SharedKernel

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
