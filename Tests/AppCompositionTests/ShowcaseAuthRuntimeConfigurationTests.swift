import AppComposition
import AuthFeature
import Foundation
import SharedKernel
import SharedNetworking
import Testing

@Suite("ShowcaseAuthRuntimeConfiguration")
struct ShowcaseAuthRuntimeConfigurationTests {

    @Test("Given AUTH_BASE_URL is empty, when runtime is assembled, then the bootstrap HTTP transport is configured accordingly")
    func emptyBaseURLConfiguresBootstrapTransport() {
        let configuration = makeShowcaseAuthRuntimeConfigurationSUT()
        let configuredProtocolNames = configuration.session.configuration.protocolClasses?.map {
            String(describing: $0)
        } ?? []

        #expect(configuration.baseURL.absoluteString == "https://bootstrap.auth.local")
        #expect(configuration.evaluationCredentials == .default)
        #expect(configuration.launchPolicy == .resetSession)
        #expect(configuredProtocolNames.contains("ShowcaseBootstrapAuthURLProtocol"))
    }

    @Test("Given restore-on-launch is enabled in runtime configuration, when the app bootstraps, then sessions are restored on launch")
    func explicitConfigurationCanRestoreSessionsOnLaunch() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.iberia.com"
        let configuration = makeConfiguredShowcaseAuthRuntimeConfigurationSUT(
            baseURL: components.url ?? URL(filePath: "/"),
            session: URLSession(configuration: .ephemeral),
            evaluationCredentials: nil,
            launchPolicy: .restoreValidSession
        )

        #expect(configuration.baseURL.absoluteString == "https://api.iberia.com")
        #expect(configuration.evaluationCredentials == nil)
        #expect(configuration.launchPolicy == .restoreValidSession)
    }

    @Test("Given evaluation credentials, when authenticating via bootstrap HTTP transport, then authentication succeeds")
    func bootstrapTransportAuthenticatesEvaluationCredentials() async throws {
        let tracked = makeBootstrapAuthenticationSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let session = try await context.gateway.authenticate(
            email: ShowcaseEvaluationCredentials.default.email,
            password: ShowcaseEvaluationCredentials.default.password
        )

        #expect(session.passengerID == PassengerID("PAX-001"))
        #expect(session.token.isEmpty == false)
        #expect(session.expiresAt > .now)
    }
}
