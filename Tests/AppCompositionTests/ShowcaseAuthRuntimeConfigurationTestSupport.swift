import AppComposition
import Foundation

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
