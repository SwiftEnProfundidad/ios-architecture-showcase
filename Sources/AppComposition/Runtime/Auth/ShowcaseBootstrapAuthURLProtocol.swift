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

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        return url.host == "bootstrap.auth.local"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client else {
            return
        }
        let configuration = Self.state.withLock { $0 }
        let response = Self.makeResponse(for: request, configuration: configuration)
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

    private static func makeResponse(
        for request: URLRequest,
        configuration: BootstrapAuthConfiguration
    ) -> BootstrapHTTPResponse {
        guard request.httpMethod == "POST", request.url?.path == "/v1/auth/login" else {
            return BootstrapHTTPResponse(statusCode: 404, body: Data())
        }
        guard
            let body = requestBody(from: request),
            let payload = try? JSONDecoder().decode(BootstrapAuthRequest.self, from: body)
        else {
            return BootstrapHTTPResponse(statusCode: 400, body: Data())
        }

        guard payload.email == configuration.email, payload.password == configuration.password else {
            return BootstrapHTTPResponse(statusCode: 401, body: Data())
        }

        let session = BootstrapAuthSessionResponse(
            passengerID: configuration.passengerID,
            token: "session-\(UUID().uuidString.lowercased())",
            expiresAt: .now.addingTimeInterval(configuration.sessionDuration)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = (try? encoder.encode(session)) ?? Data()
        return BootstrapHTTPResponse(statusCode: 200, body: bodyData)
    }

    private static func requestBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let readCount = stream.read(buffer, maxLength: bufferSize)
            if readCount < 0 {
                return nil
            }
            if readCount == 0 {
                break
            }
            data.append(buffer, count: readCount)
        }
        return data
    }
}

private struct BootstrapAuthRequest: Codable {
    let email: String
    let password: String
}

private struct BootstrapAuthSessionResponse: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}

private struct BootstrapHTTPResponse {
    let statusCode: Int
    let body: Data
}

private struct BootstrapAuthConfiguration: Sendable {
    let baseURL: URL
    let email: String
    let password: String
    let passengerID: String
    let sessionDuration: TimeInterval
}

private extension URL {
    static let bootstrapAuthBaseURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "bootstrap.auth.local"
        guard let url = components.url else {
            preconditionFailure("Bootstrap auth URL must be valid")
        }
        return url
    }()
}
