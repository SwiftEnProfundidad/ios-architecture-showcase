
public struct LoginUseCase<Gateway: AuthGatewayProtocol, Store: SessionStoreProtocol>: Sendable {
    private let gateway: Gateway
    private let sessionStore: Store
    private let eventBus: NavigationEventPublishing

    public init(gateway: Gateway, sessionStore: Store, eventBus: NavigationEventPublishing) {
        self.gateway = gateway
        self.sessionStore = sessionStore
        self.eventBus = eventBus
    }

    public func execute(email: String, password: String) async throws -> AuthSession {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmailFormat
        }
        let session = try await gateway.authenticate(email: email, password: password)
        await sessionStore.save(token: session.token)
        await eventBus.publish(.loginSuccess(passengerID: session.passengerID, token: session.token))
        return session
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}
