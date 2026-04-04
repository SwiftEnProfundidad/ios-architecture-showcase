import AuthFeature

actor SessionPersistingSpy: SessionPersisting {
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

    func persistedSession() -> AuthSession? {
        session
    }
}
