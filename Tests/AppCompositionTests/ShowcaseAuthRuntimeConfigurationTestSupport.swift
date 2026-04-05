import AppComposition
import AuthFeature
import Foundation
import SharedNetworking
import Testing

func makeShowcaseAuthRuntimeConfigurationSUT() -> ShowcaseAuthRuntimeConfiguration {
    ShowcaseAuthRuntimeConfiguration.live(evaluationCredentials: .default)
}

func makeConfiguredShowcaseAuthRuntimeConfigurationSUT(
    baseURL: URL,
    session: URLSession,
    evaluationCredentials: ShowcaseEvaluationCredentials?,
    launchPolicy: SessionLaunchPolicy
) -> ShowcaseAuthRuntimeConfiguration {
    ShowcaseAuthRuntimeConfiguration(
        baseURL: baseURL,
        session: session,
        evaluationCredentials: evaluationCredentials,
        launchPolicy: launchPolicy
    )
}

struct BootstrapAuthenticationTestContext {
    let gateway: RemoteAuthGateway<URLSessionHTTPClient>
    let configuration: ShowcaseAuthRuntimeConfiguration
}

func makeBootstrapAuthenticationSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<BootstrapAuthenticationTestContext> {
    let configuration = makeShowcaseAuthRuntimeConfigurationSUT()
    let client = URLSessionHTTPClient(session: configuration.session)
    let gateway = RemoteAuthGateway(client: client, baseURL: configuration.baseURL)
    return makeLeakTrackedTestContext(
        BootstrapAuthenticationTestContext(
            gateway: gateway,
            configuration: configuration
        ),
        trackedInstances: client,
        sourceLocation: sourceLocation
    )
}
