import Foundation
import os

final class ShowcaseBootstrapAuthURLProtocol: URLProtocol {
    private static let state = OSAllocatedUnfairLock(
        initialState: BootstrapAuthConfiguration(
            baseURL: .bootstrapAuthBaseURL,
            email: ShowcaseEvaluationCredentials.default.email,
            password: ShowcaseEvaluationCredentials.default.password,
            passengerID: "PAX-001",
            sessionDuration: 60 * 60
        )
    )
    private static let responseHandler = BootstrapAuthResponseHandler()

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        return url.host == URL.bootstrapAuthBaseURL.host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client else {
            preconditionFailure("URLProtocol.startLoading() invoked without client")
        }
        let configuration = Self.state.withLock { $0 }
        let response = Self.responseHandler.handleRequest(request, configuration: configuration)
        if let httpResponse = HTTPURLResponse(
            url: request.url ?? configuration.baseURL,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        ) {
            client.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        }
        client.urlProtocol(self, didLoad: response.body)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }

    static func bootstrap(
        credentials: ShowcaseEvaluationCredentials,
        passengerID: String,
        sessionDuration: TimeInterval
    ) {
        state.withLock {
            $0 = BootstrapAuthConfiguration(
                baseURL: .bootstrapAuthBaseURL,
                email: credentials.email,
                password: credentials.password,
                passengerID: passengerID,
                sessionDuration: sessionDuration
            )
        }
    }
}
