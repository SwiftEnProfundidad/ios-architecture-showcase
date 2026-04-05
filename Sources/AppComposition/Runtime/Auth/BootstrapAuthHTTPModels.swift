import Foundation

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
