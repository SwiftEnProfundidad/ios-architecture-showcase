import Foundation

struct BootstrapAuthResponseHandler {
    func handleRequest(
        _ request: URLRequest,
        configuration: BootstrapAuthConfiguration
    ) -> BootstrapHTTPResponse {
        guard request.httpMethod == "POST", request.url?.path == "/v1/auth/login" else {
            return BootstrapHTTPResponse(statusCode: 404, body: Data())
        }
        guard
            let body = requestBody(from: request),
            let payload = try? JSONDecoder().decode(BootstrapAuthLoginPayload.self, from: body)
        else {
            return BootstrapHTTPResponse(statusCode: 400, body: Data())
        }

        guard payload.email == configuration.email, payload.password == configuration.password else {
            return BootstrapHTTPResponse(statusCode: 401, body: Data())
        }

        let session = BootstrapAuthSessionPayload(
            passengerID: configuration.passengerID,
            token: "session-\(UUID().uuidString.lowercased())",
            expiresAt: .now.addingTimeInterval(configuration.sessionDuration)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = (try? encoder.encode(session)) ?? Data()
        return BootstrapHTTPResponse(statusCode: 200, body: bodyData)
    }

    private func requestBody(from request: URLRequest) -> Data? {
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

private struct BootstrapAuthLoginPayload: Codable {
    let email: String
    let password: String
}

private struct BootstrapAuthSessionPayload: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}

struct BootstrapHTTPResponse: Sendable {
    let statusCode: Int
    let body: Data
}

struct BootstrapAuthConfiguration: Sendable {
    let baseURL: URL
    let email: String
    let password: String
    let passengerID: String
    let sessionDuration: TimeInterval
}

extension URL {
    static let bootstrapAuthBaseURL =
        URL(string: "https://bootstrap.auth.local") ?? URL(filePath: "/bootstrap-auth-local")
}
