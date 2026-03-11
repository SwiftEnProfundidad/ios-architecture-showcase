import SharedKernel

public protocol AuthGatewayProtocol: Sendable {
    func authenticate(email: String, password: String) async throws -> AuthSession
}
