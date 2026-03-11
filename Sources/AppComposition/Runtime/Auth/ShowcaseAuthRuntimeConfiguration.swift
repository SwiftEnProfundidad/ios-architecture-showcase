import Foundation

public struct ShowcaseAuthRuntimeConfiguration: Sendable {
    private static let bootstrapBaseURL = URL.bootstrapAuthBaseURL

    public let baseURL: URL
    public let session: URLSession
    public let evaluationCredentials: ShowcaseEvaluationCredentials?
    public let launchPolicy: SessionLaunchPolicy

    public init(
        baseURL: URL,
        session: URLSession,
        evaluationCredentials: ShowcaseEvaluationCredentials? = nil,
        launchPolicy: SessionLaunchPolicy
    ) {
        self.baseURL = baseURL
        self.session = session
        self.evaluationCredentials = evaluationCredentials
        self.launchPolicy = launchPolicy
    }

    public static func live(
        bundle: Bundle = .main,
        evaluationCredentials: ShowcaseEvaluationCredentials
    ) -> ShowcaseAuthRuntimeConfiguration {
        if
            let configuredBaseURL = bundle.object(forInfoDictionaryKey: "AUTH_BASE_URL") as? String,
            configuredBaseURL.isEmpty == false,
            let url = URL(string: configuredBaseURL)
        {
            return ShowcaseAuthRuntimeConfiguration(
                baseURL: url,
                session: URLSession(configuration: .default),
                evaluationCredentials: nil,
                launchPolicy: .restoreValidSession
            )
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ShowcaseBootstrapAuthURLProtocol.self]
        ShowcaseBootstrapAuthURLProtocol.bootstrap(
            credentials: evaluationCredentials,
            passengerID: "PAX-001",
            sessionDuration: 60 * 60
        )
        return ShowcaseAuthRuntimeConfiguration(
            baseURL: bootstrapBaseURL,
            session: URLSession(configuration: configuration),
            evaluationCredentials: evaluationCredentials,
            launchPolicy: .resetSession
        )
    }
}

private extension URL {
    static let bootstrapAuthBaseURL = URLComponents.bootstrapAuthBaseURL
}

private extension URLComponents {
    static let bootstrapAuthBaseURL =
        URL(string: "https://bootstrap.auth.local") ?? URL(filePath: "/bootstrap-auth-local")
}
