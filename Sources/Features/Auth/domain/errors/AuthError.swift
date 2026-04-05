public enum AuthError: Error, Equatable, Sendable {
    case invalidCredentials
    case invalidEmailFormat
    case sessionExpired
    case network
    case invalidServerResponse
    case storage
}
