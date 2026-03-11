import Foundation
import SharedKernel

public struct RemoteAuthGateway<Client: HTTPClient>: AuthGatewayProtocol {
    private let client: Client
    private let baseURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(client: Client, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func authenticate(email: String, password: String) async throws -> AuthSession {
        let endpoint = baseURL.appending(path: "v1").appending(path: "auth").appending(path: "login")
        let body = LoginRequestBody(email: email, password: password)
        let request = HTTPRequest(
            url: endpoint,
            method: .post,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ],
            body: try? encoder.encode(body)
        )

        let response: HTTPResponse
        do {
            response = try await client.execute(request)
        } catch is HTTPClientError {
            throw AuthError.network
        } catch {
            throw AuthError.network
        }

        switch response.statusCode {
        case 200:
            guard let sessionResponse = try? decoder.decode(LoginResponseBody.self, from: response.data) else {
                throw AuthError.network
            }
            return AuthSession(
                passengerID: PassengerID(sessionResponse.passengerID),
                token: sessionResponse.token,
                expiresAt: sessionResponse.expiresAt
            )
        case 401:
            return try invalidCredentials()
        default:
            throw AuthError.network
        }
    }

    private func invalidCredentials() throws -> AuthSession {
        throw AuthError.invalidCredentials
    }
}

private struct LoginRequestBody: Codable {
    let email: String
    let password: String
}

private struct LoginResponseBody: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}
