import AuthFeature

actor SessionStoreSpy: SessionStoreProtocol {
    private var session: AuthSession?
    private var saveError: Error?

    func stubSaveError(_ error: Error) {
        saveError = error
    }

    func save(session: AuthSession) async throws {
        if let saveError {
            throw saveError
        }
        self.session = session
    }

    func currentSession() -> AuthSession? {
        session
    }

    func clear() {
        session = nil
    }
}
