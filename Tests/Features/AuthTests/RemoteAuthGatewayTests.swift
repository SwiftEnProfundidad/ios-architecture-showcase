import AuthFeature
import Foundation
import SharedKernel
import Testing

private typealias SUT = RemoteAuthGateway<HTTPClientSpy>

@Suite("RemoteAuthGateway")
struct RemoteAuthGatewayTests {

    @Test("Successful HTTP authentication maps payload into AuthSession")
    func successfulAuthenticationMapsResponse() async throws {
        let client = HTTPClientSpy()
        let decoder = JSONEncoder()
        decoder.dateEncodingStrategy = .iso8601
        let expiresAt = fixedDate(hour: 12, minute: 0)
        await client.stub(
            result: .success(
                HTTPResponse(
                    statusCode: 200,
                    data: try decoder.encode(
                        LoginPayload(
                            passengerID: "PAX-001",
                            token: "tok-abc",
                            expiresAt: expiresAt
                        )
                    )
                )
            )
        )
        let sut = SUT(client: client, baseURL: authBaseURL)

        let session = try await sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")

        #expect(session.passengerID == PassengerID("PAX-001"))
        #expect(session.token == "tok-abc")
        #expect(session.expiresAt == expiresAt)
    }

    @Test("401 response maps to invalid credentials")
    func unauthorizedMapsToInvalidCredentials() async {
        let client = HTTPClientSpy()
        await client.stub(result: .success(HTTPResponse(statusCode: 401, data: Data())))
        let sut = SUT(client: client, baseURL: authBaseURL)

        await #expect(throws: AuthError.invalidCredentials) {
            try await sut.authenticate(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Transport failures map to network error")
    func transportFailuresMapToNetworkError() async {
        let client = HTTPClientSpy()
        await client.stub(result: .failure(.transport))
        let sut = SUT(client: client, baseURL: authBaseURL)

        await #expect(throws: AuthError.network) {
            try await sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")
        }
    }
}

private actor HTTPClientSpy: HTTPClient {
    private var result: Result<HTTPResponse, HTTPClientError> = .failure(.transport)

    func stub(result: Result<HTTPResponse, HTTPClientError>) {
        self.result = result
    }

    func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        try result.get()
    }
}

private struct LoginPayload: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}

private let authBaseURL: URL = {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "auth.example.com"
    guard let url = components.url else {
        preconditionFailure("Auth test base URL must be valid")
    }
    return url
}()
