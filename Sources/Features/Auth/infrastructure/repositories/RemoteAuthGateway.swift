import Foundation
import SharedKernel
import SharedNetworking

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
        let encodedBody: Data
        do {
            encodedBody = try encoder.encode(body)
        } catch {
            throw AuthError.network
        }
        let request = HTTPRequest(
            url: endpoint,
            method: .post,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ],
            body: encodedBody
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
                throw AuthError.invalidServerResponse
            }
            return AuthSession(
                passengerID: PassengerID(sessionResponse.passengerID),
                token: sessionResponse.token,
                expiresAt: sessionResponse.expiresAt
            )
        case 401:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.network
        }
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
