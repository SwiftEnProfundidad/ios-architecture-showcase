@testable import iOSArchitectureShowcase

actor SessionStoreSpy: SessionStoreProtocol {
    private var token: String?

    func save(token: String) {
        self.token = token
    }

    func currentToken() -> String? {
        token
    }

    func clear() {
        token = nil
    }
}
