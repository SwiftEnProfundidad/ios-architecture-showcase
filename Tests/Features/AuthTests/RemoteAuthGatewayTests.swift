import AuthFeature
import Foundation
import SharedKernel
import Testing

private typealias SUT = RemoteAuthGateway<HTTPClientSpy>

@Suite("RemoteAuthGateway")
struct RemoteAuthGatewayTests {

    @Test("Successful HTTP authentication maps payload into AuthSession")
    func successfulAuthenticationMapsResponse() async throws {
        let decoder = JSONEncoder()
        decoder.dateEncodingStrategy = .iso8601
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.client.stub(
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
        let session = try await context.sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")

        #expect(session.passengerID == PassengerID("PAX-001"))
        #expect(session.token == "tok-abc")
        #expect(session.expiresAt == expiresAt)
    }

    @Test("401 response maps to invalid credentials")
    func unauthorizedMapsToInvalidCredentials() async {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .success(HTTPResponse(statusCode: 401, data: Data())))

        await #expect(throws: AuthError.invalidCredentials) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Transport failures map to network error")
    func transportFailuresMapToNetworkError() async {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .failure(.transport))

        await #expect(throws: AuthError.network) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")
        }
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> TrackedTestContext<RemoteAuthGatewayTestContext> {
        let client = HTTPClientSpy()
        let sut = SUT(client: client, baseURL: authBaseURL)
        return makeLeakTrackedTestContext(
            RemoteAuthGatewayTestContext(sut: sut, client: client),
            trackedInstances: client,
            sourceLocation: sourceLocation
        )
    }
}

private struct RemoteAuthGatewayTestContext {
    let sut: SUT
    let client: HTTPClientSpy
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

private let authBaseURL = URL(string: "https://auth.example.com") ?? URL(filePath: "/auth-example")
