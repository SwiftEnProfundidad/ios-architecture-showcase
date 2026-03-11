import AuthFeature
import Foundation
import SharedKernel
import Testing

@Suite("RemoteAuthGateway")
struct RemoteAuthGatewayTests {

    @Test("Successful HTTP authentication maps payload into AuthSession")
    func successfulAuthenticationMapsResponse() async throws {
        let decoder = JSONEncoder()
        decoder.dateEncodingStrategy = .iso8601
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let tracked = makeRemoteAuthGatewaySUT()
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
        let tracked = makeRemoteAuthGatewaySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .success(HTTPResponse(statusCode: 401, data: Data())))

        await #expect(throws: AuthError.invalidCredentials) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Transport failures map to network error")
    func transportFailuresMapToNetworkError() async {
        let tracked = makeRemoteAuthGatewaySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .failure(.transport))

        await #expect(throws: AuthError.network) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")
        }
    }
}
