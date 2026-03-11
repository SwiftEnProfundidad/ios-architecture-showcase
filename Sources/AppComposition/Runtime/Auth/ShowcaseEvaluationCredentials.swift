public struct ShowcaseEvaluationCredentials: Sendable, Equatable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }

    public static let `default` = ShowcaseEvaluationCredentials(
        email: "carlos@iberia.com",
        password: "Secure123!"
    )
}
