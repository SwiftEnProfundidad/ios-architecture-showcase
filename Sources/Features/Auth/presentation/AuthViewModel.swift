import Observation
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class AuthViewModel {
    public var email: String = ""
    public var password: String = ""
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let loginUseCase: LoginUseCase<InMemoryAuthGateway, InMemorySessionStore>

    public init(loginUseCase: LoginUseCase<InMemoryAuthGateway, InMemorySessionStore>) {
        self.loginUseCase = loginUseCase
    }

    public func login() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await loginUseCase.execute(email: email, password: password)
        } catch let error as AuthError {
            errorMessage = map(error)
        } catch {
            errorMessage = String(localized: "auth.error.unexpected")
        }
    }

    private func map(_ error: AuthError) -> String {
        switch error {
        case .invalidCredentials: String(localized: "auth.error.invalidCredentials")
        case .invalidEmailFormat: String(localized: "auth.error.invalidEmailFormat")
        case .sessionExpired: String(localized: "auth.error.sessionExpired")
        case .network: String(localized: "auth.error.network")
        }
    }
}
