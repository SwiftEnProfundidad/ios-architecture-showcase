#if canImport(SwiftUI)
import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(localized: "auth.login.title"))
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 16) {
                    emailField
                    SecureField(String(localized: "auth.login.password"), text: $viewModel.password)
                        .textContentType(.password)
                        .accessibilityLabel(String(localized: "auth.login.password.accessibility"))
                }
                .padding(.horizontal)

                if let error = viewModel.errorMessage {
                    errorText(error)
                }

                Button {
                    Task { await viewModel.login() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text(String(localized: "auth.login.cta"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                .accessibilityLabel(String(localized: "auth.login.cta.accessibility"))
            }
            .navigationTitle(String(localized: "auth.login.navigationTitle"))
        }
    }

    @ViewBuilder
    private func errorText(_ message: String) -> some View {
        let base = Text(message)
            .foregroundStyle(.red)
            .font(.callout)
        #if os(iOS)
        base.accessibilityLiveRegion(.polite)
        #else
        base
        #endif
    }

    @ViewBuilder
    private var emailField: some View {
        let field = TextField(String(localized: "auth.login.email"), text: $viewModel.email)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .accessibilityLabel(String(localized: "auth.login.email.accessibility"))
        #if os(iOS)
        field
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
        #else
        field
        #endif
    }
}
#endif
