import AuthFeature
import Foundation
import SharedKernel
import Testing

typealias RemoteAuthGatewaySUT = RemoteAuthGateway<HTTPClientSpy>

func makeRemoteAuthGatewaySUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<RemoteAuthGatewayTestContext> {
    let client = HTTPClientSpy()
    let sut = RemoteAuthGatewaySUT(client: client, baseURL: authBaseURL)
    return makeLeakTrackedTestContext(
        RemoteAuthGatewayTestContext(sut: sut, client: client),
        trackedInstances: client,
        sourceLocation: sourceLocation
    )
}

struct RemoteAuthGatewayTestContext {
    let sut: RemoteAuthGatewaySUT
    let client: HTTPClientSpy
}

actor HTTPClientSpy: HTTPClient {
    private var result: Result<HTTPResponse, HTTPClientError> = .failure(.transport)

    func stub(result: Result<HTTPResponse, HTTPClientError>) {
        self.result = result
    }

    func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        try result.get()
    }
}

struct LoginPayload: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}

let authBaseURL = URL(string: "https://auth.example.com") ?? URL(filePath: "/auth-example")
