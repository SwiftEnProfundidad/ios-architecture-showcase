import SharedKernel
import SwiftUI

public struct LoginView<LoginExecutor: LoginExecuting>: View {
    @Bindable var viewModel: AuthViewModel<LoginExecutor>
    @Environment(\.colorScheme) private var colorScheme
    private let emailFieldConfiguration = LoginEmailFieldConfiguration.default

    public init(viewModel: AuthViewModel<LoginExecutor>) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? ShowcaseScreenPalette.loginDarkGradient
                    : ShowcaseScreenPalette.loginLightGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: ShowcaseLayout.Space.hero) {
                    VStack(spacing: ShowcaseLayout.Space.lg) {
                        Text(AppStrings.localized("auth.login.title"))
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)

                        Text(AppStrings.localized("auth.login.productName"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: ShowcaseLayout.Space.xxl) {
                        VStack(spacing: ShowcaseLayout.Inset.row) {
                            emailField
                            SecureField(AppStrings.localized("auth.login.password"), text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .accessibilityLabel(AppStrings.localized("auth.login.password.accessibility"))
                        }
                        .padding(ShowcaseLayout.Inset.formBlock)
                        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.loginCard))
                        .overlay {
                            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.loginCard)
                                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.55), lineWidth: ShowcaseLayout.Line.stroke)
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
                    .padding(.horizontal, ShowcaseLayout.Inset.screenX)
                }
                .frame(maxWidth: ShowcaseLayout.ContentWidth.login)
                .padding(.horizontal, ShowcaseLayout.Inset.screenX)
                .padding(.vertical, ShowcaseLayout.Space.loginVertical)
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
            .autocorrectionDisabled(emailFieldConfiguration.disablesAutocorrection)
            .onChange(of: viewModel.email) {
                guard emailFieldConfiguration.normalizesVisibleInput else { return }
                viewModel.normalizeVisibleEmailInput()
            }
            .accessibilityLabel(AppStrings.localized("auth.login.email.accessibility"))
    }
}
