import AuthFeature
import SharedNavigation
import SwiftUI

@MainActor
struct AuthFeatureAssembly {
    private let runtime: AuthRuntime
    private let navigation: NavigationRuntime

    init(
        runtime: AuthRuntime,
        navigation: NavigationRuntime
    ) {
        self.runtime = runtime
        self.navigation = navigation
    }

    func makeView() -> some View {
        LoginScene(
            viewModel: AuthViewModel(
                loginUseCase: LoginUseCase(
                    gateway: runtime.gateway,
                    sessionStore: runtime.sessionStore
                ),
                eventBus: navigation.eventBus,
                quickAccessEmail: runtime.quickAccessCredentials?.email,
                quickAccessPassword: runtime.quickAccessCredentials?.password
            )
        )
    }
}

private struct LoginScene<LoginExecutor: LoginExecuting>: View {
    @State private var viewModel: AuthViewModel<LoginExecutor>

    init(viewModel: AuthViewModel<LoginExecutor>) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoginView(viewModel: viewModel)
    }
}
