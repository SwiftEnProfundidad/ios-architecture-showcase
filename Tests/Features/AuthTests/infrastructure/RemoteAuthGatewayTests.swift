import AuthFeature
import Foundation
import SharedKernel
import SharedNetworking
import Testing

@Suite("RemoteAuthGateway")
struct RemoteAuthGatewayTests {

    @Test("Given a successful HTTP authentication response, when the gateway maps it, then an AuthSession is produced")
    func successfulAuthenticationMapsResponse() async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let tracked = makeRemoteAuthGatewaySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.client.stub(
            result: .success(
                HTTPResponse(
                    statusCode: 200,
                    data: try encoder.encode(
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

    @Test("Given an HTTP 401 response, when the gateway maps the error, then invalid credentials is produced")
    func unauthorizedMapsToInvalidCredentials() async {
        let tracked = makeRemoteAuthGatewaySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .success(HTTPResponse(statusCode: 401, data: Data())))

        await #expect(throws: AuthError.invalidCredentials) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "wrong")
        }
    }

    @Test("Given a transport failure, when the gateway maps the error, then a network error is produced")
    func transportFailuresMapToNetworkError() async {
        let tracked = makeRemoteAuthGatewaySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .failure(.transport))

        await #expect(throws: AuthError.network) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")
        }
    }

    @Test("Given HTTP 200 with malformed JSON, when the gateway maps the response, then invalid server response is produced")
    func malformedSuccessBodyMapsToInvalidServerResponse() async {
        let tracked = makeRemoteAuthGatewaySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        await context.client.stub(result: .success(HTTPResponse(statusCode: 200, data: Data("{".utf8))))

        await #expect(throws: AuthError.invalidServerResponse) {
            try await context.sut.authenticate(email: "carlos@iberia.com", password: "Secure123!")
        }
    }
}
