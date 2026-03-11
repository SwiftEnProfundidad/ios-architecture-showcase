import SharedKernel

public protocol SessionPersisting: Sendable {
    func save(session: AuthSession) async throws
}

public protocol SessionReading: Sendable {
    func currentSession() async -> AuthSession?
}

public protocol SessionClearing: Sendable {
    func clear() async
}

public typealias SessionStoreProtocol = SessionPersisting & SessionReading & SessionClearing
