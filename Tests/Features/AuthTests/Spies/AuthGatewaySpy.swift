@testable import iOSArchitectureShowcase

actor AuthGatewaySpy: AuthGatewayProtocol {
    private var stubbedResult: Result<AuthSession, AuthError> = .failure(.invalidCredentials)
    private(set) var executeCallCount = 0

    func stub(result: Result<AuthSession, AuthError>) {
        stubbedResult = result
    }

    func authenticate(email: String, password: String) async throws -> AuthSession {
        executeCallCount += 1
        switch stubbedResult {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }
}
