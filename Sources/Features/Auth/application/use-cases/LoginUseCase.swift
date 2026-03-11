public protocol LoginExecuting: Sendable {
    func execute(email: String, password: String) async throws -> AuthSession
}

public struct LoginUseCase<Gateway: AuthGatewayProtocol, Store: SessionPersisting>: Sendable {
    private let gateway: Gateway
    private let sessionStore: Store

    public init(gateway: Gateway, sessionStore: Store) {
        self.gateway = gateway
        self.sessionStore = sessionStore
    }

    public func execute(email: String, password: String) async throws -> AuthSession {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmailFormat
        }
        let session = try await gateway.authenticate(email: email, password: password)
        try await sessionStore.save(session: session)
        return session
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}

extension LoginUseCase: LoginExecuting {}
