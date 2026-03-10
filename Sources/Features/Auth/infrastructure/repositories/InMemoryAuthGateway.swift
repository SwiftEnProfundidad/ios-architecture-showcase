import Foundation

public struct InMemoryAuthGateway: AuthGatewayProtocol {
    private let validEmail = "carlos@iberia.com"
    private let validPassword = "Secure123!"

    public init() {}

    public func authenticate(email: String, password: String) async throws -> AuthSession {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard email == validEmail, password == validPassword else {
            throw AuthError.invalidCredentials
        }
        return AuthSession(passengerID: PassengerID("PAX-001"), token: "demo-token-\(UUID().uuidString.prefix(8))")
    }
}
