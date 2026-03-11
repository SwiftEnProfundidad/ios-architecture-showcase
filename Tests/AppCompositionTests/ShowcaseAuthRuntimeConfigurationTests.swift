@testable import AppComposition
import AuthFeature
import Foundation
import SharedKernel
import Testing

@Suite("ShowcaseAuthRuntimeConfiguration")
struct ShowcaseAuthRuntimeConfigurationTests {

    @Test("Empty AUTH_BASE_URL configures the bootstrap HTTP transport")
    func emptyBaseURLConfiguresBootstrapTransport() {
        let configuration = ShowcaseAuthRuntimeConfiguration.live(evaluationCredentials: .default)
        let configuredProtocolNames = configuration.session.configuration.protocolClasses?.map {
            String(describing: $0)
        } ?? []

        #expect(configuration.baseURL.absoluteString == "https://bootstrap.auth.local")
        #expect(configuration.evaluationCredentials == .default)
        #expect(configuration.launchPolicy == .resetSession)
        #expect(configuredProtocolNames.contains("ShowcaseBootstrapAuthURLProtocol"))
    }

    @Test("Explicit runtime configuration can opt into restoring sessions on launch")
    func explicitConfigurationCanRestoreSessionsOnLaunch() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.iberia.com"
        let configuration = ShowcaseAuthRuntimeConfiguration(
            baseURL: components.url ?? URL(filePath: "/"),
            session: URLSession(configuration: .ephemeral),
            evaluationCredentials: nil,
            launchPolicy: .restoreValidSession
        )

        #expect(configuration.baseURL.absoluteString == "https://api.iberia.com")
        #expect(configuration.evaluationCredentials == nil)
        #expect(configuration.launchPolicy == .restoreValidSession)
    }

    @Test("Bootstrap HTTP transport authenticates the evaluation credentials")
    func bootstrapTransportAuthenticatesEvaluationCredentials() async throws {
        let configuration = ShowcaseAuthRuntimeConfiguration.live(evaluationCredentials: .default)
        let gateway = RemoteAuthGateway(
            client: URLSessionHTTPClient(session: configuration.session),
            baseURL: configuration.baseURL
        )

        let session = try await gateway.authenticate(
            email: ShowcaseEvaluationCredentials.default.email,
            password: ShowcaseEvaluationCredentials.default.password
        )

        #expect(session.passengerID == PassengerID("PAX-001"))
        #expect(session.token.isEmpty == false)
        #expect(session.expiresAt > .now)
    }
}
