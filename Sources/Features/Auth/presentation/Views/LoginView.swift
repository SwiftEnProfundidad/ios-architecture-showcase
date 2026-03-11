import SharedKernel
import SwiftUI

public struct LoginView<LoginExecutor: LoginExecuting>: View {
    @Bindable var viewModel: AuthViewModel<LoginExecutor>
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: AuthViewModel<LoginExecutor>) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.06, green: 0.09, blue: 0.18),
                        Color(red: 0.03, green: 0.03, blue: 0.07),
                        .black
                    ]
                    : [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.99, green: 0.99, blue: 1.0),
                        .white
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text(AppStrings.localized("auth.login.title"))
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)

                        Text(AppStrings.localized("auth.login.productName"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 18) {
                        VStack(spacing: 16) {
                            emailField
                            SecureField(AppStrings.localized("auth.login.password"), text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .accessibilityLabel(AppStrings.localized("auth.login.password.accessibility"))
                        }
                        .padding(24)
                        .background(.thinMaterial, in: .rect(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.55), lineWidth: 1)
                        }

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
                                    Text(AppStrings.localized("auth.login.cta"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)
                        .accessibilityLabel(AppStrings.localized("auth.login.cta.accessibility"))

                        if viewModel.hasQuickAccess {
                            Button {
                                Task { await viewModel.loginWithQuickAccess() }
                            } label: {
                                Text(AppStrings.localized("auth.login.quickAccess"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isLoading)
                            .accessibilityLabel(AppStrings.localized("auth.login.quickAccess.accessibility"))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.vertical, 48)
            }
        }
        .navigationTitle(AppStrings.localized("auth.login.navigationTitle"))
    }

    @ViewBuilder
    private func errorText(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(.red)
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var emailField: some View {
        TextField(AppStrings.localized("auth.login.email"), text: $viewModel.email)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .accessibilityLabel(AppStrings.localized("auth.login.email.accessibility"))
    }
}
