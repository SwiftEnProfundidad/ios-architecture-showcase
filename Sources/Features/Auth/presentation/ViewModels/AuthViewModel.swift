import Observation
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class AuthViewModel<LoginExecutor: LoginExecuting> {
    public var email: String = ""
    public var password: String = ""
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public var hasQuickAccess: Bool {
        quickAccessEmail?.isEmpty == false && quickAccessPassword?.isEmpty == false
    }

    private let loginUseCase: LoginExecutor
    private let eventBus: NavigationEventPublishing
    private let quickAccessEmail: String?
    private let quickAccessPassword: String?

    public init(
        loginUseCase: LoginExecutor,
        eventBus: NavigationEventPublishing,
        quickAccessEmail: String? = nil,
        quickAccessPassword: String? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.eventBus = eventBus
        self.quickAccessEmail = quickAccessEmail
        self.quickAccessPassword = quickAccessPassword
        if let quickAccessEmail, quickAccessEmail.isEmpty == false {
            email = quickAccessEmail
        }
        if let quickAccessPassword, quickAccessPassword.isEmpty == false {
            password = quickAccessPassword
        }
    }

    public func login() async {
        await executeLogin(email: email, password: password)
    }

    public func loginWithQuickAccess() async {
        guard let quickAccessEmail, let quickAccessPassword, hasQuickAccess else {
            return
        }
        email = quickAccessEmail
        password = quickAccessPassword
        await executeLogin(email: quickAccessEmail, password: quickAccessPassword)
    }

    private func executeLogin(email: String, password: String) async {
        guard !isLoading else { return }
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.email = normalizedEmail
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await loginUseCase.execute(email: normalizedEmail, password: password)
            await eventBus.publish(.sessionStarted(AppSession(
                passengerID: session.passengerID,
                token: session.token,
                expiresAt: session.expiresAt
            )))
        } catch is CancellationError {
            return
        } catch let error as AuthError {
            if error != .invalidEmailFormat {
                await eventBus.publish(.sessionStartRejected)
            }
            errorMessage = map(error)
        } catch {
            await eventBus.publish(.sessionStartRejected)
            errorMessage = AppStrings.localized("auth.error.unexpected")
        }
    }

    private func map(_ error: AuthError) -> String {
        switch error {
        case .invalidCredentials: AppStrings.localized("auth.error.invalidCredentials")
        case .invalidEmailFormat: AppStrings.localized("auth.error.invalidEmailFormat")
        case .sessionExpired: AppStrings.localized("auth.error.sessionExpired")
        case .network: AppStrings.localized("auth.error.network")
        case .storage: AppStrings.localized("auth.error.unexpected")
        }
    }
}
